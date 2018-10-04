BEGIN { $ENV{DOCSIS_CAN_TRANSLATE_OID} = 0; }
use warnings;
use strict;
use Test::More;
use DOCSIS::ConfigFile qw(encode_docsis decode_docsis);

eval { encode_docsis {DownstreamFrequency => 88000000} };
ok !$@, 'encoded DownstreamFrequency' or diag $@;

done_testing;
