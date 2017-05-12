package Auth::Kokolores::Protocol::CyrusSaslauthd;

use Moose;
extends 'Auth::Kokolores::Protocol';

# ABSTRACT: saslauthd protocol implementation for kokolores
our $VERSION = '1.01'; # VERSION

use Auth::Kokolores::Request;

sub _read_sasl_string {
  my ( $conn ) = @_;
  my $buf;
  $conn->read($buf, 2);
  my $size = unpack('n', $buf);
  if( ! defined $size ) {
    die('protocol error: could not read size of next string');
  }
  $conn->read($buf, $size);
  return unpack("A$size", $buf);
}

sub read_request {
  my $self = shift;
  my %opts;

  foreach my $field ('username', 'password', 'service', 'realm') {
    $opts{$field} = _read_sasl_string( $self->handle );
  }

  return Auth::Kokolores::Request->new(
    username => $opts{'username'},
    password => $opts{'password'},
    parameters => {
      service => $opts{'service'},
      realm => $opts{'realm'},
    },
    server => $self->server,
  );
}

sub write_response {
  my ( $self, $response ) = @_;
  my $message = 'NO';

  if( $response->success ) {
    $message = 'OK';
  }

  my $size = length($message) + 1;
  $self->handle->print( pack("nA$size", $size, $message."\0") );


  return;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Protocol::CyrusSaslauthd - saslauthd protocol implementation for kokolores

=head1 VERSION

version 1.01

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
