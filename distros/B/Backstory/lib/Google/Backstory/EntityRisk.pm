package Google::Backstory::EntityRisk;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
ChtiYWNrc3RvcnkvZW50aXR5X3Jpc2sucHJvdG8SEGdvb2dsZS5iYWNrc3RvcnkaHmdvb2ds
ZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90bxoaZ29vZ2xlL3R5cGUvaW50ZXJ2YWwucHJvdG8izgYKCkVudGl0eVJpc2sSIQoMcmlz
a192ZXJzaW9uGAEgASgJUgtyaXNrVmVyc2lvbhI2CgtyaXNrX3dpbmRvdxgCIAEoCzIVLmdv
b2dsZS50eXBlLkludGVydmFsUgpyaXNrV2luZG93EjYKFURFUFJFQ0FURURfcmlza19zY29y
ZRgDIAEoBUICGAFSE0RFUFJFQ0FURURSaXNrU2NvcmUSPwoKcmlza19kZWx0YRgEIAEoCzIb
Lmdvb2dsZS5iYWNrc3RvcnkuUmlza0RlbHRhSABSCXJpc2tEZWx0YYgBARIpChBkZXRlY3Rp
b25zX2NvdW50GAUgASgFUg9kZXRlY3Rpb25zQ291bnQSTAoUZmlyc3RfZGV0ZWN0aW9uX3Rp
bWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhJmaXJzdERldGVjdGlvblRp
bWUSSgoTbGFzdF9kZXRlY3Rpb25fdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l
c3RhbXBSEWxhc3REZXRlY3Rpb25UaW1lEh0KCnJpc2tfc2NvcmUYCCABKAJSCXJpc2tTY29y
ZRIyChVub3JtYWxpemVkX3Jpc2tfc2NvcmUYCSABKAVSE25vcm1hbGl6ZWRSaXNrU2NvcmUS
QwoQcmlza193aW5kb3dfc2l6ZRgKIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIO
cmlza1dpbmRvd1NpemUSRgoOcmF3X3Jpc2tfZGVsdGEYCyABKAsyGy5nb29nbGUuYmFja3N0
b3J5LlJpc2tEZWx0YUgBUgxyYXdSaXNrRGVsdGGIAQESQgoPbGFzdF9yZXNldF90aW1lGAwg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFINbGFzdFJlc2V0VGltZRIdCgpkZXRh
aWxfdXJpGA0gASgJUglkZXRhaWxVcmkSQgoecmlza193aW5kb3dfaGFzX25ld19kZXRlY3Rp
b25zGA4gASgIUhpyaXNrV2luZG93SGFzTmV3RGV0ZWN0aW9uc0INCgtfcmlza19kZWx0YUIR
Cg9fcmF3X3Jpc2tfZGVsdGEi8QEKCVJpc2tEZWx0YRJRChdwcmV2aW91c19yYW5nZV9lbmRf
dGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSFHByZXZpb3VzUmFuZ2VF
bmRUaW1lEigKEHJpc2tfc2NvcmVfZGVsdGEYAiABKAVSDnJpc2tTY29yZURlbHRhEi4KE3By
ZXZpb3VzX3Jpc2tfc2NvcmUYAyABKAVSEXByZXZpb3VzUmlza1Njb3JlEjcKGHJpc2tfc2Nv
cmVfbnVtZXJpY19kZWx0YRgEIAEoBVIVcmlza1Njb3JlTnVtZXJpY0RlbHRhQpoBChRjb20u
Z29vZ2xlLmJhY2tzdG9yeUIPRW50aXR5Umlza1Byb3RvUAFaNWNsb3VkLmdvb2dsZS5jb20v
Z28vYmFja3N0b3J5L2JhY2tzdG9yeXBiO2JhY2tzdG9yeXBiqgIQR29vZ2xlLkJhY2tzdG9y
ecoCEEdvb2dsZVxCYWNrc3RvcnnqAhFHb29nbGU6OkJhY2tzdG9yeUqqHQoGEgQOAGcBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAZCgkKAgMAEgMSACgK
CQoCAwESAxMAKQoJCgIDAhIDFAAkCggKAQgSAxYALQoJCgIIJRIDFgAtCggKAQgSAxcATAoJ
CgIICxIDFwBMCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAMAoJCgIICBIDGQAwCggK
AQgSAxoALQoJCgIIARIDGgAtCggKAQgSAxsAKwoJCgIIKRIDGwArCggKAQgSAxwAKgoJCgII
LRIDHAAqCoUCCgIEABIEJABYARo8IFN0b3JlcyBpbmZvcm1hdGlvbiByZWxhdGVkIHRvIHRo
ZSByaXNrIHNjb3JlIG9mIGFuIGVudGl0eS4KMroBIFRoaXMgaXMgYnJhbmNoZWQgb2YgdGhl
IG9yaWdpbmFsIGVudGl0eS5wcm90byBpbgogZ29vZ2xleC9zZWN1cml0eS9tYWxhY2hpdGUv
cHJvdG8vZXh0ZXJuYWwvZW50aXR5LnByb3RvLgogVGhpcyBpcyB0byBhdm9pZCB0aGUgY2ly
Y3VsYXIgZGVwZW5kZW5jeSBiZXR3ZWVuIHVkbS5wcm90byBhbmQKIGVudGl0eS5wcm90by4K
CgoKAwQAARIDJAgSCj8KBAQAAgASAyYCGhoyIFZlcnNpb24gb2YgdGhlIHJpc2sgc2NvcmUg
Y2FsY3VsYXRpb24gYWxnb3JpdGhtLgoKDAoFBAACAAUSAyYCCAoMCgUEAAIAARIDJgkVCgwK
BQQAAgADEgMmGBkKbQoEBAACARIDKgInGmAgVGltZSB3aW5kb3cgdXNlZCB3aGVuIGNvbXB1
dGluZyB0aGUgcmlzayBzY29yZSBmb3IgYW4gZW50aXR5LCBmb3IKIGV4YW1wbGUgMjQgaG91
cnMgb3IgNyBkYXlzLgoKDAoFBAACAQYSAyoCFgoMCgUEAAIBARIDKhciCgwKBQQAAgEDEgMq
JSYKJgoEBAACAhIELQIuPRoYIERlcHJlY2F0ZWQgcmlzayBzY29yZS4KCgwKBQQAAgIFEgMt
AgcKDAoFBAACAgESAy0IHQoMCgUEAAICAxIDLSAhCgwKBQQAAgIIEgMuBjwKDQoGBAACAggD
EgMuBxgKDAoFBAACAgoSAy4aOwoMCgUEAAICChIDLiY7CpYBCgQEAAIDEgMyAiQaiAEgUmVw
cmVzZW50cyB0aGUgY2hhbmdlIGluIHJpc2sgc2NvcmUgZm9yIGFuIGVudGl0eSBiZXR3ZWVu
IHRoZSBlbmQgb2YgdGhlCiBwcmV2aW91cyB0aW1lIHdpbmRvdyBhbmQgdGhlIGVuZCBvZiB0
aGUgY3VycmVudCB0aW1lIHdpbmRvdy4KCgwKBQQAAgMEEgMyAgoKDAoFBAACAwYSAzILFAoM
CgUEAAIDARIDMhUfCgwKBQQAAgMDEgMyIiMKVwoEBAACBBIDNQIdGkogTnVtYmVyIG9mIGRl
dGVjdGlvbnMgdGhhdCBtYWtlIHVwIHRoZSByaXNrIHNjb3JlIHdpdGhpbiB0aGUgdGltZSB3
aW5kb3cuCgoMCgUEAAIEBRIDNQIHCgwKBQQAAgQBEgM1CBgKDAoFBAACBAMSAzUbHAqEAQoE
BAACBRIDOQI1GncgVGltZXN0YW1wIG9mIHRoZSBmaXJzdCBkZXRlY3Rpb24gd2l0aGluIHRo
ZSBzcGVjaWZpZWQgdGltZSB3aW5kb3cuCiBUaGlzIGZpZWxkIGlzIGVtcHR5IHdoZW4gdGhl
cmUgYXJlIG5vIGRldGVjdGlvbnMuCgoMCgUEAAIFBhIDOQIbCgwKBQQAAgUBEgM5HDAKDAoF
BAACBQMSAzkzNAqDAQoEBAACBhIDPQI0GnYgVGltZXN0YW1wIG9mIHRoZSBsYXN0IGRldGVj
dGlvbiB3aXRoaW4gdGhlIHNwZWNpZmllZCB0aW1lIHdpbmRvdy4KIFRoaXMgZmllbGQgaXMg
ZW1wdHkgd2hlbiB0aGVyZSBhcmUgbm8gZGV0ZWN0aW9ucy4KCgwKBQQAAgYGEgM9AhsKDAoF
BAACBgESAz0cLwoMCgUEAAIGAxIDPTIzCi0KBAQAAgcSA0ACFxogIFJhdyByaXNrIHNjb3Jl
IGZvciB0aGUgZW50aXR5LgoKDAoFBAACBwUSA0ACBwoMCgUEAAIHARIDQAgSCgwKBQQAAgcD
EgNAFRYKUgoEBAACCBIDQwIiGkUgTm9ybWFsaXplZCByaXNrIHNjb3JlIGZvciB0aGUgZW50
aXR5LiBUaGlzIHZhbHVlIGlzIGJldHdlZW4gMC0xMDAwLgoKDAoFBAACCAUSA0MCBwoMCgUE
AAIIARIDQwgdCgwKBQQAAggDEgNDICEKMwoEBAACCRIDRgIxGiYgUmlzayB3aW5kb3cgZHVy
YXRpb24gZm9yIHRoZSBlbnRpdHkuCgoMCgUEAAIJBhIDRgIaCgwKBQQAAgkBEgNGGysKDAoF
BAACCQMSA0YuMAqaAQoEBAACChIDSgIpGowBIFJlcHJlc2VudHMgdGhlIGNoYW5nZSBpbiBy
YXcgcmlzayBzY29yZSBmb3IgYW4gZW50aXR5IGJldHdlZW4gdGhlIGVuZCBvZgogdGhlIHBy
ZXZpb3VzIHRpbWUgd2luZG93IGFuZCB0aGUgZW5kIG9mIHRoZSBjdXJyZW50IHRpbWUgd2lu
ZG93LgoKDAoFBAACCgQSA0oCCgoMCgUEAAIKBhIDSgsUCgwKBQQAAgoBEgNKFSMKDAoFBAAC
CgMSA0omKAp1CgQEAAILEgNOAjEaaCBUaW1lc3RhbXAgZm9yIFVFQkEgcmlzayBzY29yZSBy
ZXNldCBiYXNlZCBkZWR1cGxpY2F0aW9uLiBVc2VkIHNwZWNpZmljYWxseQogZm9yIHJpc2sg
YmFzZWQgbWV0YSBydWxlcy4KCgwKBQQAAgsGEgNOAhsKDAoFBAACCwESA04cKwoMCgUEAAIL
AxIDTi4wCvIBCgQEAAIMEgNUAhka5AEgTGluayB0byB0aGUgR29vZ2xlIFNlY3VyaXR5IE9w
ZXJhdGlvbnMgVUkgd2l0aCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgZW50aXR5CiByaXNrIHNj
b3JlLgogSWYgdGhlIFNlY09wcyBpbnN0YW5jZSBoYXMgbXVsdGlwbGUgZnJvbnRlbmQgcGF0
aHMgY29uZmlndXJlZCwgdGhpcyB3aWxsIGJlCiBhIHJlbGF0aXZlIHBhdGggdGhhdCBjYW4g
YmUgdXNlZCB0byBjb25zdHJ1Y3QgdGhlIGZ1bGwgVVJMLgoKDAoFBAACDAUSA1QCCAoMCgUE
AAIMARIDVAkTCgwKBQQAAgwDEgNUFhgKRAoEBAACDRIDVwIrGjcgV2hldGhlciB0aGVyZSBh
cmUgbmV3IGRldGVjdGlvbnMgZm9yIHRoZSByaXNrIHdpbmRvdy4KCgwKBQQAAg0FEgNXAgYK
DAoFBAACDQESA1cHJQoMCgUEAAINAxIDVygqClAKAgQBEgRbAGcBGkQgRGVzY3JpYmVzIHRo
ZSBkaWZmZXJlbmNlIGluIHJpc2sgc2NvcmUgYmV0d2VlbiB0d28gcG9pbnRzIGluIHRpbWUu
CgoKCgMEAQESA1sIEQo0CgQEAQIAEgNdAjgaJyBFbmQgdGltZSBvZiB0aGUgcHJldmlvdXMg
dGltZSB3aW5kb3cuCgoMCgUEAQIABhIDXQIbCgwKBQQBAgABEgNdHDMKDAoFBAECAAMSA102
NwpYCgQEAQIBEgNgAh0aSyBEaWZmZXJlbmNlIGluIHRoZSBub3JtYWxpemVkIHJpc2sgc2Nv
cmUgZnJvbSB0aGUgcHJldmlvdXMgcmVjb3JkZWQgdmFsdWUuCgoMCgUEAQIBBRIDYAIHCgwK
BQQBAgEBEgNgCBgKDAoFBAECAQMSA2AbHAozCgQEAQICEgNjAiAaJiBSaXNrIHNjb3JlIGZy
b20gcHJldmlvdXMgcmlzayB3aW5kb3cKCgwKBQQBAgIFEgNjAgcKDAoFBAECAgESA2MIGwoM
CgUEAQICAxIDYx4fCkUKBAQBAgMSA2YCJRo4IE51bWVyaWMgY2hhbmdlIGJldHdlZW4gY3Vy
cmVudCBhbmQgcHJldmlvdXMgcmlzayBzY29yZQoKDAoFBAECAwUSA2YCBwoMCgUEAQIDARID
ZgggCgwKBQQBAgMDEgNmIyRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Backstory::EntityRisk::EntityRisk ===
    # Fields for EntityRisk
    # Field: risk_version Type: 9 ()
    # Field: risk_window Type: 11 (.google.type.Interval)
    # Field: DEPRECATED_risk_score Type: 5 ()
    # Field: risk_delta Type: 11 (.google.backstory.RiskDelta)
    # Field: detections_count Type: 5 ()
    # Field: first_detection_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_detection_time Type: 11 (.google.protobuf.Timestamp)
    # Field: risk_score Type: 2 ()
    # Field: normalized_risk_score Type: 5 ()
    # Field: risk_window_size Type: 11 (.google.protobuf.Duration)
    # Field: raw_risk_delta Type: 11 (.google.backstory.RiskDelta)
    # Field: last_reset_time Type: 11 (.google.protobuf.Timestamp)
    # Field: detail_uri Type: 9 ()
    # Field: risk_window_has_new_detections Type: 8 ()

# === Message: Google::Backstory::EntityRisk::RiskDelta ===
    # Fields for RiskDelta
    # Field: previous_range_end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: risk_score_delta Type: 5 ()
    # Field: previous_risk_score Type: 5 ()
    # Field: risk_score_numeric_delta Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Backstory::EntityRisk - Compiled Protocol Buffers messages for backstory/entity_risk.proto

=head1 SYNOPSIS

    use Google::Backstory::EntityRisk;

    my $msg = Google::Backstory::EntityRisk::EntityRisk->new({
        risk_version => $risk_version,
        risk_window => $risk_window,
        DEPRECATED_risk_score => $DEPRECATED_risk_score,
        risk_delta => $risk_delta,
    });

    # Read or update a field
    my $val = $msg->risk_version();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Backstory::EntityRisk::EntityRisk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<backstory/entity_risk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Backstory::EntityRisk::EntityRisk

Stores information related to the risk score of an entity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->risk_version() >> / C<< $msg->risk_version($value) >>

Type: C<String>

Version of the risk score calculation algorithm.

=item * C<< $msg->risk_window() >> / C<< $msg->risk_window($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Time window used when computing the risk score for an entity, for
example 24 hours or 7 days.

=item * C<< $msg->DEPRECATED_risk_score() >> / C<< $msg->DEPRECATED_risk_score($value) >>

Type: C<Int32>

Deprecated risk score.

=item * C<< $msg->risk_delta() >> / C<< $msg->risk_delta($value) >>

Type: C<Message> (L<Google::Backstory::EntityRisk::RiskDelta>)

Represents the change in risk score for an entity between the end of the
previous time window and the end of the current time window.

=item * C<< $msg->detections_count() >> / C<< $msg->detections_count($value) >>

Type: C<Int32>

Number of detections that make up the risk score within the time window.

=item * C<< $msg->first_detection_time() >> / C<< $msg->first_detection_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the first detection within the specified time window.
This field is empty when there are no detections.

=item * C<< $msg->last_detection_time() >> / C<< $msg->last_detection_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp of the last detection within the specified time window.
This field is empty when there are no detections.

=item * C<< $msg->risk_score() >> / C<< $msg->risk_score($value) >>

Type: C<Float>

Raw risk score for the entity.

=item * C<< $msg->normalized_risk_score() >> / C<< $msg->normalized_risk_score($value) >>

Type: C<Int32>

Normalized risk score for the entity. This value is between 0-1000.

=item * C<< $msg->risk_window_size() >> / C<< $msg->risk_window_size($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Risk window duration for the entity.

=item * C<< $msg->raw_risk_delta() >> / C<< $msg->raw_risk_delta($value) >>

Type: C<Message> (L<Google::Backstory::EntityRisk::RiskDelta>)

Represents the change in raw risk score for an entity between the end of
the previous time window and the end of the current time window.

=item * C<< $msg->last_reset_time() >> / C<< $msg->last_reset_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp for UEBA risk score reset based deduplication. Used specifically
for risk based meta rules.

=item * C<< $msg->detail_uri() >> / C<< $msg->detail_uri($value) >>

Type: C<String>

Link to the Google Security Operations UI with information about the entity
risk score.
If the SecOps instance has multiple frontend paths configured, this will be
a relative path that can be used to construct the full URL.

=item * C<< $msg->risk_window_has_new_detections() >> / C<< $msg->risk_window_has_new_detections($value) >>

Type: C<Bool>

Whether there are new detections for the risk window.

=back

=head2 Google::Backstory::EntityRisk::RiskDelta

Describes the difference in risk score between two points in time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->previous_range_end_time() >> / C<< $msg->previous_range_end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

End time of the previous time window.

=item * C<< $msg->risk_score_delta() >> / C<< $msg->risk_score_delta($value) >>

Type: C<Int32>

Difference in the normalized risk score from the previous recorded value.

=item * C<< $msg->previous_risk_score() >> / C<< $msg->previous_risk_score($value) >>

Type: C<Int32>

Risk score from previous risk window

=item * C<< $msg->risk_score_numeric_delta() >> / C<< $msg->risk_score_numeric_delta($value) >>

Type: C<Int32>

Numeric change between current and previous risk score

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Backstory::EntityRisk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
