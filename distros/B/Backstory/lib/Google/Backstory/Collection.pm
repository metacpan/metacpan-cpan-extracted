package Google::Backstory::Collection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Backstory::Entity };
    eval { require Google::Backstory::Id };
    eval { require Google::Backstory::Udm };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Type::Interval };
    my $descriptor_b64 = <<'EOF';
ChpiYWNrc3RvcnkvY29sbGVjdGlvbi5wcm90bxIQZ29vZ2xlLmJhY2tzdG9yeRoWYmFja3N0
b3J5L2VudGl0eS5wcm90bxoSYmFja3N0b3J5L2lkLnByb3RvGhNiYWNrc3RvcnkvdWRtLnBy
b3RvGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9z
dHJ1Y3QucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8aGmdvb2dsZS90
eXBlL2ludGVydmFsLnByb3RvIvkNCgpDb2xsZWN0aW9uEg4KAmlkGAcgASgJUgJpZBI/CgR0
eXBlGAEgASgOMisuZ29vZ2xlLmJhY2tzdG9yeS5Db2xsZWN0aW9uLkNvbGxlY3Rpb25UeXBl
UgR0eXBlEkEKDGlkX25hbWVzcGFjZRgMIAEoDjIeLmdvb2dsZS5iYWNrc3RvcnkuSWQuTmFt
ZXNwYWNlUgtpZE5hbWVzcGFjZRI9CgxjcmVhdGVkX3RpbWUYBSABKAsyGi5nb29nbGUucHJv
dG9idWYuVGltZXN0YW1wUgtjcmVhdGVkVGltZRJGChFsYXN0X3VwZGF0ZWRfdGltZRgGIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD2xhc3RVcGRhdGVkVGltZRI2Cgt0aW1l
X3dpbmRvdxgIIAEoCzIVLmdvb2dsZS50eXBlLkludGVydmFsUgp0aW1lV2luZG93EkoKE2Nv
bGxlY3Rpb25fZWxlbWVudHMYCSADKAsyGS5nb29nbGUuYmFja3N0b3J5LkVsZW1lbnRSEmNv
bGxlY3Rpb25FbGVtZW50cxI+CglkZXRlY3Rpb24YAyADKAsyIC5nb29nbGUuYmFja3N0b3J5
LlNlY3VyaXR5UmVzdWx0UglkZXRlY3Rpb24SQQoOZGV0ZWN0aW9uX3RpbWUYCiABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUg1kZXRlY3Rpb25UaW1lEkUKDWludmVzdGlnYXRp
b24YBCABKAsyHy5nb29nbGUuYmFja3N0b3J5LkludmVzdGlnYXRpb25SDWludmVzdGlnYXRp
b24SEgoEdGFncxgLIAMoCVIEdGFncxJcChZyZXNwb25zZV9wbGF0Zm9ybV9pbmZvGA0gASgL
MiYuZ29vZ2xlLmJhY2tzdG9yeS5SZXNwb25zZVBsYXRmb3JtSW5mb1IUcmVzcG9uc2VQbGF0
Zm9ybUluZm8SGwoJY2FzZV9uYW1lGA4gASgJUghjYXNlTmFtZRIdCgpzb2FyX2FsZXJ0GBEg
ASgIUglzb2FyQWxlcnQSUwoTc29hcl9hbGVydF9tZXRhZGF0YRgSIAEoCzIjLmdvb2dsZS5i
YWNrc3RvcnkuU29hckFsZXJ0TWV0YWRhdGFSEXNvYXJBbGVydE1ldGFkYXRhEioKEWRhdGFf
YWNjZXNzX3Njb3BlGBMgASgJUg9kYXRhQWNjZXNzU2NvcGUSbQoYZGV0ZWN0aW9uX3RpbWlu
Z19kZXRhaWxzGBQgAygOMjMuZ29vZ2xlLmJhY2tzdG9yeS5Db2xsZWN0aW9uLkRldGVjdGlv
blRpbWluZ0RldGFpbHNSFmRldGVjdGlvblRpbWluZ0RldGFpbHMSSQoPbGF0ZW5jeV9tZXRy
aWNzGBUgASgLMiAuZ29vZ2xlLmJhY2tzdG9yeS5MYXRlbmN5TWV0cmljc1IObGF0ZW5jeU1l
dHJpY3MSVwoScnVsZV9ydW5fZnJlcXVlbmN5GBYgASgOMikuZ29vZ2xlLmJhY2tzdG9yeS5D
b2xsZWN0aW9uLlJ1bkZyZXF1ZW5jeVIQcnVsZVJ1bkZyZXF1ZW5jeRIyChVzaW11bGF0ZWRf
ZXZlbnRfY291bnQYFyABKANSE3NpbXVsYXRlZEV2ZW50Q291bnQSMgoVc2ltdWxhdGVkX2V2
ZW50X25hbWVzGBggAygJUhNzaW11bGF0ZWRFdmVudE5hbWVzIrUBCg5Db2xsZWN0aW9uVHlw
ZRIfChtDT0xMRUNUSU9OX1RZUEVfVU5TUEVDSUZJRUQQABITCg9URUxFTUVUUllfQUxFUlQQ
ARIQCgxHQ1RJX0ZJTkRJTkcQAhITCg9VUFBFUkNBU0VfQUxFUlQQAhISCg5SVUxFX0RFVEVD
VElPThADEh4KGk1BQ0hJTkVfSU5URUxMSUdFTkNFX0FMRVJUEAQSDgoKU09BUl9BTEVSVBAF
GgIQASKVAQoWRGV0ZWN0aW9uVGltaW5nRGV0YWlscxIoCiRERVRFQ1RJT05fVElNSU5HX0RF
VEFJTFNfVU5TUEVDSUZJRUQQABIpCiVERVRFQ1RJT05fVElNSU5HX0RFVEFJTFNfUkVQUk9D
RVNTSU5HEAESJgoiREVURUNUSU9OX1RJTUlOR19ERVRBSUxTX1JFVFJPSFVOVBACInwKDFJ1
bkZyZXF1ZW5jeRIdChlSVU5fRlJFUVVFTkNZX1VOU1BFQ0lGSUVEEAASGgoWUlVOX0ZSRVFV
RU5DWV9SRUFMVElNRRABEhgKFFJVTl9GUkVRVUVOQ1lfSE9VUkxZEAISFwoTUlVOX0ZSRVFV
RU5DWV9EQUlMWRADSgQIDxAQSgQIEBARIqsCChVFbnRpdHlHcmFwaEVucmljaG1lbnQSHQoK
ZGF0YV90YWJsZRgBIAEoCVIJZGF0YVRhYmxlEl8KD2VucmljaG1lbnRfdHlwZRgDIAEoDjI2
Lmdvb2dsZS5iYWNrc3RvcnkuRW50aXR5R3JhcGhFbnJpY2htZW50LkVucmljaG1lbnRUeXBl
Ug5lbnJpY2htZW50VHlwZRJFChFvdmVycmlkZGVuX2VudGl0eRgCIAEoCzIYLmdvb2dsZS5i
YWNrc3RvcnkuRW50aXR5UhBvdmVycmlkZGVuRW50aXR5IksKDkVucmljaG1lbnRUeXBlEh8K
G0VOUklDSE1FTlRfVFlQRV9VTlNQRUNJRklFRBAAEgoKBkFQUEVORBABEgwKCE9WRVJSSURF
EAIicwoQRGF0YVRhYmxlUm93SW5mbxIdCgpkYXRhX3RhYmxlGAEgASgJUglkYXRhVGFibGUS
KQoDcm93GAIgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIDcm93EhUKBnJvd19pZBgD
IAEoCVIFcm93SWQiiAMKDkxhdGVuY3lNZXRyaWNzEk4KFW9sZGVzdF9pbmdlc3Rpb25fdGlt
ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSE29sZGVzdEluZ2VzdGlvblRp
bWUSTgoVbmV3ZXN0X2luZ2VzdGlvbl90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp
bWVzdGFtcFITbmV3ZXN0SW5nZXN0aW9uVGltZRJGChFvbGRlc3RfZXZlbnRfdGltZRgDIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD29sZGVzdEV2ZW50VGltZRJGChFuZXdl
c3RfZXZlbnRfdGltZRgEIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSD25ld2Vz
dEV2ZW50VGltZRJGChFpbmdlc3Rpb25fbGF0ZW5jeRgFIAEoCzIZLmdvb2dsZS5wcm90b2J1
Zi5EdXJhdGlvblIQaW5nZXN0aW9uTGF0ZW5jeSLlAgoJUmVmZXJlbmNlEisKBWV2ZW50GAEg
ASgLMhUuZ29vZ2xlLmJhY2tzdG9yeS5VRE1SBWV2ZW50EjAKBmVudGl0eRgCIAEoCzIYLmdv
b2dsZS5iYWNrc3RvcnkuRW50aXR5UgZlbnRpdHkSVwoWam9pbmVkX2RhdGFfdGFibGVfcm93
cxgEIAMoCzIiLmdvb2dsZS5iYWNrc3RvcnkuRGF0YVRhYmxlUm93SW5mb1ITam9pbmVkRGF0
YVRhYmxlUm93cxJSChBncmFwaF9lbnJpY2htZW50GAUgASgLMicuZ29vZ2xlLmJhY2tzdG9y
eS5FbnRpdHlHcmFwaEVucmljaG1lbnRSD2dyYXBoRW5yaWNobWVudBIkCgJpZBgDIAEoCzIU
Lmdvb2dsZS5iYWNrc3RvcnkuSWRSAmlkEiYKD2xvZ19iYXRjaF90b2tlbhgGIAEoCVINbG9n
QmF0Y2hUb2tlbiKaAgoHRWxlbWVudBJCCgthc3NvY2lhdGlvbhgBIAEoCzIgLmdvb2dsZS5i
YWNrc3RvcnkuU2VjdXJpdHlSZXN1bHRSC2Fzc29jaWF0aW9uEjsKCnJlZmVyZW5jZXMYAiAD
KAsyGy5nb29nbGUuYmFja3N0b3J5LlJlZmVyZW5jZVIKcmVmZXJlbmNlcxIUCgVsYWJlbBgD
IAEoCVIFbGFiZWwSLQoScmVmZXJlbmNlc19zYW1wbGVkGAQgASgIUhFyZWZlcmVuY2VzU2Ft
cGxlZBJJCg9sYXRlbmN5X21ldHJpY3MYBSABKAsyIC5nb29nbGUuYmFja3N0b3J5LkxhdGVu
Y3lNZXRyaWNzUg5sYXRlbmN5TWV0cmljcyKKAgoUUmVzcG9uc2VQbGF0Zm9ybUluZm8SGQoI
YWxlcnRfaWQYAiABKAlSB2FsZXJ0SWQScQoWcmVzcG9uc2VfcGxhdGZvcm1fdHlwZRgDIAEo
DjI7Lmdvb2dsZS5iYWNrc3RvcnkuUmVzcG9uc2VQbGF0Zm9ybUluZm8uUmVzcG9uc2VQbGF0
Zm9ybVR5cGVSFHJlc3BvbnNlUGxhdGZvcm1UeXBlImQKFFJlc3BvbnNlUGxhdGZvcm1UeXBl
EiYKIlJFU1BPTlNFX1BMQVRGT1JNX1RZUEVfVU5TUEVDSUZJRUQQABIkCiBSRVNQT05TRV9Q
TEFURk9STV9UWVBFX1NJRU1QTElGWRABIokCChFTb2FyQWxlcnRNZXRhZGF0YRIZCghhbGVy
dF9pZBgBIAEoCVIHYWxlcnRJZBIfCgtzb3VyY2VfcnVsZRgCIAEoCVIKc291cmNlUnVsZRIW
CgZ2ZW5kb3IYAyABKAlSBnZlbmRvchIjCg1zb3VyY2Vfc3lzdGVtGAQgASgJUgxzb3VyY2VT
eXN0ZW0SGAoHcHJvZHVjdBgFIAEoCVIHcHJvZHVjdBI1Chdzb3VyY2Vfc3lzdGVtX3RpY2tl
dF9pZBgGIAEoCVIUc291cmNlU3lzdGVtVGlja2V0SWQSKgoRc291cmNlX3N5c3RlbV91cmkY
ByABKAlSD3NvdXJjZVN5c3RlbVVyaUKJAQoUY29tLmdvb2dsZS5iYWNrc3RvcnlQAVo1Y2xv
dWQuZ29vZ2xlLmNvbS9nby9iYWNrc3RvcnkvYmFja3N0b3J5cGI7YmFja3N0b3J5cGKqAhBH
b29nbGUuQmFja3N0b3J5ygIQR29vZ2xlXEJhY2tzdG9yeeoCEUdvb2dsZTo6QmFja3N0b3J5
SuttCgcSBQ4A8gIBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAZCgkKAgMAEgMSACAKCQoCAwESAxMAHAoJCgIDAhIDFAAdCgkKAgMDEgMVACgKCQoCAwQS
AxYAJgoJCgIDBRIDFwApCgkKAgMGEgMYACQKCAoBCBIDGgAtCgkKAgglEgMaAC0KCAoBCBID
GwBMCgkKAggLEgMbAEwKCAoBCBIDHAAiCgkKAggKEgMcACIKCAoBCBIDHQAtCgkKAggBEgMd
AC0KCAoBCBIDHgArCgkKAggpEgMeACsKCAoBCBIDHwAqCgkKAggtEgMfACoK3QQKAgQAEgUs
AMYBARrPBCBDb2xsZWN0aW9uIHJlcHJlc2VudHMgYSBjb250YWluZXIgb2Ygb2JqZWN0cyAo
c3VjaCBhcyBldmVudHMsIGVudGl0eQogY29udGV4dCBtZXRhZGF0YSwgZGV0ZWN0aW9uIGZp
bmRpbmcgbWV0YWRhdGEpIGFuZCBzdGF0ZSAoc3VjaCBhcwogaW52ZXN0aWdhdGlvbiBkZXRh
aWxzKS4KCiBBbiBleGFtcGxlIHVzZSBjYXNlIGZvciBDb2xsZWN0aW9uIGlzIHRvIG1vZGVs
IGEgZGV0ZWN0aW9uIGFuZCBpbnZlc3RpZ2F0aW9uCiBmcm9tIGRldGVjdGlvbiBmaW5kaW5n
IG1ldGFkYXRhIHRvIGludmVzdGlnYXRpdmUgc3RhdGUgY29sbGVjdGVkIGluIHRoZQogY291
cnNlIG9mIHRoZSBpbnZlc3RpZ2F0aW9uLiBGb3IgbW9yZSBjb21wbGV4IGludmVzdGlnYXRp
b24gYW5kIHJlc3BvbnNlCiB3b3JrZmxvd3MgYSBDb2xsZWN0aW9uIGNvdWxkIHJlcHJlc2Vu
dCBhbiBpbmNpZGVudCBjb25zaXN0aW5nIG9mIG11bHRpcGxlCiBjaGlsZCBmaW5kaW5ncyBv
ciBpbmNpZGVudHMuIFRoaXMgY2FuIGJlIGV4cGFuZGVkIG9uIHRvIG1vZGVsIHJlbWVkaWF0
aW9uCiBlbGVtZW50cyBvZiBhIGZ1bGwgZGV0ZWN0aW9uIGFuZCByZXNwb25zZSB3b3JrZmxv
dy4KCgoKCgMEAAESAywIEgqBAgoEBAAEABIEMQJHAxryASBUaGUgdHlwZSBvZiB0aGUgY29s
bGVjdGlvbiB3aGljaCB3aWxsIGluZGljYXRlIHdoaWNoIG90aGVyIGZpZWxkcyBhcmUKIHJl
bGV2YW50LiBGb3IgZXhhbXBsZSwgZGV0ZWN0aW9uIGZpbmRpbmcgY29sbGVjdGlvbnMgd2ls
bCBwb3B1bGF0ZSB0aGUKIGRldGVjdGlvbiBmaWVsZC4gRmluZGluZ3MgdGhhdCBldm9sdmUg
aW50byBpbnZlc3RpZ2F0aW9ucyB3aWxsIHBvcHVsYXRlIHRoZQogaW52ZXN0aWdhdGlvbiBm
aWVsZC4KCgwKBQQABAABEgMxBxUKDAoFBAAEAAMSAzIEHgoNCgYEAAQAAwISAzIEHgowCgYE
AAQAAgASAzUEJBohIEFuIHVuc3BlY2lmaWVkIGNvbGxlY3Rpb24gdHlwZS4KCg4KBwQABAAC
AAESAzUEHwoOCgcEAAQAAgACEgM1IiMKOQoGBAAEAAIBEgM4BBgaKiBBbiBhbGVydCByZXBv
cnRlZCBpbiBjdXN0b21lciB0ZWxlbWV0cnkuCgoOCgcEAAQAAgEBEgM4BBMKDgoHBAAEAAIB
AhIDOBYXCjMKBgQABAACAhIDOwQVGiQgQSBmaW5kaW5nIGZyb20gdGhlIFVwcGVyY2FzZSB0
ZWFtLgoKDgoHBAAEAAICARIDOwQQCg4KBwQABAACAgISAzsTFAoNCgYEAAQAAgMSAz0EGAoO
CgcEAAQAAgMBEgM9BBMKDgoHBAAEAAIDAhIDPRYXCjYKBgQABAACBBIDQAQXGicgQSBkZXRl
Y3Rpb24gZm91bmQgYnkgYXBwbHlpbmcgYSBydWxlLgoKDgoHBAAEAAIEARIDQAQSCg4KBwQA
BAACBAISA0AVFgpJCgYEAAQAAgUSA0MEIxo6IEFuIGFsZXJ0IGdlbmVyYXRlZCBieSBDaHJv
bmljbGUgbWFjaGluZSBsZWFybmluZyBtb2RlbHMuCgoOCgcEAAQAAgUBEgNDBB4KDgoHBAAE
AAIFAhIDQyEiCkUKBgQABAACBhIDRgQTGjYgQW4gYWxlcnQgY29taW5nIGZyb20gb3RoZXIg
U0lFTXMgdmlhIENocm9uaWNsZSBTT0FSLgoKDgoHBAAEAAIGARIDRgQOCg4KBwQABAACBgIS
A0YREgo8CgQEAAQBEgRKAlMDGi4gRGV0ZWN0aW9uIHRpbWluZyBkZXRhaWxzIGZvciB0aGUg
Y29sbGVjdGlvbi4KCgwKBQQABAEBEgNKBx0KOgoGBAAEAQIAEgNMBC0aKyBEZXRlY3Rpb24g
dGltaW5nIGRldGFpbHMgYXJlIHVuc3BlY2lmaWVkLgoKDgoHBAAEAQIAARIDTAQoCg4KBwQA
BAECAAISA0wrLAo+CgYEAAQBAgESA08ELhovIERldGVjdGlvbiBpcyBnZW5lcmF0ZWQgYnkg
YSByZXByb2Nlc3NpbmcgcnVuLgoKDgoHBAAEAQIBARIDTwQpCg4KBwQABAECAQISA08sLQo7
CgYEAAQBAgISA1IEKxosIERldGVjdGlvbiBpcyBnZW5lcmF0ZWQgYnkgYSByZXRyb2h1bnQg
cnVuLgoKDgoHBAAEAQICARIDUgQmCg4KBwQABAECAgISA1IpKgo4CgQEAAQCEgRWAmIDGiog
UnVuIGZyZXF1ZW5jaWVzIHVzZWQgYnkgcnVsZSBleGVjdXRpb25zLgoKDAoFBAAEAgESA1YH
EworCgYEAAQCAgASA1gEIhocIFVuc3BlY2lmaWVkIHJ1biBmcmVxdWVuY3kuCgoOCgcEAAQC
AgABEgNYBB0KDgoHBAAEAgIAAhIDWCAhCikKBgQABAICARIDWwQfGhogUmVhbC10aW1lIHJ1
biBmcmVxdWVuY3kuCgoOCgcEAAQCAgEBEgNbBBoKDgoHBAAEAgIBAhIDWx0eCicKBgQABAIC
AhIDXgQdGhggRXhlY3V0ZXMgb25jZSBhbiBob3VyLgoKDgoHBAAEAgICARIDXgQYCg4KBwQA
BAICAgISA14bHAolCgYEAAQCAgMSA2EEHBoWIEV4ZWN1dGVzIG9uY2UgYSBkYXkuCgoOCgcE
AAQCAgMBEgNhBBcKDgoHBAAEAgIDAhIDYRobCpkBCgQEAAIAEgNnAhAaiwEgVW5pcXVlIElE
IGZvciB0aGUgY29sbGVjdGlvbi4KIFRoZSBJRCBpcyBzcGVjaWZpYyB0byB0aGUgdHlwZSBv
ZiBjb2xsZWN0aW9uLiBGb3IgZXhhbXBsZSwgd2l0aCBydWxlCiBkZXRlY3Rpb25zIHRoaXMg
aXMgdGhlIGRldGVjdGlvbiBJRC4KCgwKBQQAAgAFEgNnAggKDAoFBAACAAESA2cJCwoMCgUE
AAIAAxIDZw4PCi4KBAQAAgESA2oCGhohIFdoYXQgdGhlIGNvbGxlY3Rpb24gcmVwcmVzZW50
cy4KCgwKBQQAAgEGEgNqAhAKDAoFBAACAQESA2oRFQoMCgUEAAIBAxIDahgZCjgKBAQAAgIS
A20CIRorIFRoZSBJRCBuYW1lc3BhY2UgdXNlZCBmb3IgdGhlIENvbGxlY3Rpb24uCgoMCgUE
AAICBhIDbQIOCgwKBQQAAgIBEgNtDxsKDAoFBAACAgMSA20eIAovCgQEAAIDEgNwAi0aIiBU
aW1lIHRoZSBjb2xsZWN0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACAwYSA3ACGwoMCgUEAAID
ARIDcBwoCgwKBQQAAgMDEgNwKywKNAoEBAACBBIDcwIyGicgVGltZSB0aGUgY29sbGVjdGlv
biB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACBAYSA3MCGwoMCgUEAAIEARIDcxwtCgwKBQQA
AgQDEgNzMDEKPAoEBAACBRIDdgInGi8gVGltZSBpbnRlcnZhbCB0aGF0IHRoZSBjb2xsZWN0
aW9uIHJlcHJlc2VudHMuCgoMCgUEAAIFBhIDdgIWCgwKBQQAAgUBEgN2FyIKDAoFBAACBQMS
A3YlJgrSAgoEBAACBhIDfQIrGsQCIENvbnN0aXR1ZW50IGVsZW1lbnRzIG9mIHRoZSBjb2xs
ZWN0aW9uLiBFYWNoIGVsZW1lbnQgc2hhcmVzIGFuIGFzc29jaWF0aW9uCiB0aGF0IGdyb3Vw
cyBpdCB0b2dldGhlciBhbmQgaXMgYSBjb21wb25lbnQgb2YgdGhlIG92ZXJhbGwgY29sbGVj
dGlvbi4gRm9yCiBleGFtcGxlLCBhIGRldGVjdGlvbiBjb2xsZWN0aW9uIG1heSBoYXZlIHNl
dmVyYWwgY29uc3RpdHVlbnQgZWxlbWVudHMgdGhhdAogZWFjaCBzaGFyZSBhIGNvcnJlbGF0
aW9uIGFzc29jaWF0aW9uIHRoYXQgdG9nZXRoZXIgcmVwcmVzZW50IGEgcGFydGljdWxhcgog
cGF0dGVybiBvciBiZWhhdmlvci4KCgwKBQQAAgYEEgN9AgoKDAoFBAACBgYSA30LEgoMCgUE
AAIGARIDfRMmCgwKBQQAAgYDEgN9KSoKzQEKBAQAAgcSBIIBAigavgEgRGV0ZWN0aW9uIG1l
dGFkYXRhIGZvciBmaW5kaW5ncyB0aGF0IHJlcHJlc2VudCBkZXRlY3Rpb25zLCBjYW4gaW5j
bHVkZQogcnVsZSBkZXRhaWxzLCBtYWNoaW5lIGxlYXJuaW5nIG1vZGVsIG1ldGFkYXRhLCBh
bmQgaW5kaWNhdG9ycyBpbXBsaWNhdGVkCiBpbiB0aGUgZGV0ZWN0aW9uICh1c2luZyB0aGUg
LmFib3V0IGZpZWxkKS4KCg0KBQQAAgcEEgSCAQIKCg0KBQQAAgcGEgSCAQsZCg0KBQQAAgcB
EgSCARojCg0KBQQAAgcDEgSCASYnCtwCCgQEAAIIEgSJAQIwGs0CIFRpbWVzdGFtcCB3aXRo
aW4gdGhlIHRpbWVfd2luZG93IHJlbGF0ZWQgdG8gdGhlIHRpbWUgb2YgdGhlCiBjb2xsZWN0
aW9uX2VsZW1lbnRzLiBGb3IgUnVsZSBEZXRlY3Rpb25zLCB0aGlzIHRpbWVzdGFtcCBpcyB0
aGUgZW5kIG9mIHRoZQogdGhlIHRpbWVfd2luZG93IGZvciBtdWx0aS1ldmVudCBydWxlcyBv
ciB0aGUgdGltZSBvZiB0aGUgZXZlbnQgZm9yIHNpbmdsZQogZXZlbnQgcnVsZXMuIEZvciBs
YXRlLWFycml2aW5nIGV2ZW50cyB0aGF0IHRyaWdnZXIgbmV3IGFsZXJ0cywgdGhlCiBkZXRl
Y3Rpb25fdGltZSB3aWxsIGJlIHRoZSBldmVudCB0aW1lIG9mIHRoZSBldmVudC4KCg0KBQQA
AggGEgSJAQIbCg0KBQQAAggBEgSJARwqCg0KBQQAAggDEgSJAS0vCvEBCgQEAAIJEgSPAQIi
GuIBIENvbnNvbGlkYXRlZCBpbnZlc3RpZ2F0aW9uIGRldGFpbHMgKGNhdGVnb3JpemF0aW9u
LCBzdGF0dXMsIGV0YykgdHlwaWNhbGx5CiBmb3IgY29sbGVjdGlvbnMgdGhhdCBiZWdpbiBh
cyBkZXRlY3Rpb24gZmluZGluZ3MgYW5kIHRoZW4gZXZvbHZlIHdpdGgKIGFuYWx5c3QgYWN0
aW9uIGFuZCBmZWVkYmFjayBpbnRvIGludmVzdGlnYXRpb25zIGFyb3VuZCB0aGUgZGV0ZWN0
aW9uCiBvdXRwdXQuCgoNCgUEAAIJBhIEjwECDwoNCgUEAAIJARIEjwEQHQoNCgUEAAIJAxIE
jwEgIQpHCgQEAAIKEgSSAQIcGjkgVGFncyBzZXQgYnkgVUMvRFNNTC9SRSBmb3IgdGhlIEZp
bmRpbmcgZHVyaW5nIGNyZWF0aW9uLgoKDQoFBAACCgQSBJIBAgoKDQoFBAACCgUSBJIBCxEK
DQoFBAACCgESBJIBEhYKDQoFBAACCgMSBJIBGRsKUgoEBAACCxIElQECMxpEIEFsZXJ0IHJl
bGF0ZWQgaW5mbyBvZiB0aGlzIHNhbWUgYWxlcnQgaW4gY3VzdG9tZXIncyBTT0FSIHBsYXRm
b3JtLgoKDQoFBAACCwYSBJUBAhYKDQoFBAACCwESBJUBFy0KDQoFBAACCwMSBJUBMDIKpgEK
BAQAAgwSBJoBAhgalwEgVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIENhc2UgdGhhdCB0aGlz
IGNvbGxlY3Rpb24gYmVsb25ncyB0by4KIEV4YW1wbGU6CiBwcm9qZWN0cy97cHJvamVjdCBp
ZH0vbG9jYXRpb25zL3tyZWdpb259L2Nocm9uaWNsZS9jYXNlcy97aW50ZXJuYWxfY2FzZV9p
ZH0KCg0KBQQAAgwFEgSaAQIICg0KBQQAAgwBEgSaAQkSCg0KBQQAAgwDEgSaARUXCpEBCgME
AAkSBJ8BAg4agwEgVGhlIGN1cnJlbnQgcHJpbWFyeSBhbmFseXN0IGZlZWRiYWNrLgogVGhp
cyBkb2VzIG5vdCBpbmNsdWRlIHRoZSBoaXN0b3J5IG9mIGZlZWRiYWNrIGdpdmVuLCB3aGlj
aCBtYXkgYmUgc3VwcGxpZWQKIGluIGBmZWVkYmFja2AuCgoMCgQEAAkAEgSfAQsNCg0KBQQA
CQABEgSfAQsNCg0KBQQACQACEgSfAQsNCuwBCgMEAAkSBKUBAg4a3gEgVGhlIGhpc3Rvcnkg
b2YgZmVlZGJhY2sgc3VibWl0dGVkIGJ5IGFuYWx5c3RzIGZvciB0aGlzIGZpbmRpbmcsCiBp
biBkZXNjZW5kaW5nIG9yZGVyIGJ5IHRpbWVzdGFtcC4KIFRoaXMgZmllbGQgaXMgbGltaXRl
ZCB0byB0aGUgbW9zdCByZWNlbnQgMTAwMCBmZWVkYmFjayBldmVudHMuCiBUaGUgcHJpbWFy
eSBmZWVkYmFjayB3aWxsIGFsc28gYmUgaW5jbHVkZWQgaW4gdGhpcyBsaXN0LgoKDAoEBAAJ
ARIEpQELDQoNCgUEAAkBARIEpQELDQoNCgUEAAkBAhIEpQELDQpNCgQEAAINEgSoAQIXGj8g
QSBib29sZWFuIGZpZWxkIGluZGljYXRpbmcgdGhhdCB0aGUgYWxlcnQgaXMgcHJlc2VudCBp
biBTT0FSLgoKDQoFBAACDQUSBKgBAgYKDQoFBAACDQESBKgBBxEKDQoFBAACDQMSBKgBFBYK
UgoEBAACDhIEqwECLRpEIE1ldGFkYXRhIGZpZWxkcyBvZiBhbGVydHMgY29taW5nIGZyb20g
b3RoZXIgU0lFTSBzeXN0ZW1zIHZpYSBTT0FSLgoKDQoFBAACDgYSBKsBAhMKDQoFBAACDgES
BKsBFCcKDQoFBAACDgMSBKsBKiwKTAoEBAACDxIErgECIBo+IFRoZSByZXNvdXJjZSBuYW1l
IG9mIHRoZSBEYXRhQWNjZXNzU2NvcGUgb2YgdGhpcyBjb2xsZWN0aW9uLgoKDQoFBAACDwUS
BK4BAggKDQoFBAACDwESBK4BCRoKDQoFBAACDwMSBK4BHR8K1QEKBAQAAhASBLMBAkAaxgEg
RGV0ZWN0aW9uIHRpbWluZyBkZXRhaWxzIGZvciB0aGUgY29sbGVjdGlvbi4gVGhlc2UgZGV0
YWlscyBhcmUgdXNlZCB0bwogZGV0ZXJtaW5lIHByb3NzaWJsZSBjYXVzZXMgb2YgbGF0ZW5j
eSBmb3IgdGhlIGRldGVjdGlvbi4KIFRoaXMgZmllbGQgaXMgb25seSBzZXQgZm9yIGRldGVj
dGlvbnMgdGhhdCBhcmUgZ2VuZXJhdGVkIGJ5IHJ1bGVzLgoKDQoFBAACEAQSBLMBAgoKDQoF
BAACEAYSBLMBCyEKDQoFBAACEAESBLMBIjoKDQoFBAACEAMSBLMBPT8KswEKBAQAAhESBLgB
AiYapAEgVGhlIGxhdGVuY3kgbWV0cmljcyBmb3IgdGhlIHNwZWNpZmljIGRldGVjdGlvbi4g
VGhlc2UgbWV0cmljcyBhcmUKIGNhbGN1bGF0ZWQgZnJvbSBBTEwgb2YgdGhlIGV2ZW50cyB0
aGF0IGNvbnRyaWJ1dGUgdG8gdGhlIGRldGVjdGlvbiwgbm90CiBqdXN0IHRoZSBzYW1wbGVk
IG9uZXMuCgoNCgUEAAIRBhIEuAECEAoNCgUEAAIRARIEuAERIAoNCgUEAAIRAxIEuAEjJQpO
CgQEAAISEgS7AQInGkAgVGhlIHJ1biBmcmVxdWVuY3kgb2YgdGhlIHJ1bGUgd2hlbiBpdCBn
ZW5lcmF0ZWQgdGhlIGRldGVjdGlvbi4KCg0KBQQAAhIGEgS7AQIOCg0KBQQAAhIBEgS7AQ8h
Cg0KBQQAAhIDEgS7ASQmCqoCCgQEAAITEgTBAQIjGpsCIFRoZSB0b3RhbCBudW1iZXIgb2Yg
c2ltdWxhdGVkIGV2ZW50cyB0aGF0IGNvbnRyaWJ1dGVkIHRvIHRoaXMgZGV0ZWN0aW9uLgog
U2ltdWxhdGVkIGV2ZW50cyBhcmUgcmVhbGlzdGljIHRocmVhdCBzZXF1ZW5jZXMgKFJhdyBM
b2dzIG9yIFVETSkKIHByb2dyYW1tYXRpY2FsbHkgZGVsaXZlcmVkIGludG8gdGhlIHByb2R1
Y3Rpb24gaW5nZXN0aW9uIHBpcGVsaW5lIHRvIHZlcmlmeQogdGhlIGVudGlyZSBkZXRlY3Rp
b24gbGlmZWN5Y2xl4oCUZnJvbSBpZGVudGlmaWNhdGlvbiB0byBhY3Rpb24uCgoNCgUEAAIT
BRIEwQECBwoNCgUEAAITARIEwQEIHQoNCgUEAAITAxIEwQEgIgqkAQoEBAACFBIExQECLRqV
ASBUaGUgc2V0IG9mIGFsbCB2YWx1ZXMgZnJvbSBldmVudCBpbmdlc3Rpb25fbGFiZWxzIHdo
ZXJlIFNJTVVMQVRFRCBpcyBzZXQgYXMKIHRoZSBrZXksIGZvciBhbGwgc2ltdWxhdGVkIGV2
ZW50cyB0aGF0IHBhcnRpY2lwYXRlZCBpbiB0aGlzIGRldGVjdGlvbi4KCg0KBQQAAhQEEgTF
AQIKCg0KBQQAAhQFEgTFAQsRCg0KBQQAAhQBEgTFARInCg0KBQQAAhQDEgTFASosCm0KAgQB
EgbKAQDgAQEaXyBFbnRpdHlHcmFwaEVucmljaG1lbnQgY29udGFpbnMgdGhlIGRhdGEgdGFi
bGUgbmFtZSBhbmQgdGhlIGVucmljaG1lbnQgYXBwbGllZAogdG8gdGhlIGVudGl0eS4KCgsK
AwQBARIEygEIHQolCgQEAQQAEgbMAQLVAQMaFSBUeXBlIG9mIGVucmljaG1lbnQuCgoNCgUE
AQQAARIEzAEHFQoxCgYEAQQAAgASBM4BBCQaISBFbnJpY2htZW50IHR5cGUgaXMgdW5zcGVj
aWZpZWQuCgoPCgcEAQQAAgABEgTOAQQfCg8KBwQBBAACAAISBM4BIiMKQgoGBAEEAAIBEgTR
AQQPGjIgVGhlIGRhdGEgdGFibGUgd2FzIGFwcGVuZGVkIHRvIHRoZSBlbnRpdHkgZ3JhcGgu
CgoPCgcEAQQAAgEBEgTRAQQKCg8KBwQBBAACAQISBNEBDQ4KRAoGBAEEAAICEgTUAQQRGjQg
VGhlIGVudGl0eSBncmFwaCB3YXMgb3ZlcnJpZGRlbiBieSB0aGUgZGF0YSB0YWJsZS4KCg8K
BwQBBAACAgESBNQBBAwKDwoHBAEEAAICAhIE1AEPEAorCgQEAQIAEgTYAQIYGh0gVGhlIG5h
bWUgb2YgdGhlIGRhdGEgdGFibGUuCgoNCgUEAQIABRIE2AECCAoNCgUEAQIAARIE2AEJEwoN
CgUEAQIAAxIE2AEWFwonCgQEAQIBEgTbAQIlGhkgVGhlIHR5cGUgb2YgZW5yaWNobWVudC4K
Cg0KBQQBAgEGEgTbAQIQCg0KBQQBAgEBEgTbAREgCg0KBQQBAgEDEgTbASMkCn4KBAQBAgIS
BN8BAh8acCBUaGUgZW50aXR5IHdoaWNoIGhhcyBvbmx5IHRoZSBvdmVycmlkZGVuIGZpZWxk
cyBwb3B1bGF0ZWQuIE9ubHkgcG9wdWxhdGVkCiBpZiB0aGUgZW5yaWNobWVudCB0eXBlIGlz
IE9WRVJSSURFLgoKDQoFBAECAgYSBN8BAggKDQoFBAECAgESBN8BCRoKDQoFBAECAgMSBN8B
HR4KcwoCBAISBuQBAO4BARplIERhdGFUYWJsZVJvd0luZm8gY2FwdHVyZXMgaW5mb3JtYXRp
b24gYWJvdXQgYSBkYXRhIHRhYmxlIHJvdyBpbmNsdWRpbmcgdGhlCiBuYW1lIG9mIHRoZSBk
YXRhIHRhYmxlLgoKCwoDBAIBEgTkAQgYCicKBAQCAgASBOYBAhgaGSBUaGUgbmFtZSBvZiBk
YXRhIHRhYmxlLgoKDQoFBAICAAUSBOYBAggKDQoFBAICAAESBOYBCRMKDQoFBAICAAMSBOYB
FhcKfAoEBAICARIE6gECIRpuIFN0b3JlcyB0aGUga2V5IHZhbHVlIHBhaXIgZm9yIGEgZGF0
YSB0YWJsZSByb3cgd2hlcmUgdGhlIGtleSBpcyB0aGUgbmFtZQogb2YgdGhlIGNvbHVtbiBm
b3IgdGhlIGdpdmVuIHZhbHVlLgoKDQoFBAICAQYSBOoBAhgKDQoFBAICAQESBOoBGRwKDQoF
BAICAQMSBOoBHyAKMQoEBAICAhIE7QECFBojIFRoZSByb3cgaWQgb2YgdGhlIGRhdGEgdGFi
bGUgcm93LgoKDQoFBAICAgUSBO0BAggKDQoFBAICAgESBO0BCQ8KDQoFBAICAgMSBO0BEhMK
2QEKAgQDEgbzAQCGAgEaygEgTGF0ZW5jeU1ldHJpY3MgY29udGFpbnMgcmVsZXZhbnQgdGlt
ZXN0YW1wcyBmb3IgbWVhc3VyaW5nIGxhdGVuY3kgcGVyIGV2ZW50CiB2YXJpYWJsZS4gVGhl
c2UgbWV0cmljcyBhcmUgY2FsY3VsYXRlZCBmcm9tIEFMTCBvZiB0aGUgZXZlbnRzIHRoYXQg
Y29udHJpYnV0ZQogdG8gdGhlIGRldGVjdGlvbiwgbm90IGp1c3QgdGhlIHNhbXBsZWQgb25l
cy4KCgsKAwQDARIE8wEIFgpdCgQEAwIAEgT2AQI2Gk8gVGhlIG9sZGVzdCBpbmdlc3Rpb24g
dGltZXN0YW1wIGZyb20gdGhlIGV2ZW50cyB1c2VkIHRvIGNyZWF0ZSB0aGUKIGRldGVjdGlv
bi4KCg0KBQQDAgAGEgT2AQIbCg0KBQQDAgABEgT2ARwxCg0KBQQDAgADEgT2ATQ1CmsKBAQD
AgESBPoBAjYaXSBUaGUgbmV3ZXN0IChtb3N0IHJlY2VudCkgaW5nZXN0aW9uIHRpbWVzdGFt
cCBmcm9tIHRoZSBldmVudHMgdXNlZCB0bwogY3JlYXRlIHRoZSBkZXRlY3Rpb24uCgoNCgUE
AwIBBhIE+gECGwoNCgUEAwIBARIE+gEcMQoNCgUEAwIBAxIE+gE0NQpYCgQEAwICEgT9AQIy
GkogVGhlIG9sZGVzdCBldmVudCB0aW1lc3RhbXAgZnJvbSB0aGUgZXZlbnRzIHVzZWQgdG8g
Y3JlYXRlIHRoZSBkZXRlY3Rpb24uCgoNCgUEAwICBhIE/QECGwoNCgUEAwICARIE/QEcLQoN
CgUEAwICAxIE/QEwMQpnCgQEAwIDEgSBAgIyGlkgVGhlIG5ld2VzdCAobW9zdCByZWNlbnQp
IGV2ZW50IHRpbWVzdGFtcCBmcm9tIHRoZSBldmVudHMgdXNlZCB0byBjcmVhdGUKIHRoZSBk
ZXRlY3Rpb24uCgoNCgUEAwIDBhIEgQICGwoNCgUEAwIDARIEgQIcLQoNCgUEAwIDAxIEgQIw
MQpeCgQEAwIEEgSFAgIxGlAgVGhlIGRpZmZlcmVuY2UgYmV0d2VlbiBuZXdlc3QgaW5nZXN0
aW9uIHRpbWVzdGFtcCBhbmQgbmV3ZXN0IGV2ZW50CiB0aW1lc3RhbXAuCgoNCgUEAwIEBhIE
hQICGgoNCgUEAwIEARIEhQIbLAoNCgUEAwIEAxIEhQIvMArdAQoCBAQSBosCAKgCARrOASBS
ZWZlcmVuY2UgdG8gbW9kZWwgcHJpbWF0aXZlcyBpbmNsdWRpbmcgZXZlbnQgYW5kIGVudGl0
eS4gQXMgc3VwcG9ydCBpcyBhZGRlZAogZm9yIGZhc3QgcmV0cmlldmFsIG9mIG9iamVjdHMg
YnkgaWRlbnRpZmllcnMsIHRoaXMgd2lsbCBiZQogZXhwYW5kZWQgdG8gaW5jbHVkZSBJRCBy
ZWZlcmVuY2VzIHJhdGhlciB0aGFuIGZ1bGwgb2JqZWN0IGNvcGllcy4KCgsKAwQEARIEiwII
EQp9CgQEBAIAEgSQAgIQGm8gT25seSBvbmUgb2YgZXZlbnQgb3IgZW50aXR5IHdpbGwgYmUg
cG9wdWxhdGVkIGZvciBhIHNpbmdsZQogcmVmZXJlbmNlLgogU3RhcnQgb25lLW9mCiBFdmVu
dCBiZWluZyByZWZlcmVuY2VkLgoKDQoFBAQCAAYSBJACAgUKDQoFBAQCAAESBJACBgsKDQoF
BAQCAAMSBJACDg8KnAEKBAQEAgESBJUCAhQajQEgRW50aXR5IGJlaW5nIHJlZmVyZW5jZWQu
IEluIGNhc2VzIHdoZXJlIHRoZSBlbnRpdHkgZ3JhcGggaXMgb3ZlcnJpZGRlbiBieQogZGF0
YSB0YWJsZSwgdGhpcyB3aWxsIHJlcHJlc2VudCB0aGUgb3JpZ2luYWwgZW50aXR5LgogRW5k
IG9uZS1vZgoKDQoFBAQCAQYSBJUCAggKDQoFBAQCAQESBJUCCQ8KDQoFBAQCAQMSBJUCEhMK
OgoEBAQCAhIEmAICNxosIFRoZSBkYXRhIHRhYmxlIHJvd3Mgam9pbmVkIHdpdGggdGhlIGV2
ZW50LgoKDQoFBAQCAgQSBJgCAgoKDQoFBAQCAgYSBJgCCxsKDQoFBAQCAgESBJgCHDIKDQoF
BAQCAgMSBJgCNTYKqQEKBAQEAgMSBJ0CAi0amgEgVGhlIGVudGl0eSBncmFwaCBlbnJpY2ht
ZW50IGRldGFpbHMuIE9ubHkgc2V0IHdoZW4gdGhlIHJlZmVyZW5jZSBpcyBhbgogRW50aXR5
IHdoaWNoIGhhcyBiZWVuIG92ZXJyaWRkZW4gYnkgYSBkYXRhIHRhYmxlIG9yIGFwcGVuZGVk
IGZyb20gYSBkYXRhCiB0YWJsZS4KCg0KBQQEAgMGEgSdAgIXCg0KBQQEAgMBEgSdAhgoCg0K
BQQEAgMDEgSdAissCqkBCgQEBAIEEgSiAgIMGpoBIElkIGJlaW5nIHJlZmVyZW5jZWQuIFRo
aXMgZmllbGQgd2lsbCBhbHNvIGJlIHBvcHVsYXRlZCBmb3IgYm90aCBldmVudCBhbmQKIGVu
dGl0eSB3aXRoIHRoZSBldmVudCBpZC4gRm9yIGRldGVjdGlvbnMsIG9ubHkgdGhpcyBmaWVs
ZCB3aWxsIGJlCiBwb3B1bGF0ZWQuCgoNCgUEBAIEBhIEogICBAoNCgUEBAIEARIEogIFBwoN
CgUEBAIEAxIEogIKCwrRAQoEBAQCBRIEpwICHRrCASBUaGUgbG9nIGJhdGNoIHRva2VuIG9m
IHRoZSBldmVudCBiZWluZyByZWZlcmVuY2VkLiBUaGlzIGZpZWxkIGlzCiB1c2VkIHRvIGZl
dGNoIHRoZSByYXcgbG9nIGFzc29jaWF0ZWQgd2l0aCB0aGUgZXZlbnQgaW4gc29tZSBsZWdh
Y3kgc3lzdGVtcy4KIFRoaXMgZmllbGQgaXMgb25seSBwb3B1bGF0ZWQgZm9yIGV2ZW50cy9l
bnRpdGllcy4KCg0KBQQEAgUFEgSnAgIICg0KBQQEAgUBEgSnAgkYCg0KBQQEAgUDEgSnAhsc
CgwKAgQFEgaqAgDIAgEKCwoDBAUBEgSqAggPCoADCgQEBQIAEgSxAgIhGvECIE1ldGFkYXRh
IHRoYXQgcHJvdmlkZXMgdGhlIHJlbGV2YW50IGFzc29jaWF0aW9uIGZvciB0aGUgcmVmZXJl
bmNlcyBpbiB0aGUKIGVsZW1lbnQuIEZvciBhIGRldGVjdGlvbiwgdGhpcyBjYW4gYmUgdGhl
IGNvcnJlbGF0ZWQgYXNwZWN0IG9mIHRoZQogcmVmZXJlbmNlcyB0aGF0IGNvbnRyaWJ1dGVk
IHRvIHRoZSBvdmVyYWxsIGRldGVjdGlvbi4gRm9yIGV4YW1wbGUsIG1heQogaW5jbHVkZSBz
dWItcnVsZSBjb25kaXRpb24sIG1hY2hpbmUgbGVhcm5pbmcgbW9kZWwgbWV0YWRhdGEsIGFu
ZC9vcgogaW5kaWNhdG9ycyBpbXBsaWNhdGVkIGluIHRoaXMgY29tcG9uZW50IG9mIHRoZSBk
ZXRlY3Rpb24KICh1c2luZyB0aGUgLmFib3V0IGZpZWxkKS4KCg0KBQQFAgAGEgSxAgIQCg0K
BQQFAgABEgSxAhEcCg0KBQQFAgADEgSxAh8gCpkCCgQEBQIBEgS4AgIkGooCIFJlZmVyZW5j
ZXMgdG8gbW9kZWwgcHJpbWF0aXZlcyBpbmNsdWRpbmcgZXZlbnRzIGFuZCBlbnRpdGllcyB0
aGF0IHNoYXJlIGEKIGNvbW1vbiBhc3NvY2lhdGlvbi4KIEV2ZW4gdGhvdWdoIGEgcmVmZXJl
bmNlIGNhbiBoYXZlIGJvdGggVURNIGFuZCBlbnRpdHksIGEgY29sbGVjdGlvbiBvZgogcmVm
ZXJlbmNlcyAob2YgYSBzaW5nbGUgZWxlbWVudCkgd2lsbCBvbmx5IGhhdmUgb25lIHR5cGUg
b2YgbWVzc2FnZSBpbiBpdAogKGVpdGhlciBVRE0gLyBFbnRpdHkpLgoKDQoFBAUCAQQSBLgC
AgoKDQoFBAUCAQYSBLgCCxQKDQoFBAUCAQESBLgCFR8KDQoFBAUCAQMSBLgCIiMKPwoEBAUC
AhIEuwICExoxIEEgbmFtZSB0aGF0IGxhYmVscyB0aGUgZW50aXJlIHJlZmVyZW5jZXMgZ3Jv
dXAuCgoNCgUEBQICBRIEuwICCAoNCgUEBQICARIEuwIJDgoNCgUEBQICAxIEuwIREgr1AQoE
BAUCAxIEwQICHhrmASBDb3BpZWQgZnJvbSB0aGUgZGV0ZWN0aW9uIGV2ZW50X3NhbXBsZS50
b29fbWFueV9ldmVudF9zYW1wbGVzIGZpZWxkLgogSWYgdHJ1ZSwgdGhlIG51bWJlciBvZiBy
ZWZlcmVuY2VzIHdpbGwgYmUgY2FwcGVkIGF0IHRoZSBzYW1wbGUgbGltaXQKIChzZXQgYXQg
cnVsZSBzZXJ2aWNlKS4KIFRoaXMgaXMgYXBwbGljYWJsZSB0byBib3RoIFVETSByZWZlcmVu
Y2VzIGFuZCBFbnRpdHkgcmVmZXJlbmNlcy4KCg0KBQQFAgMFEgTBAgIGCg0KBQQFAgMBEgTB
AgcZCg0KBQQFAgMDEgTBAhwdCv8BCgQEBQIEEgTHAgIlGvABIExhdGVuY3kgbWV0cmljcyBm
b3IgdGhlIHNwZWNpZmljIGVsZW1lbnQuIFRoZXNlIGFyZQogY2FsY3VsYXRlZCBmcm9tIGFs
bCB0aGUgY29udHJpYnV0aW5nIGV2ZW50cyBvciBlbnRpdGllcyBmb3IgYSBzaW5nbGUgZXZl
bnQKIHZhcmlhYmxlLCBub3QganVzdCB0aGUgc2FtcGxlZCBvbmVzIGluY2x1ZGVkIGluIHJl
ZmVyZW5jZXMuIFRoaXMgaXMKIGN1cnJlbnRseSBvbmx5IHBvcHVsYXRlZCBmb3IgVURNIGV2
ZW50cy4KCg0KBQQFAgQGEgTHAgIQCg0KBQQFAgQBEgTHAhEgCg0KBQQFAgQDEgTHAiMkCkUK
AgQGEgbLAgDaAgEaNyBSZWxhdGVkIGluZm8gb2YgYW4gQWxlcnQgaW4gY3VzdG9tZXIncyBT
T0FSIHBsYXRmb3JtLgoKCwoDBAYBEgTLAggcCi8KBAQGBAASBs0CAtMCAxofIEF2YWlsYWJs
ZSByZXNwb25zZSBwbGF0Zm9ybXMuCgoNCgUEBgQAARIEzQIHGwoyCgYEBgQAAgASBM8CBCsa
IiBSZXNwb25zZSBwbGF0Zm9ybSBub3Qgc3BlY2lmaWVkLgoKDwoHBAYEAAIAARIEzwIEJgoP
CgcEBgQAAgACEgTPAikqChsKBgQGBAACARIE0gIEKRoLIFNpZW1wbGlmeQoKDwoHBAYEAAIB
ARIE0gIEJAoPCgcEBgQAAgECEgTSAicoCjAKBAQGAgASBNYCAhYaIiBJZCBvZiB0aGUgYWxl
cnQgaW4gU09BUiBwcm9kdWN0LgoKDQoFBAYCAAUSBNYCAggKDQoFBAYCAAESBNYCCREKDQoF
BAYCAAMSBNYCFBUKJQoEBAYCARIE2QICMhoXIFR5cGUgb2YgU09BUiBwcm9kdWN0LgoKDQoF
BAYCAQYSBNkCAhYKDQoFBAYCAQESBNkCFy0KDQoFBAYCAQMSBNkCMDEKSQoCBAcSBt0CAPIC
ARo7IE1ldGFkYXRhIGZpZWxkcyBvZiBhbGVydHMgY29taW5nIGZyb20gb3RoZXIgU0lFTSBz
eXN0ZW1zLgoKCwoDBAcBEgTdAggZCjMKBAQHAgASBN8CAhYaJSBBbGVydCBJRCBpbiB0aGUg
c291cmNlIFNJRU0gc3lzdGVtLgoKDQoFBAcCAAUSBN8CAggKDQoFBAcCAAESBN8CCREKDQoF
BAcCAAMSBN8CFBUKSQoEBAcCARIE4gICGRo7IE5hbWUgb2YgdGhlIHJ1bGUgdHJpZ2dlcmlu
ZyB0aGUgYWxlcnQgaW4gdGhlIHNvdXJjZSBTSUVNLgoKDQoFBAcCAQUSBOICAggKDQoFBAcC
AQESBOICCRQKDQoFBAcCAQMSBOICFxgKIwoEBAcCAhIE5QICFBoVIE5hbWUgb2YgdGhlIHZl
bmRvci4KCg0KBQQHAgIFEgTlAgIICg0KBQQHAgIBEgTlAgkPCg0KBQQHAgIDEgTlAhITCi8K
BAQHAgMSBOgCAhsaISBOYW1lIG9mIHRoZSBTb3VyY2UgU0lFTSBzeXN0ZW0uCgoNCgUEBwID
BRIE6AICCAoNCgUEBwIDARIE6AIJFgoNCgUEBwIDAxIE6AIZGgo9CgQEBwIEEgTrAgIVGi8g
TmFtZSBvZiB0aGUgcHJvZHVjdCB0aGUgYWxlcnQgaXMgY29taW5nIGZyb20uCgoNCgUEBwIE
BRIE6wICCAoNCgUEBwIEARIE6wIJEAoNCgUEBwIEAxIE6wITFAo9CgQEBwIFEgTuAgIlGi8g
VGlja2V0IGlkIGZvciB0aGUgYWxlcnQgaW4gdGhlIHNvdXJjZSBzeXN0ZW0uCgoNCgUEBwIF
BRIE7gICCAoNCgUEBwIFARIE7gIJIAoNCgUEBwIFAxIE7gIjJAouCgQEBwIGEgTxAgIfGiAg
VXJsIHRvIHRoZSBzb3VyY2UgU0lFTSBzeXN0ZW0uCgoNCgUEBwIGBRIE8QICCAoNCgUEBwIG
ARIE8QIJGgoNCgUEBwIGAxIE8QIdHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Backstory::Collection::Collection ===
    # Fields for Collection
    # Field: id Type: 9 ()
    # Field: type Type: 14 (.google.backstory.Collection.CollectionType)
    # Field: id_namespace Type: 14 (.google.backstory.Id.Namespace)
    # Field: created_time Type: 11 (.google.protobuf.Timestamp)
    # Field: last_updated_time Type: 11 (.google.protobuf.Timestamp)
    # Field: time_window Type: 11 (.google.type.Interval)
    # Field: collection_elements Type: 11 (.google.backstory.Element)
    # Field: detection Type: 11 (.google.backstory.SecurityResult)
    # Field: detection_time Type: 11 (.google.protobuf.Timestamp)
    # Field: investigation Type: 11 (.google.backstory.Investigation)
    # Field: tags Type: 9 ()
    # Field: response_platform_info Type: 11 (.google.backstory.ResponsePlatformInfo)
    # Field: case_name Type: 9 ()
    # Field: soar_alert Type: 8 ()
    # Field: soar_alert_metadata Type: 11 (.google.backstory.SoarAlertMetadata)
    # Field: data_access_scope Type: 9 ()
    # Field: detection_timing_details Type: 14 (.google.backstory.Collection.DetectionTimingDetails)
    # Field: latency_metrics Type: 11 (.google.backstory.LatencyMetrics)
    # Field: rule_run_frequency Type: 14 (.google.backstory.Collection.RunFrequency)
    # Field: simulated_event_count Type: 3 ()
    # Field: simulated_event_names Type: 9 ()

# Enum: Collection::CollectionType
our $Collection_COLLECTION_TYPE_UNSPECIFIED = 0;
our $Collection_TELEMETRY_ALERT = 1;
our $Collection_GCTI_FINDING = 2;
our $Collection_UPPERCASE_ALERT = 2;
our $Collection_RULE_DETECTION = 3;
our $Collection_MACHINE_INTELLIGENCE_ALERT = 4;
our $Collection_SOAR_ALERT = 5;

# Enum: Collection::DetectionTimingDetails
our $Collection_DETECTION_TIMING_DETAILS_UNSPECIFIED = 0;
our $Collection_DETECTION_TIMING_DETAILS_REPROCESSING = 1;
our $Collection_DETECTION_TIMING_DETAILS_RETROHUNT = 2;

# Enum: Collection::RunFrequency
our $Collection_RUN_FREQUENCY_UNSPECIFIED = 0;
our $Collection_RUN_FREQUENCY_REALTIME = 1;
our $Collection_RUN_FREQUENCY_HOURLY = 2;
our $Collection_RUN_FREQUENCY_DAILY = 3;

# === Message: Google::Backstory::Collection::EntityGraphEnrichment ===
    # Fields for EntityGraphEnrichment
    # Field: data_table Type: 9 ()
    # Field: enrichment_type Type: 14 (.google.backstory.EntityGraphEnrichment.EnrichmentType)
    # Field: overridden_entity Type: 11 (.google.backstory.Entity)

# Enum: EntityGraphEnrichment::EnrichmentType
our $EntityGraphEnrichment_ENRICHMENT_TYPE_UNSPECIFIED = 0;
our $EntityGraphEnrichment_APPEND = 1;
our $EntityGraphEnrichment_OVERRIDE = 2;

# === Message: Google::Backstory::Collection::DataTableRowInfo ===
    # Fields for DataTableRowInfo
    # Field: data_table Type: 9 ()
    # Field: row Type: 11 (.google.protobuf.Struct)
    # Field: row_id Type: 9 ()

# === Message: Google::Backstory::Collection::LatencyMetrics ===
    # Fields for LatencyMetrics
    # Field: oldest_ingestion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: newest_ingestion_time Type: 11 (.google.protobuf.Timestamp)
    # Field: oldest_event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: newest_event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: ingestion_latency Type: 11 (.google.protobuf.Duration)

# === Message: Google::Backstory::Collection::Reference ===
    # Fields for Reference
    # Field: event Type: 11 (.google.backstory.UDM)
    # Field: entity Type: 11 (.google.backstory.Entity)
    # Field: joined_data_table_rows Type: 11 (.google.backstory.DataTableRowInfo)
    # Field: graph_enrichment Type: 11 (.google.backstory.EntityGraphEnrichment)
    # Field: id Type: 11 (.google.backstory.Id)
    # Field: log_batch_token Type: 9 ()

# === Message: Google::Backstory::Collection::Element ===
    # Fields for Element
    # Field: association Type: 11 (.google.backstory.SecurityResult)
    # Field: references Type: 11 (.google.backstory.Reference)
    # Field: label Type: 9 ()
    # Field: references_sampled Type: 8 ()
    # Field: latency_metrics Type: 11 (.google.backstory.LatencyMetrics)

# === Message: Google::Backstory::Collection::ResponsePlatformInfo ===
    # Fields for ResponsePlatformInfo
    # Field: alert_id Type: 9 ()
    # Field: response_platform_type Type: 14 (.google.backstory.ResponsePlatformInfo.ResponsePlatformType)

# Enum: ResponsePlatformInfo::ResponsePlatformType
our $ResponsePlatformInfo_RESPONSE_PLATFORM_TYPE_UNSPECIFIED = 0;
our $ResponsePlatformInfo_RESPONSE_PLATFORM_TYPE_SIEMPLIFY = 1;

# === Message: Google::Backstory::Collection::SoarAlertMetadata ===
    # Fields for SoarAlertMetadata
    # Field: alert_id Type: 9 ()
    # Field: source_rule Type: 9 ()
    # Field: vendor Type: 9 ()
    # Field: source_system Type: 9 ()
    # Field: product Type: 9 ()
    # Field: source_system_ticket_id Type: 9 ()
    # Field: source_system_uri Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Backstory::Collection - Compiled Protocol Buffers messages for backstory/collection.proto

=head1 SYNOPSIS

    use Google::Backstory::Collection;

    my $msg = Google::Backstory::Collection::Collection->new({
        id => $id,
        type => $type,
        id_namespace => $id_namespace,
        created_time => $created_time,
    });

    # Read or update a field
    my $val = $msg->id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Backstory::Collection::Collection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<backstory/collection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Backstory::Collection::Collection

Collection represents a container of objects (such as events, entity
context metadata, detection finding metadata) and state (such as
investigation details).

An example use case for Collection is to model a detection and investigation
from detection finding metadata to investigative state collected in the
course of the investigation. For more complex investigation and response
workflows a Collection could represent an incident consisting of multiple
child findings or incidents. This can be expanded on to model remediation
elements of a full detection and response workflow.


Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique ID for the collection.
The ID is specific to the type of collection. For example, with rule
detections this is the detection ID.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Backstory::Collection::CollectionType>)

What the collection represents.

=item * C<< $msg->id_namespace() >> / C<< $msg->id_namespace($value) >>

Type: C<Enum> (L<Google::Backstory::Id::Namespace>)

The ID namespace used for the Collection.

=item * C<< $msg->created_time() >> / C<< $msg->created_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the collection was created.

=item * C<< $msg->last_updated_time() >> / C<< $msg->last_updated_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the collection was last updated.

=item * C<< $msg->time_window() >> / C<< $msg->time_window($value) >>

Type: C<Message> (L<Google::Type::Interval::Interval>)

Time interval that the collection represents.

=item * C<< $msg->collection_elements() >> / C<< $msg->collection_elements($value) >>

Type: C<Message> (L<Google::Backstory::Collection::Element>)

Constituent elements of the collection. Each element shares an association
that groups it together and is a component of the overall collection. For
example, a detection collection may have several constituent elements that
each share a correlation association that together represent a particular
pattern or behavior.

=item * C<< $msg->detection() >> / C<< $msg->detection($value) >>

Type: C<Message> (L<Google::Backstory::Udm::SecurityResult>)

Detection metadata for findings that represent detections, can include
rule details, machine learning model metadata, and indicators implicated
in the detection (using the .about field).

=item * C<< $msg->detection_time() >> / C<< $msg->detection_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Timestamp within the time_window related to the time of the
collection_elements. For Rule Detections, this timestamp is the end of the
the time_window for multi-event rules or the time of the event for single
event rules. For late-arriving events that trigger new alerts, the
detection_time will be the event time of the event.

=item * C<< $msg->investigation() >> / C<< $msg->investigation($value) >>

Type: C<Message> (L<Google::Backstory::Udm::Investigation>)

Consolidated investigation details (categorization, status, etc) typically
for collections that begin as detection findings and then evolve with
analyst action and feedback into investigations around the detection
output.

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<String>

Tags set by UC/DSML/RE for the Finding during creation.

=item * C<< $msg->response_platform_info() >> / C<< $msg->response_platform_info($value) >>

Type: C<Message> (L<Google::Backstory::Collection::ResponsePlatformInfo>)

Alert related info of this same alert in customer's SOAR platform.

=item * C<< $msg->case_name() >> / C<< $msg->case_name($value) >>

Type: C<String>

The resource name of the Case that this collection belongs to.
Example:
projects/{project id}/locations/{region}/chronicle/cases/{internal_case_id}

=item * C<< $msg->soar_alert() >> / C<< $msg->soar_alert($value) >>

Type: C<Bool>

A boolean field indicating that the alert is present in SOAR.

=item * C<< $msg->soar_alert_metadata() >> / C<< $msg->soar_alert_metadata($value) >>

Type: C<Message> (L<Google::Backstory::Collection::SoarAlertMetadata>)

Metadata fields of alerts coming from other SIEM systems via SOAR.

=item * C<< $msg->data_access_scope() >> / C<< $msg->data_access_scope($value) >>

Type: C<String>

The resource name of the DataAccessScope of this collection.

=item * C<< $msg->detection_timing_details() >> / C<< $msg->detection_timing_details($value) >>

Type: C<Enum> (L<Google::Backstory::Collection::DetectionTimingDetails>)

Detection timing details for the collection. These details are used to
determine prossible causes of latency for the detection.
This field is only set for detections that are generated by rules.

=item * C<< $msg->latency_metrics() >> / C<< $msg->latency_metrics($value) >>

Type: C<Message> (L<Google::Backstory::Collection::LatencyMetrics>)

The latency metrics for the specific detection. These metrics are
calculated from ALL of the events that contribute to the detection, not
just the sampled ones.

=item * C<< $msg->rule_run_frequency() >> / C<< $msg->rule_run_frequency($value) >>

Type: C<Enum> (L<Google::Backstory::Collection::RunFrequency>)

The run frequency of the rule when it generated the detection.

=item * C<< $msg->simulated_event_count() >> / C<< $msg->simulated_event_count($value) >>

Type: C<Int64>

The total number of simulated events that contributed to this detection.
Simulated events are realistic threat sequences (Raw Logs or UDM)
programmatically delivered into the production ingestion pipeline to verify
the entire detection lifecycle—from identification to action.

=item * C<< $msg->simulated_event_names() >> / C<< $msg->simulated_event_names($value) >>

Type: C<String>

The set of all values from event ingestion_labels where SIMULATED is set as
the key, for all simulated events that participated in this detection.

=back

=head3 Enum: Collection::CollectionType

=over 4

=item * C<COLLECTION_TYPE_UNSPECIFIED> => C<0>

=item * C<TELEMETRY_ALERT> => C<1>

=item * C<GCTI_FINDING> => C<2>

=item * C<UPPERCASE_ALERT> => C<2>

=item * C<RULE_DETECTION> => C<3>

=item * C<MACHINE_INTELLIGENCE_ALERT> => C<4>

=item * C<SOAR_ALERT> => C<5>

=back

=head3 Enum: Collection::DetectionTimingDetails

=over 4

=item * C<DETECTION_TIMING_DETAILS_UNSPECIFIED> => C<0>

=item * C<DETECTION_TIMING_DETAILS_REPROCESSING> => C<1>

=item * C<DETECTION_TIMING_DETAILS_RETROHUNT> => C<2>

=back

=head3 Enum: Collection::RunFrequency

=over 4

=item * C<RUN_FREQUENCY_UNSPECIFIED> => C<0>

=item * C<RUN_FREQUENCY_REALTIME> => C<1>

=item * C<RUN_FREQUENCY_HOURLY> => C<2>

=item * C<RUN_FREQUENCY_DAILY> => C<3>

=back

=head2 Google::Backstory::Collection::EntityGraphEnrichment

EntityGraphEnrichment contains the data table name and the enrichment applied
to the entity.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_table() >> / C<< $msg->data_table($value) >>

Type: C<String>

The name of the data table.

=item * C<< $msg->enrichment_type() >> / C<< $msg->enrichment_type($value) >>

Type: C<Enum> (L<Google::Backstory::EntityGraphEnrichment::EnrichmentType>)

The type of enrichment.

=item * C<< $msg->overridden_entity() >> / C<< $msg->overridden_entity($value) >>

Type: C<Message> (L<Google::Backstory::Entity::Entity>)

The entity which has only the overridden fields populated. Only populated
if the enrichment type is OVERRIDE.

=back

=head3 Enum: EntityGraphEnrichment::EnrichmentType

=over 4

=item * C<ENRICHMENT_TYPE_UNSPECIFIED> => C<0>

=item * C<APPEND> => C<1>

=item * C<OVERRIDE> => C<2>

=back

=head2 Google::Backstory::Collection::DataTableRowInfo

DataTableRowInfo captures information about a data table row including the
name of the data table.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_table() >> / C<< $msg->data_table($value) >>

Type: C<String>

The name of data table.

=item * C<< $msg->row() >> / C<< $msg->row($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Stores the key value pair for a data table row where the key is the name
of the column for the given value.

=item * C<< $msg->row_id() >> / C<< $msg->row_id($value) >>

Type: C<String>

The row id of the data table row.

=back

=head2 Google::Backstory::Collection::LatencyMetrics

LatencyMetrics contains relevant timestamps for measuring latency per event
variable. These metrics are calculated from ALL of the events that contribute
to the detection, not just the sampled ones.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->oldest_ingestion_time() >> / C<< $msg->oldest_ingestion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The oldest ingestion timestamp from the events used to create the
detection.

=item * C<< $msg->newest_ingestion_time() >> / C<< $msg->newest_ingestion_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The newest (most recent) ingestion timestamp from the events used to
create the detection.

=item * C<< $msg->oldest_event_time() >> / C<< $msg->oldest_event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The oldest event timestamp from the events used to create the detection.

=item * C<< $msg->newest_event_time() >> / C<< $msg->newest_event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The newest (most recent) event timestamp from the events used to create
the detection.

=item * C<< $msg->ingestion_latency() >> / C<< $msg->ingestion_latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The difference between newest ingestion timestamp and newest event
timestamp.

=back

=head2 Google::Backstory::Collection::Reference

Reference to model primatives including event and entity. As support is added
for fast retrieval of objects by identifiers, this will be
expanded to include ID references rather than full object copies.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event() >> / C<< $msg->event($value) >>

Type: C<Message> (L<Google::Backstory::Udm::UDM>)

Only one of event or entity will be populated for a single
reference.
Start one-of
Event being referenced.

=item * C<< $msg->entity() >> / C<< $msg->entity($value) >>

Type: C<Message> (L<Google::Backstory::Entity::Entity>)

Entity being referenced. In cases where the entity graph is overridden by
data table, this will represent the original entity.
End one-of

=item * C<< $msg->joined_data_table_rows() >> / C<< $msg->joined_data_table_rows($value) >>

Type: C<Message> (L<Google::Backstory::Collection::DataTableRowInfo>)

The data table rows joined with the event.

=item * C<< $msg->graph_enrichment() >> / C<< $msg->graph_enrichment($value) >>

Type: C<Message> (L<Google::Backstory::Collection::EntityGraphEnrichment>)

The entity graph enrichment details. Only set when the reference is an
Entity which has been overridden by a data table or appended from a data
table.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<Message> (L<Google::Backstory::Id::Id>)

Id being referenced. This field will also be populated for both event and
entity with the event id. For detections, only this field will be
populated.

=item * C<< $msg->log_batch_token() >> / C<< $msg->log_batch_token($value) >>

Type: C<String>

The log batch token of the event being referenced. This field is
used to fetch the raw log associated with the event in some legacy systems.
This field is only populated for events/entities.

=back

=head2 Google::Backstory::Collection::Element

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->association() >> / C<< $msg->association($value) >>

Type: C<Message> (L<Google::Backstory::Udm::SecurityResult>)

Metadata that provides the relevant association for the references in the
element. For a detection, this can be the correlated aspect of the
references that contributed to the overall detection. For example, may
include sub-rule condition, machine learning model metadata, and/or
indicators implicated in this component of the detection
(using the .about field).

=item * C<< $msg->references() >> / C<< $msg->references($value) >>

Type: C<Message> (L<Google::Backstory::Collection::Reference>)

References to model primatives including events and entities that share a
common association.
Even though a reference can have both UDM and entity, a collection of
references (of a single element) will only have one type of message in it
(either UDM / Entity).

=item * C<< $msg->label() >> / C<< $msg->label($value) >>

Type: C<String>

A name that labels the entire references group.

=item * C<< $msg->references_sampled() >> / C<< $msg->references_sampled($value) >>

Type: C<Bool>

Copied from the detection event_sample.too_many_event_samples field.
If true, the number of references will be capped at the sample limit
(set at rule service).
This is applicable to both UDM references and Entity references.

=item * C<< $msg->latency_metrics() >> / C<< $msg->latency_metrics($value) >>

Type: C<Message> (L<Google::Backstory::Collection::LatencyMetrics>)

Latency metrics for the specific element. These are
calculated from all the contributing events or entities for a single event
variable, not just the sampled ones included in references. This is
currently only populated for UDM events.

=back

=head2 Google::Backstory::Collection::ResponsePlatformInfo

Related info of an Alert in customer's SOAR platform.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alert_id() >> / C<< $msg->alert_id($value) >>

Type: C<String>

Id of the alert in SOAR product.

=item * C<< $msg->response_platform_type() >> / C<< $msg->response_platform_type($value) >>

Type: C<Enum> (L<Google::Backstory::ResponsePlatformInfo::ResponsePlatformType>)

Type of SOAR product.

=back

=head3 Enum: ResponsePlatformInfo::ResponsePlatformType

=over 4

=item * C<RESPONSE_PLATFORM_TYPE_UNSPECIFIED> => C<0>

=item * C<RESPONSE_PLATFORM_TYPE_SIEMPLIFY> => C<1>

=back

=head2 Google::Backstory::Collection::SoarAlertMetadata

Metadata fields of alerts coming from other SIEM systems.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->alert_id() >> / C<< $msg->alert_id($value) >>

Type: C<String>

Alert ID in the source SIEM system.

=item * C<< $msg->source_rule() >> / C<< $msg->source_rule($value) >>

Type: C<String>

Name of the rule triggering the alert in the source SIEM.

=item * C<< $msg->vendor() >> / C<< $msg->vendor($value) >>

Type: C<String>

Name of the vendor.

=item * C<< $msg->source_system() >> / C<< $msg->source_system($value) >>

Type: C<String>

Name of the Source SIEM system.

=item * C<< $msg->product() >> / C<< $msg->product($value) >>

Type: C<String>

Name of the product the alert is coming from.

=item * C<< $msg->source_system_ticket_id() >> / C<< $msg->source_system_ticket_id($value) >>

Type: C<String>

Ticket id for the alert in the source system.

=item * C<< $msg->source_system_uri() >> / C<< $msg->source_system_uri($value) >>

Type: C<String>

Url to the source SIEM system.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Backstory::Collection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
