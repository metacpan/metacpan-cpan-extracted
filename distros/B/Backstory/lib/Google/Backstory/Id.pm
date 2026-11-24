package Google::Backstory::Id;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChJiYWNrc3RvcnkvaWQucHJvdG8SEGdvb2dsZS5iYWNrc3RvcnkitwIKAklkEjwKCW5hbWVz
cGFjZRgBIAEoDjIeLmdvb2dsZS5iYWNrc3RvcnkuSWQuTmFtZXNwYWNlUgluYW1lc3BhY2US
DgoCaWQYAiABKAxSAmlkEhsKCXN0cmluZ19pZBgDIAEoCVIIc3RyaW5nSWQixQEKCU5hbWVz
cGFjZRIYChROT1JNQUxJWkVEX1RFTEVNRVRSWRAAEhEKDVJBV19URUxFTUVUUlkQARITCg9S
VUxFX0RFVEVDVElPTlMQAhINCglVUFBFUkNBU0UQAxIYChRNQUNISU5FX0lOVEVMTElHRU5D
RRAEEhsKF1NFQ1VSSVRZX0NPTU1BTkRfQ0VOVEVSEAUSDwoLVU5TUEVDSUZJRUQQBhIOCgpT
T0FSX0FMRVJUEAcSDwoLVklSVVNfVE9UQUwQCEKJAQoUY29tLmdvb2dsZS5iYWNrc3RvcnlQ
AVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYWNrc3RvcnkvYmFja3N0b3J5cGI7YmFja3N0b3J5
cGKqAhBHb29nbGUuQmFja3N0b3J5ygIQR29vZ2xlXEJhY2tzdG9yeeoCEUdvb2dsZTo6QmFj
a3N0b3J5StcRCgYSBA4ARwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQABkKCAoBCBIDEgAtCgkKAgglEgMSAC0KCAoBCBIDEwBMCgkKAggLEgMTAEwKCAoB
CBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAtCgkKAggBEgMVAC0KCAoBCBIDFgArCgkKAggp
EgMWACsKCAoBCBIDFwAqCgkKAggtEgMXACoK8AIKAgQAEgQeAEcBGuMCIElkZW50aWZpZXIg
dG8gaWRlbnRpZnkgYSBVRE0gb2JqZWN0IGxpa2UgYSBVRE0gZXZlbnQsIEVudGl0eSwgQ29s
bGVjdGlvbi4KIFRoZSBmdWxsIGlkZW50aWZpZXIgZm9yIHBlcnNpc3RlbmNlIGlzIGNyZWF0
ZWQgYnkgc2V0dGluZyB0aGUgMzIgbW9zdAogc2lnbmlmaWNhbnQgYml0cyBhcyB0aGUgSWQu
TmFtZXNwYWNlIGVudW0gVGhpcyBpcyBhIGNvbnZlbmllbmNlIHdyYXBwZXIgdG8KIGRlZmlu
ZSB0aGUgaWQgc3BhY2UgZW51bSB2YWx1ZXMgYW5kIHByb3ZpZGUgYW4gZWFzeSBpbnRlcmZh
Y2UgZm9yIFJQQ3MsIG1vc3QKIHBlcnNpc3RlbmNlIHVzZSBjYXNlcyBzaG91bGQgdXNlIGEg
ZGVub3JtYWxpemVkIGZvcm0uCgoKCgMEAAESAx4ICgotCgQEAAQAEgQgAjsDGh8gRXh0cmFj
dGVkIE5hbWVzcGFjZSBDb21wb25lbnQKCgwKBQQABAABEgMgBxAKOQoGBAAEAAIAEgMiBB0a
KiBJbmdlc3RlZCBhbmQgTm9ybWFsaXplZCB0ZWxlbWV0cnkgZXZlbnRzCgoOCgcEAAQAAgAB
EgMiBBgKDgoHBAAEAAIAAhIDIhscCicKBgQABAACARIDJQQWGhggSW5nZXN0ZWQgUmF3IHRl
bGVtZXRyeQoKDgoHBAAEAAIBARIDJQQRCg4KBwQABAACAQISAyUUFQonCgYEAAQAAgISAygE
GBoYIENocm9uaWNsZSBSdWxlcyBlbmdpbmUKCg4KBwQABAACAgESAygEEwoOCgcEAAQAAgIC
EgMoFhcKGgoGBAAEAAIDEgMrBBIaCyBVcHBlcmNhc2UKCg4KBwQABAACAwESAysEDQoOCgcE
AAQAAgMCEgMrEBEKLAoGBAAEAAIEEgMuBB0aHSBEU01MIC0gTWFjaGluZSBJbnRlbGxpZ2Vu
Y2UKCg4KBwQABAACBAESAy4EGAoOCgcEAAQAAgQCEgMuGxwKUgoGBAAEAAIFEgMxBCAaQyBB
IG5vcm1hbGl6ZWQgdGVsZW1ldHJ5IGV2ZW50IGZyb20gR29vZ2xlIFNlY3VyaXR5IENvbW1h
bmQgQ2VudGVyLgoKDgoHBAAEAAIFARIDMQQbCg4KBwQABAACBQISAzEeHwomCgYEAAQAAgYS
AzQEFBoXIFVuc3BlY2lmaWVkIE5hbWVzcGFjZQoKDgoHBAAEAAIGARIDNAQPCg4KBwQABAAC
BgISAzQSEwpFCgYEAAQAAgcSAzcEExo2IEFuIGFsZXJ0IGNvbWluZyBmcm9tIG90aGVyIFNJ
RU1zIHZpYSBDaHJvbmljbGUgU09BUi4KCg4KBwQABAACBwESAzcEDgoOCgcEAAQAAgcCEgM3
ERIKHAoGBAAEAAIIEgM6BBQaDSBWaXJ1c1RvdGFsLgoKDgoHBAAEAAIIARIDOgQPCg4KBwQA
BAACCAISAzoSEworCgQEAAIAEgM+AhoaHiBOYW1lc3BhY2UgdGhlIGlkIGJlbG9uZ3MgdG8u
CgoMCgUEAAIABhIDPgILCgwKBQQAAgABEgM+DBUKDAoFBAACAAMSAz4YGQobCgQEAAIBEgNB
Ag8aDiBGdWxsIHJhdyBJRC4KCgwKBQQAAgEFEgNBAgcKDAoFBAACAQESA0EICgoMCgUEAAIB
AxIDQQ0OCqkBCgQEAAICEgNGAhcamwEgU29tZSBpZHMgYXJlIHN0b3JlZCBhcyBzdHJpbmdz
IHRoYXQgYXJlIG5vdCBhYmxlIHRvIGJlIHRyYW5zbGF0ZWQgdG8gYnl0ZXMsCiBzbyBzdG9y
ZSB0aGVzZSBzZXBhcmF0ZWx5LgogRXguIGRldGVjdGlvbiBpZCBvZiB0aGUgZm9ybSBkZV9h
YWFhYWFhYS1hYWFhLi4uCgoMCgUEAAICBRIDRgIICgwKBQQAAgIBEgNGCRIKDAoFBAACAgMS
A0YVFmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Backstory::Id::Id ===
    # Fields for Id
    # Field: namespace Type: 14 (.google.backstory.Id.Namespace)
    # Field: id Type: 12 ()
    # Field: string_id Type: 9 ()

# Enum: Id::Namespace
our $Id_NORMALIZED_TELEMETRY = 0;
our $Id_RAW_TELEMETRY = 1;
our $Id_RULE_DETECTIONS = 2;
our $Id_UPPERCASE = 3;
our $Id_MACHINE_INTELLIGENCE = 4;
our $Id_SECURITY_COMMAND_CENTER = 5;
our $Id_UNSPECIFIED = 6;
our $Id_SOAR_ALERT = 7;
our $Id_VIRUS_TOTAL = 8;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Backstory::Id - Compiled Protocol Buffers messages for backstory/id.proto

=head1 SYNOPSIS

    use Google::Backstory::Id;

    my $msg = Google::Backstory::Id::Id->new({
        namespace => $namespace,
        id => $id,
        string_id => $string_id,
    });

    # Read or update a field
    my $val = $msg->namespace();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Backstory::Id::Id->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<backstory/id.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Backstory::Id::Id

Identifier to identify a UDM object like a UDM event, Entity, Collection.
The full identifier for persistence is created by setting the 32 most
significant bits as the Id.Namespace enum This is a convenience wrapper to
define the id space enum values and provide an easy interface for RPCs, most
persistence use cases should use a denormalized form.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->namespace() >> / C<< $msg->namespace($value) >>

Type: C<Enum> (L<Google::Backstory::Id::Namespace>)

Namespace the id belongs to.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Bytes>

Full raw ID.

=item * C<< $msg->string_id() >> / C<< $msg->string_id($value) >>

Type: C<String>

Some ids are stored as strings that are not able to be translated to bytes,
so store these separately.
Ex. detection id of the form de_aaaaaaaa-aaaa...

=back

=head3 Enum: Id::Namespace

=over 4

=item * C<NORMALIZED_TELEMETRY> => C<0>

=item * C<RAW_TELEMETRY> => C<1>

=item * C<RULE_DETECTIONS> => C<2>

=item * C<UPPERCASE> => C<3>

=item * C<MACHINE_INTELLIGENCE> => C<4>

=item * C<SECURITY_COMMAND_CENTER> => C<5>

=item * C<UNSPECIFIED> => C<6>

=item * C<SOAR_ALERT> => C<7>

=item * C<VIRUS_TOTAL> => C<8>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Backstory::Id::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
