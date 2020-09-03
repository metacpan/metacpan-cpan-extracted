package Alien::Base::ModuleBuild::Repository::FTP;

use strict;
use warnings;
use parent 'Alien::Base::ModuleBuild::Repository';
use Carp;
use Net::FTP;

# ABSTRACT: HTTP repository handler
our $VERSION = '1.15'; # VERSION

sub connection {
  my $self = shift;

  return $self->{connection}
    if $self->{connection};

  # allow easy use of Net::FTP subclass
  $self->{protocol_class} ||= 'Net::FTP';

  my $server = $self->{host}
    or croak "Must specify a host for FTP service";

  my $ftp = $self->{protocol_class}->new($server, Debug => 0)
    or croak "Cannot connect to $server: $@";

  $ftp->login()
    or croak "Cannot login ", $ftp->message;

  if (defined $self->location) {
    $ftp->cwd($self->location)
      or croak "Cannot change working directory ", $ftp->message;
  }

  $ftp->binary();
  $self->{connection} = $ftp;

  return $ftp;
}

sub get_file {
  my $self = shift;
  my $file = shift || croak "Must specify file to download";

  my $ftp = $self->connection();

  $ftp->get( $file ) or croak "Download failed: " . $ftp->message();

  return $file;
}

sub list_files {
  my $self = shift;
  return $self->connection->ls();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::ModuleBuild::Repository::FTP - HTTP repository handler

=head1 VERSION

version 1.15

=head1 AUTHOR

Original author: Joel A Berger E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

David Mertens (run4flat)

Mark Nunberg (mordy, mnunberg)

Christian Walde (Mithaldu)

Brian Wightman (MidLifeXis)

Graham Ollis (plicease)

Zaki Mughal (zmughal)

mohawk2

Vikas N Kumar (vikasnkumar)

Flavio Poletti (polettix)

Salvador Fandiño (salva)

Gianni Ceccarelli (dakkar)

Pavel Shaydo (zwon, trinitum)

Kang-min Liu (劉康民, gugod)

Nicholas Shipp (nshp)

Petr Pisar (ppisar)

Alberto Simões (ambs)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2020 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
