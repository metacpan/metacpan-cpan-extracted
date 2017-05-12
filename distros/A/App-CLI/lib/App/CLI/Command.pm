package App::CLI::Command;
use strict;
use warnings;
use Locale::Maketext::Simple;
use Carp ();
use App::CLI::Helper;

=head1 NAME

App::CLI::Command - Base class for App::CLI commands

=head1 SYNOPSIS

    package MyApp::List;
    use base qw(App::CLI::Command);

    use constant options => (
        'verbose'   => 'verbose',
        'n|name=s'  => 'name',
    );

    sub run {
        my ( $self, $arg ) = @_;

        print "verbose" if $self->{verbose};

        my $name = $self->{name}; # get arg following long option --name

        # any thing your want this command do
    }

    # See App::CLI for information of how to invoke (sub)command.

=head1 DESCRIPTION


=cut

use constant subcommands => ();
use constant options => ();

sub new {
    my $class = shift;
    bless {@_}, $class;
}



sub command_options {
    ((map { $_ => $_ } $_[0]->subcommands), $_[0]->options);
}

# XXX:
sub _mk_completion_sh { }
sub _mk_completion_zsh { }



sub run_command {
    my $self = shift;
    $self->run(@_);
}

=head3 subcommand()

    return old genre subcommand of $self;

=cut

sub subcommand {
    my $self = shift;
    my @cmd = $self->subcommands;
    @cmd = values %{{$self->options}} if @cmd && $cmd[0] eq '*';
    my $subcmd = undef;
    for (grep {$self->{$_}} @cmd) {
      no strict 'refs';
      if (exists ${ref($self).'::'}{$_.'::'}) {
        my %data = %{$self};
	$subcmd = bless ({%data}, (ref($self)."::$_"));
        last;
      }
    }
    $subcmd ? $subcmd : $self;
}

=head3 cascading()

return instance of cascading subcommand invoked if it was listed in your constant subcommands.

=cut

sub cascading {
  my $self = shift;
  if (my $subcmd = $self->cascadable) {
    shift @ARGV;
    my %data = %{$self};
    return bless {%data}, $subcmd;
  } else {
    die $self->error_cmd;
  }
}

=head3 cascadable()

return package name of subcommand if the subcommand invoked is in you constant subcommands

otherwise, return undef

=cut

sub cascadable {
  my $self = shift;
  for ($self->subcommands) {
    no strict 'refs';
    eval "require ".ref($self)."::$_";
    if (ucfirst($ARGV[0]) eq $_ && exists ${ref($self)."::"}{$_."::"}) {
      return ref($self)."::".$_;
    }
  }
  return undef
}

sub app {
    my $self = shift;
    die Carp::longmess "not a ref" unless ref $self;
    $self->{app} = shift if @_;
    return ref ($self->{app}) || $self->{app};
}

=head3 brief_usage ($file)

Display an one-line brief usage of the command object.  Optionally, a file
could be given to extract the usage from the POD.

=cut

sub brief_usage {
    my ($self, $file) = @_;
    open my ($podfh), '<', ($file || $self->filename) or return;
    local $/=undef;
    my $buf = <$podfh>;
    my $base = $self->app;
    if($buf =~ /^=head1\s+NAME\s*\Q$base\E::(\w+ - .+)$/m) {
        print "   ",loc(lc($1)),"\n";
    } else {
        my $cmd = $file ||$self->filename;
        $cmd =~ s/^(?:.*)\/(.*?).pm$/$1/;
        print "   ", lc($cmd), " - ",loc("undocumented")."\n";
    }
    close $podfh;
}

=head3 usage ($want_detail)

Display usage.  If C<$want_detail> is true, the C<DESCRIPTION>
section is displayed as well.

=cut

sub usage {
    my ($self, $want_detail) = @_;
    my $fname = $self->filename;
    my ($cmd) = $fname =~ m{\W(\w+)\.pm$};
    require Pod::Simple::Text;
    my $parser = Pod::Simple::Text->new;
    my $buf;
    $parser->output_string(\$buf);
    $parser->parse_file($fname);

    my $base = $self->app;
    $buf =~ s/\Q$base\E::(\w+)/\l$1/g;
    $buf =~ s/^AUTHORS.*//sm;
    $buf =~ s/^DESCRIPTION.*//sm unless $want_detail;
    print $self->loc_text($buf);
}

=head3 loc_text $text

Localizes the body of (formatted) text in $text, and returns the
localized version.

=cut

sub loc_text {
    my $self = shift;
    my $buf = shift;

    my $out = "";
    foreach my $line (split(/\n\n+/, $buf, -1)) {
        if (my @lines = $line =~ /^( {4}\s+.+\s*)$/mg) {
            foreach my $chunk (@lines) {
                $chunk =~ /^(\s*)(.+?)( *)(: .+?)?(\s*)$/ or next;
                my $spaces = $3;
                my $loc = $1 . loc($2 . ($4||'')) . $5;
                $loc =~ s/: /$spaces: / if $spaces;
                $out .= $loc . "\n";
            }
            $out .= "\n";
        }
        elsif ($line =~ /^(\s+)(\w+ - .*)$/) {
            $out .= $1 . loc($2) . "\n\n";
        }
        elsif (length $line) {
            $out .= loc($line) . "\n\n";
        }
    }
    return $out;
}

=head3 filename

Return the filename for the command module.

=cut

sub filename {
    my $self = shift;
    my $fname = ref($self);
    $fname =~ s{::[a-z]+$}{}; # subcommand
    $fname =~ s{::}{/}g;
    return $INC{"$fname.pm"};
}


=head1 SEE ALSO

L<App::CLI>
L<Getopt::Long>

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>
Cornelius Lin  E<lt>cornelius.howl@gmail.comE<gt>
shelling       E<lt>navyblueshellingford@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2005-2006 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
