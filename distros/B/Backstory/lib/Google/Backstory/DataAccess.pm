package Google::Backstory::DataAccess;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
ChtiYWNrc3RvcnkvZGF0YV9hY2Nlc3MucHJvdG8SEGdvb2dsZS5iYWNrc3RvcnkiQgoYRGF0
YUFjY2Vzc0luZ2VzdGlvbkxhYmVsEhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJ
UgV2YWx1ZSKvAgoQRGF0YUFjY2Vzc0xhYmVscxIbCglsb2dfdHlwZXMYASADKAlSCGxvZ1R5
cGVzEi0KEGluZ2VzdGlvbl9sYWJlbHMYAiADKAlCAhgBUg9pbmdlc3Rpb25MYWJlbHMSHgoK
bmFtZXNwYWNlcxgDIAMoCVIKbmFtZXNwYWNlcxIjCg1jdXN0b21fbGFiZWxzGAQgAygJUgxj
dXN0b21MYWJlbHMSWgoTaW5nZXN0aW9uX2t2X2xhYmVscxgFIAMoCzIqLmdvb2dsZS5iYWNr
c3RvcnkuRGF0YUFjY2Vzc0luZ2VzdGlvbkxhYmVsUhFpbmdlc3Rpb25LdkxhYmVscxIuChNh
bGxvd19zY29wZWRfYWNjZXNzGAYgASgIUhFhbGxvd1Njb3BlZEFjY2Vzc0KJAQoUY29tLmdv
b2dsZS5iYWNrc3RvcnlQAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9iYWNrc3RvcnkvYmFja3N0
b3J5cGI7YmFja3N0b3J5cGKqAhBHb29nbGUuQmFja3N0b3J5ygIQR29vZ2xlXEJhY2tzdG9y
eeoCEUdvb2dsZTo6QmFja3N0b3J5StsMCgYSBA4ANQEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQABkKCAoBCBIDEgAtCgkKAgglEgMSAC0KCAoBCBIDEwBM
CgkKAggLEgMTAEwKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAtCgkKAggBEgMVAC0K
CAoBCBIDFgArCgkKAggpEgMWACsKCAoBCBIDFwAqCgkKAggtEgMXACoKNgoCBAASBBoAIAEa
KiBMYWJlbCB1c2VkIGluIGRhdGEgYWNjZXNzIGZvciBpbmdlc3Rpb24uCgoKCgMEAAESAxoI
IAoXCgQEAAIAEgMcAhEaCiBUaGUga2V5LgoKDAoFBAACAAUSAxwCCAoMCgUEAAIAARIDHAkM
CgwKBQQAAgADEgMcDxAKGQoEBAACARIDHwITGgwgVGhlIHZhbHVlLgoKDAoFBAACAQUSAx8C
CAoMCgUEAAIBARIDHwkOCgwKBQQAAgEDEgMfERIKKAoCBAESBCMANQEaHCBMYWJlbCB1c2Vk
IGluIGRhdGEgYWNjZXNzLgoKCgoDBAEBEgMjCBgKJgoEBAECABIDJQIgGhkgQWxsIHRoZSBM
b2dUeXBlIGxhYmVscy4KCgwKBQQBAgAEEgMlAgoKDAoFBAECAAUSAyULEQoMCgUEAQIAARID
JRIbCgwKBQQBAgADEgMlHh8KKAoEBAECARIDKAI7GhsgQWxsIHRoZSBpbmdlc3Rpb24gbGFi
ZWxzLgoKDAoFBAECAQQSAygCCgoMCgUEAQIBBRIDKAsRCgwKBQQBAgEBEgMoEiIKDAoFBAEC
AQMSAyglJgoMCgUEAQIBCBIDKCc6Cg0KBgQBAgEIAxIDKCg5CiIKBAQBAgISAysCIRoVIEFs
bCB0aGUgbmFtZXNwYWNlcy4KCgwKBQQBAgIEEgMrAgoKDAoFBAECAgUSAysLEQoMCgUEAQIC
ARIDKxIcCgwKBQQBAgIDEgMrHyAKQAoEBAECAxIDLgIkGjMgQWxsIHRoZSBjb21wbGV4IGxh
YmVscyAoVURNIHNlYXJjaCBzeW50YXggYmFzZWQpLgoKDAoFBAECAwQSAy4CCgoMCgUEAQID
BRIDLgsRCgwKBQQBAgMBEgMuEh8KDAoFBAECAwMSAy4iIwo6CgQEAQIEEgMxAjwaLSBBbGwg
dGhlIGluZ2VzdGlvbiBsYWJlbHMgKGtleS92YWx1ZSBwYWlycykuCgoMCgUEAQIEBBIDMQIK
CgwKBQQBAgQGEgMxCyMKDAoFBAECBAESAzEkNwoMCgUEAQIEAxIDMTo7CjUKBAQBAgUSAzQC
HxooIEFyZSB0aGUgbGFiZWxzIHJlYWR5IGZvciBzY29wZWQgYWNjZXNzCgoMCgUEAQIFBRID
NAIGCgwKBQQBAgUBEgM0BxoKDAoFBAECBQMSAzQdHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Backstory::DataAccess::DataAccessIngestionLabel ===
    # Fields for DataAccessIngestionLabel
    # Field: key Type: 9 ()
    # Field: value Type: 9 ()

# === Message: Google::Backstory::DataAccess::DataAccessLabels ===
    # Fields for DataAccessLabels
    # Field: log_types Type: 9 ()
    # Field: ingestion_labels Type: 9 ()
    # Field: namespaces Type: 9 ()
    # Field: custom_labels Type: 9 ()
    # Field: ingestion_kv_labels Type: 11 (.google.backstory.DataAccessIngestionLabel)
    # Field: allow_scoped_access Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Backstory::DataAccess - Compiled Protocol Buffers messages for backstory/data_access.proto

=head1 SYNOPSIS

    use Google::Backstory::DataAccess;

    my $msg = Google::Backstory::DataAccess::DataAccessIngestionLabel->new({
        key => $key,
        value => $value,
    });

    # Read or update a field
    my $val = $msg->key();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Backstory::DataAccess::DataAccessIngestionLabel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<backstory/data_access.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Backstory::DataAccess::DataAccessIngestionLabel

Label used in data access for ingestion.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->key() >> / C<< $msg->key($value) >>

Type: C<String>

The key.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The value.

=back

=head2 Google::Backstory::DataAccess::DataAccessLabels

Label used in data access.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->log_types() >> / C<< $msg->log_types($value) >>

Type: C<String>

All the LogType labels.

=item * C<< $msg->ingestion_labels() >> / C<< $msg->ingestion_labels($value) >>

Type: C<String>

All the ingestion labels.

=item * C<< $msg->namespaces() >> / C<< $msg->namespaces($value) >>

Type: C<String>

All the namespaces.

=item * C<< $msg->custom_labels() >> / C<< $msg->custom_labels($value) >>

Type: C<String>

All the complex labels (UDM search syntax based).

=item * C<< $msg->ingestion_kv_labels() >> / C<< $msg->ingestion_kv_labels($value) >>

Type: C<Message> (L<Google::Backstory::DataAccess::DataAccessIngestionLabel>)

All the ingestion labels (key/value pairs).

=item * C<< $msg->allow_scoped_access() >> / C<< $msg->allow_scoped_access($value) >>

Type: C<Bool>

Are the labels ready for scoped access

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Backstory::DataAccess::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
