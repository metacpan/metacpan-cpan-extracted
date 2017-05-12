use strict;
use warnings;
use Test::More;
use Data::Recursive::Encode;
use JSON;

my $data = { int => 1 };

is encode_json( Data::Recursive::Encode->encode_utf8($data) ), '{"int":"1"}';

local $Data::Recursive::Encode::DO_NOT_PROCESS_NUMERIC_VALUE = 1;
is encode_json( Data::Recursive::Encode->encode_utf8($data) ), '{"int":1}';

done_testing;
