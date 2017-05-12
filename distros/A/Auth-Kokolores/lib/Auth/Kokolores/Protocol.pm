package Auth::Kokolores::Protocol;

use Moose;

# ABSTRACT: base class for implementing a kokolores protocol handler
our $VERSION = '1.01'; # VERSION

has 'server' => (
  is => 'ro',
  isa => 'Net::Server',
  required => 1,
  handles => {
    'log' => 'log',
  },
);

has 'handle' => (
  is => 'ro', isa => 'IO::Handle', required => 1,
);

sub init_connection {
  my ( $self ) = @_;
  return;
}

sub read_request {
  my ( $self ) = @_;
  die('NOT IMPLEMENTED');
  return;
}

sub write_response {
  my ( $self, $response ) = @_;
  die('NOT IMPLEMENTED');
  return;
}

sub shutdown_connection {
  my ( $self ) = @_;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Protocol - base class for implementing a kokolores protocol handler

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
