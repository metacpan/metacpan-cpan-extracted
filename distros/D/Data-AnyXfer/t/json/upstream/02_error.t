#BEGIN { $| = 1; print "1..31\n"; }
use Test::More tests => 32;

use utf8;
use Data::AnyXfer::JSON;
no warnings;

#our $test;
#sub ok($) {
#   print $_[0] ? "" : "not ", "ok ", ++$test, "\n";
#}

eval { Data::AnyXfer::JSON->new->encode ([\-1]) }; ok $@ =~ /cannot encode reference/;
eval { Data::AnyXfer::JSON->new->encode ([\undef]) }; ok $@ =~ /cannot encode reference/;
eval { Data::AnyXfer::JSON->new->encode ([\2]) }; ok $@ =~ /cannot encode reference/;
eval { Data::AnyXfer::JSON->new->encode ([\{}]) }; ok $@ =~ /cannot encode reference/;
eval { Data::AnyXfer::JSON->new->encode ([\[]]) }; ok $@ =~ /cannot encode reference/;
eval { Data::AnyXfer::JSON->new->encode ([\\1]) }; ok $@ =~ /cannot encode reference/;

eval { $x = Data::AnyXfer::JSON->new->ascii->decode ('croak') }; ok $@ =~ /malformed JSON/, $@;

SKIP: {
skip "5.6", 25 if $] < 5.008;

eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('"\u1234\udc00"') }; ok $@ =~ /missing high /;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ('"\ud800"') }; ok $@ =~ /missing low /;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('"\ud800\u1234"') }; ok $@ =~ /surrogate pair /;

eval { Data::AnyXfer::JSON->new->decode ('null') }; ok $@ =~ /allow_nonref/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('+0') }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ('.2') }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('bare') }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ('naughty') }; ok $@ =~ /null/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('01') }; ok $@ =~ /leading zero/;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ('00') }; ok $@ =~ /leading zero/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('-0.') }; ok $@ =~ /decimal point/;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ('-0e') }; ok $@ =~ /exp sign/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ('-e+1') }; ok $@ =~ /initial minus/;
eval { Data::AnyXfer::JSON->new->allow_nonref->decode ("\"\n\"") }; ok $@ =~ /invalid character/;
eval { Data::AnyXfer::JSON->new->allow_nonref (1)->decode ("\"\x01\"") }; ok $@ =~ /invalid character/;
eval { Data::AnyXfer::JSON->new->decode ('[5') }; ok $@ =~ /parsing array/;
eval { Data::AnyXfer::JSON->new->decode ('{"5"') }; ok $@ =~ /':' expected/;
eval { Data::AnyXfer::JSON->new->decode ('{"5":null') }; ok $@ =~ /parsing object/;

eval { Data::AnyXfer::JSON->new->decode (undef) }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->decode (\5) }; ok !!$@; # Can't coerce readonly
eval { Data::AnyXfer::JSON->new->decode ([]) }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->decode (\*STDERR) }; ok $@ =~ /malformed/;
eval { Data::AnyXfer::JSON->new->decode (*STDERR) }; ok !!$@; # cannot coerce GLOB

eval { decode_json ("\"\xa0") }; ok $@ =~ /malformed.*character/;
eval { decode_json ("\"\xa0\"") }; ok $@ =~ /malformed.*character/;

}
