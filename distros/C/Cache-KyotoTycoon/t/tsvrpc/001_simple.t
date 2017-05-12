use strict;
use warnings;
use Test::More;
use TSVRPC::Parser;

subtest 'encode_tsvrpc' => sub {
    is(encode_tsvrpc({foo => 'bar'}), "foo\tbar");
    is(encode_tsvrpc({foo => 'bar'}, 'B'), "Zm9v\tYmFy");
    is(encode_tsvrpc({foo => "\0"}, 'U'), "foo\t%00");
    is(encode_tsvrpc({foo => "\0"}, 'Q'), "foo\t=00");
    done_testing;
};

subtest 'decode_tsvrpc' => sub {
    is_deeply(scalar decode_tsvrpc("foo\tbar"), {foo => 'bar'});
    is_deeply(scalar decode_tsvrpc("Zm9v\tYmFy", 'B'), {foo => 'bar'});
    is_deeply(scalar decode_tsvrpc("foo\t%00", 'U'), {foo => "\0"});
    is_deeply(scalar decode_tsvrpc("foo\t=00", 'Q'), {foo => "\0"});
    done_testing;
};

done_testing;
