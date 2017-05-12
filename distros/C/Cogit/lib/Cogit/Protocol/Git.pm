package Cogit::Protocol::Git;
$Cogit::Protocol::Git::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base qw( Int Str );
use IO::Socket::INET;
use namespace::clean;

extends 'Cogit::Protocol';

has hostname => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);

has port => (
   is      => 'ro',
   isa     => Int,
   default => sub { 9418 },
);

has project => (
   is       => 'rw',
   isa      => Str,
   required => 1,
);

sub connect_socket {
   my $self = shift;

   my $socket = IO::Socket::INET->new(
      PeerAddr => $self->hostname,
      PeerPort => $self->port,
      Proto    => 'tcp'
   ) || die $! . ' ' . $self->hostname . ':' . $self->port;
   $socket->autoflush(1) || die $!;
   $self->read_socket($socket);
   $self->write_socket($socket);

   $self->send_line(
      "git-upload-pack " . $self->project . "\0host=" . $self->hostname . "\0");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Protocol::Git

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
