package Apache::Session::Serialize::SOAPEnvelope;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';
use SOAP::Lite ();

sub serialize {
    my $session = shift;
    my $serializer = SOAP::Serializer->new();
    $session->{serialized} = $serializer->serialize($session->{data});
}

sub unserialize {
    my $session = shift;
    my $deserializer = SOAP::Deserializer->new();
    my $decoded = $deserializer->decode($session->{serialized});
    $session->{data} = $deserializer->decode_object($decoded);
}

1;

__END__

=head1 NAME

Apache::Session::Serialize::SOAPEnvelope - serialize as SOAPEnvelope

=head1 SYNOPSIS

  use Apache::Session::Flex;

  tie %session, 'Apache::Session::Flex', $id, {
       Store     => 'MySQL',
       Lock      => 'Null',
       Generate  => 'MD5',
       Serialize => 'SOAPEnvelope',
  };


=head1 DESCRIPTION

Apache::Session::Serialize::SOAPEnvelope provides L<Apache::Session> 
serialization as SOAP Envelope.
SOAP Envelope is XML and You can share session data with other Language 
which supports SOAP.(eg. Ruby, Python, Java..)

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session> L<SOAP::Lite> L<Apache::Session::Serialize::YAML>

=cut
