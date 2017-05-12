package Cogit::Protocol::SSH;
$Cogit::Protocol::SSH::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base 'Str';
use IPC::Open2;
use namespace::clean;

extends 'Cogit::Protocol';

has hostname => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);

has username => (
   is  => 'ro',
   isa => Str,
);

has path => (
   is       => 'ro',
   isa      => Str,
   required => 1,
);

sub connect_socket {
   my $self = shift;

   my ($read, $write);
   my $connect = join('@', grep { defined } $self->username, $self->hostname);
   my $pid = open2($read, $write, "ssh", $connect, "-o", "BatchMode yes",
      "git-upload-pack", $self->path,);

   $read->autoflush(1);
   $write->autoflush(1);
   $self->read_socket($read);
   $self->write_socket($write);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Protocol::SSH

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
