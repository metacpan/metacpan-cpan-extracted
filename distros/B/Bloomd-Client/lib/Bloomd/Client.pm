#
# This file is part of Bloomd-Client
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Bloomd::Client;
{
  $Bloomd::Client::VERSION = '0.27';
}

# ABSTRACT: Perl client to the bloomd server

use feature ':5.10';
use Moo;
use List::MoreUtils qw(any mesh);
use Carp;
use Socket qw(:crlf);
use IO::Socket::INET;
use Errno qw(:POSIX);
use POSIX qw(strerror);
use Config;
use Types::Standard -types;


has protocol => ( is => 'ro', default => sub {'tcp'} );


has host => ( is => 'ro', isa => StrMatch[qr/.+/], default => sub {'127.0.0.1'} );


has port => ( is => 'ro', isa => Int, default => sub {8673} );
has _socket => ( is => 'lazy', predicate => 1, clearer => 1 );


has timeout => ( is => 'ro', , default => sub { 10 } );

has '_pid' => (is => 'ro', lazy => 1, clearer => 1, default => sub { $$ });


sub _build__socket {
    my ($self) = @_;
    my $socket = IO::Socket::INET->new(
        Proto => $self->protocol,
        PeerHost => $self->host,
        PeerPort => $self->port,
        Timeout  => $self->timeout,
    ) or die "Can't connect to server: $!";

    $self->timeout
      or return $socket;

    $Config{osname} eq 'netbsd' || $Config{osname} eq 'solaris'
      and croak "the timeout option is not yet supported on NetBSD or Solaris";

    my $seconds  = int( $self->timeout );
    my $useconds = int( 1_000_000 * ( $self->timeout - $seconds ) );
    my $timeout  = pack( 'l!l!', $seconds, $useconds );

    $socket->setsockopt( SOL_SOCKET, SO_RCVTIMEO, $timeout )
      or croak "setsockopt(SO_RCVTIMEO): $!";

    $socket->setsockopt( SOL_SOCKET, SO_SNDTIMEO, $timeout )
      or croak "setsockopt(SO_SNDTIMEO): $!";

    return $socket;

}


sub disconnect {
    my ($self) = @_;
    $self->_has_socket
      and $self->_socket->close;
    $self->_clear_socket;
}


sub create {
    my ($self, $name, $capacity, $prob, $in_memory) = @_;
    my $args =
        ( $capacity ? "capacity=$capacity" : '' )
      . ( $prob ? " prob=$prob" : '' )
      . ( $in_memory ? " in_memory=$in_memory" : '' );
    $self->_execute("create $name $args" ) eq 'Done';
}


sub list {
    my ($self, $prefix) = @_;
    $prefix //= '';
    my @keys = qw(name prob size capacity items);
    [
     map {
         my @values = split / /;
         +{ mesh @keys, @values };
     }
     $self->_execute("list $prefix" )
    ];
}


sub drop {
    my ($self, $name) = @_;
    $self->_execute("drop $name") eq 'Done';
}



sub close {
    my ($self, $name) = @_;
    $self->_execute("close $name") eq 'Done';
}


sub clear {
    my ($self, $name) = @_;
    $self->_execute("clear $name") eq 'Done';
}


sub check {
    my ($self, $name, $key) = @_;
    $self->_execute("c $name $key") eq 'Yes';
}


sub multi {
    my ($self, $name, @keys) = @_;
    @keys
      or return {};
    my @values = map { $_ eq 'Yes' } split / /, $self->_execute("m $name @keys");
    +{mesh @keys, @values };
}


sub set {
    my ($self, $name, $key) = @_;
    $self->_execute("s $name $key") eq 'Yes';
}


sub bulk {
    my ($self, $name, @keys) = @_;
    @keys
      or return;
    $self->_execute("b $name @keys");
    return;
}


sub info {
    my ($self, $name) = @_;
    +{ map { split / / } $self->_execute("info $name") };
}


sub flush {
    my ($self, $name) = @_;
    $self->_execute("info $name") eq "Done";
}

sub _execute {
    my ($self, $command) = @_;
	if ($self->_pid ne $$) {
		$self->_clear_socket;
		$self->_clear_pid;
	}
    my $socket = $self->_socket;

    local $\;
    $socket->print($command . $CRLF)
      or croak "couldn't write to socket";

    my $line = $self->_check_line($socket->getline);
    $line =~ /^Client Error:/
      and croak "$line: $command";

    $line eq 'START'
      or return $line;

    my @lines;
    while (1) {
        $line = $self->_check_line($socket->getline);
        $line eq 'END'
          and last;
        push @lines, $line;
    }

    return @lines;
}

sub _check_line {
    my ($self, $line) = @_;
    if (!defined $line) {
        my $e = $!;
        if (any { $_ } ( $!{EWOULDBLOCK}, $!{EAGAIN}, $!{ETIMEDOUT} )) {
            $e = strerror(ETIMEDOUT);
            $self->disconnect;
        }
        undef $!;
        croak $e;
    }
    $line =~ s/$CR?$LF?$//;    
    return $line;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bloomd::Client - Perl client to the bloomd server

=head1 VERSION

version 0.27

=head1 SYNOPSIS

  use feature ':5.12';
  use Bloomd::Client;
  my $b = Bloomd::Client->new( timeout => 0.2 );
  my $filter = 'test_filter';
  $b->create($filter);
  my $array_ref = $b->list();
  my $hash_ref = $b->info($filter);
  $b->set($filter, 'u1');
  if ($b->check($filter, 'u1')) { say "it exists!" }
  my $hashref = $b->multi( $filter, qw(u1 u2 u3) );

=head1 DESCRIPTION

This is a Perl client to connect to the Bloomd server. See
L<http://armon.github.io/bloomd/> for the server website.

=head1 ATTRIBUTES

=head2 protocol

The protocol. ro, defaults to 'tcp'

=head2 host

The host to connect to. ro, defaults to '127.0.0.1'

=head2 port

The port to connect to. ro, defaults to '8673'

=head2 timeout

The timeout (on read and write), in seconds. Can be a float. ro, defaults to 10.

=head1 METHODS

=head2 disconnect

Closes the connection and reset the internal socket

=head2 create

Creates a new bloom filter

  $b->create($name, $capacity?, $probability?, $in_memory=0|1?)

Only the name is mandatory. You can specify the initial capacity (if not the
filter will be enlarged as needed), the probability of maximum false positives
you want, and a flag to force the filter to not be in memory (by default it is).

Returns true if the filter didn't exist and was created successfully.

=head2 list

  my $array_ref = $b->list($prefix?)

Returns an ArrayRef of the existing filters. You can provide a prefix to filter
on them.

=head2 drop

  $b->drop($name)

Drops a filter. Returns true if the filter existed and was removed properly.

=head2 close

  $b->close($name)

Closes a filter. Returns true on success.

=head2 clear

  $b->clear($name)

Clears a filter. Returns tru on success.

=head2 check

  if ($b->check($name, $key)) {
    print "the element $key matched\n";
  }

Given a filter name and a key name, returns true if the key was previously
added in the filter (using C<set>).

=head2 multi

  my $hash_ref = $b->multi($name, $key1, key2, key3);

Given a filter name and a list of elements, returns a HashRef, which keys are
the elements, and the values are 1 or 0, depending if the element is present in
the filter or not.

=head2 set

  $b->set($name, $key);

Adds the element to the given filter. Returns 1 if the elements was not
previously in the filter and was properly added.

=head2 bulk

  $b->bulk($name, $key1, $key2, $key3);

Adds the elements to the given filter. Returns void

=head2 info

  my $hash_ref = $b->info($name);

Returns a HashRef giving informations about the given filter name.

=head2 flush

  $b->flush($name);

Flushes the filter. Returns true on success.

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
