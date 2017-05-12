package main;
BEGIN {
  $main::VERSION = '0.11';
}
sub eval_ctx { eval "sub { $_[0] }" } # Here to avoid any closures

package App::redisp;
BEGIN {
  $App::redisp::VERSION = '0.11';
}
# ABSTRACT: Perl redis shell

use B qw(svref_2object);
use Data::Dump qw(pp);
use Moo;
use Pod::Usage qw(pod2usage);
use Term::ANSIColor qw(colored);
use Term::ReadLine;
use Tie::Redis;

use constant HAVE_READKEY => eval { require Term::ReadKey };

use App::redisp::Commands qw(@COMMANDS);
use App::redisp::EvalWithLexicals; # Just a hacked copy of Eval::WithLexicals

has eval_with_lexicals => (
  is => 'ro',
  default => sub { App::redisp::EvalWithLexicals->new(
      in_package => 'main'
    );
  }
);

has host => (
  is => 'rw',
  default => sub { 'localhost' }
);

has port => (
  is => 'rw',
  default => sub { 6379 }
);

has serialize => (
  is => 'rw',
  default => sub { '' }
);

has redis => (
  is => 'rw',
  lazy => 1,
  default => sub {
    my($self) = @_;
    tie my %h, 'Tie::Redis',
      host => $self->host, port => $self->port, use_recv => 1;
    tied %h;
  }
);

sub debug {
  $ENV{DEBUG} && print "-- ", colored(['green'], @_), "\n";
}

# Special handling code
my %special = (
  keyword => sub {
    my($param) = @_;
    if($param =~ /^\s*(\w+)\s+([^\%\@\$].*)/) {
      $param = "redis_raw(q{$1}, $2)";
      debug "Replaced with '$param'\n";
    }
    return $param;
  }
);

# Handle these commands specially
my %redis_special_commands = (
  keys => $special{keyword},
  exists => $special{keyword},
);

my %util_cmds = (
  encoding => sub {

  },
);

sub BUILD {
  my($self) = @_;

  $self->_install_commands;
}

sub usage {
  my($class, $verbosity) = @_;

  pod2usage(
    -verbose => $verbosity == 1 ? (99, -sections => 'USAGE') : $verbosity,
    -input => __FILE__
  );
}

sub run {
  my($self) = @_;

  my $short_server = $self->host =~ /[0-9]$/
    ? $self->host # IP address
    : ($self->host =~ /^([^.]+)/)[0];

  my $read = Term::ReadLine->new($short_server);
  my $prompt = "$short_server> ";

  while(1) {
    my $line = $read->readline($prompt);
    exit unless defined $line;
    $read->addhistory($line) if $line =~ /\S/;

    if($line =~ /^(?:\?|help)$/) {
      print <DATA>;
      next;
    } elsif($line =~ /^\.(\w+)(?:\s+(.*))?/) {
      ($util_cmds{$1} || sub { warn "Unknown command\n" })->($2);
      next;
    } elsif($line =~ /^\s*(\w+)/ && exists $redis_special_commands{$1}) {
      $line = $redis_special_commands{$1}->($line);
    }

    # TODO: Consider Parse::Perl, but I like no-non-core XS deps for now.
    my $code = ::eval_ctx $line;
    unless(ref $code eq 'CODE') {
      chomp $@;
      print colored(['red'], $@), "\n";
      next;
    }

    $self->_setup_ties_for_code($code);

    $self->eval($line);
  }
}

sub eval {
  my($self, $line) = @_;

  Term::ReadKey::ReadMode(0) if HAVE_READKEY;
  my @ret;
  eval {
    local $SIG{INT} = sub { die "Interrupt\n" };
    @ret = $self->eval_with_lexicals->eval($line);
    1;
  } or do {
    chomp $@;
    print colored(['red'], $@), "\n";
    return;
  };
  Term::ReadKey::ReadMode(1) if HAVE_READKEY;
  pp @ret;
}

sub _setup_ties_for_code {
  my($self, $code) = @_;
  no strict 'refs';

  for my $var(_find_referenced($code)) {
    # Avoid special variables
    next if $var->[0] =~ /^(?:.*::|[\x01-\x1f].*|\W|[0-9]+|_|ENV|SIG)$/;

    if($var->[1] eq 'sv') {
      next if tied ${"::" . $var->[0]};
      debug qq{Tie \${\"$var->[0]\"}};
      tie ${"::" . $var->[0]}, 'Tie::Redis::Scalar',
        redis => $self->redis, key => $var->[0];

    } elsif($var->[1] eq 'hv') {
      next if tied %{"::" . $var->[0]};
      debug qq{Tie \%{\"$var->[0]\"}};
      tie %{"::" . $var->[0]}, 'Tie::Redis::Hash',
        redis => $self->redis, key => $var->[0];

    } elsif($var->[1] eq 'av') {
      next if tied @{"::" . $var->[0]};
      debug qq{Tie \@{\"$var->[0]\"}};
      tie @{"::" . $var->[0]}, 'Tie::Redis::List',
        redis => $self->redis, key => $var->[0];
    }
  }
}

sub _install_commands {
  my($self) = @_;

  no strict 'refs';
  no warnings 'redefine';

  for my $cmd(@COMMANDS) {
    next if exists $redis_special_commands{$cmd};
    *{"main::$cmd"} = sub(@) {
      $self->redis->$cmd(@_)->recv;
    };
  }

  *{"main::redis_raw"} = sub(@) {
    my($cmd, @args) = @_;
    $self->redis->$cmd(@args)->recv;
  };
}

sub _find_referenced {
  my($code) = @_;

  # Muahah!
  my @vars;
  my $cv = svref_2object($code);
  my $op = $cv->START;
  do {
    if($op->name =~ /^(?:gv|gvsv|aelemfast|const)$/) {
      my $type = $op->name eq 'gvsv' ? 'sv' :
      $op->name eq 'aelemfast' ? 'av' :
      ($op->next->name =~ /2(.*)/)[0];

      # B::Concise::concise_op was helpful here
      if($type) {
        my $idx = $op->isa("B::SVOP") ? $op->targ : $op->padix;

        my $sv;
        if($op->isa("B::PADOP") || !${$op->sv}) {
          $sv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$idx];
        } else {
          $sv = $op->sv;
        }
        my $gv_name = $sv->can("NAME") ? $sv->NAME : $sv->PV;
        push @vars, [$gv_name, $type] if $gv_name;
      }
    }
  } while $op = $op->next and $op->isa("B::OP");

  return @vars;
}




=pod

=head1 NAME

main - Perl redis shell

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 $ redisp
 localhost> keys "foo*"
 "foobar", "food"
 localhost> set foobarbaz 12
 "OK"

 # Or in perl style
 localhost> $foobar
 10

 localhost> .encoding utf-8
 localhost> .server xxx
 localhost> .reconnect
 localhost> .output json

=head1 DESCRIPTION

Redis and Perl share similar data types, therefore I thought it would be useful
to have a Redis shell interface that appears to behave as Perl. This is a Perl
Read-Eval-Print Loop (REPL) that happens to understand Redis.

The use of Redis aims to be transparent, you just use a variable like C<$foo>
and it will be read or saved to Redis. For a temporary variable that is only visible to Perl use C<my $foo>.

=for Pod::Coverage eval_with_lexicals host port debug eval BUILD run serialize usage

=head1 USAGE

 redisp [--help] [--server=host] [--port=port] [--encoding=encoding]
   [--serialize=serializer]

=head1 OPTIONS

=over 4

=item * B<--help>

This document.

=item * B<--server>

Host to connect to Redis on.

=item * B<--port>

Port to connect to Redis on.

=item * B<--encoding>

Encoding to use with Redis, B<UTF-8> is recommended (but the default is none).

=item * B<--serialize>

Serializer to use, see the L<Tie::Redis> documentation for details on supported
serializers and the limitations.

=back

=head1 LIMITATIONS

The main noticable thing is common key naming styles in Redis such as
C<"foo-bar"> or C<"foo:bar"> require quoting on the Perl side. For example to
access a top level key of foo:bar you need to access C<${"foo:bar"}>.

In Redis a key has one type; in Perl a glob reference may have HASH, ARRAY,
SCALAR, etc values. This application makes Perl match the Redis behaviour, it's
invalid to use more than one type at a particular name. The error will be:
C<ERR Operation against a key holding the wrong kind of value>.

=head1 BUGS

This goes I<quite> close to the internals of Perl so there may be issues with
constructs I haven't thought of. Raise bugs via L<http://rt.cpan.org>.

The output produced by:

  ANYEVENT_REDIS_DEBUG=1 DEBUG=1 redisp

for your issue would be helpful.

=head1 SEE ALSO

L<Tie::Redis>, L<http://redis.io/commands>, L<Eval::WithLexicals>,
L<Term::ReadLine::Perl> (I recommend you install this or ::Gnu).

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the terms of the Beerware license.

=cut


__DATA__
Use redis commands (see http://redis.io/commands).

Redis commands are parsed as Perl, this mostly means quoting is required and
commas separate arguments:
  > set "foo", "bar"
  "OK"
  > get foo
  "bar"

('strict' is not used so simple keys that don't clash with keywords don't need
quoting.)

Alternatively use normal Perl variables:

  > $foo = "baz"
  "baz"
  > $hash{key} = value
  "value"
  > ++${"foo:bar"}
  1
