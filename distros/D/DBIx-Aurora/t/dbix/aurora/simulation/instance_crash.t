use strict;
use warnings;
use Test::More skip_all => 'unimplemented';
use DBIx::Aurora;
use t::dbix::aurora::Test::DBIx::Aurora;

subtest 'Instance Crash' => sub {
    subtest instance => sub {
        ok 1;
    };
    subtest dispatcher => sub {
        ok 1;
    };
    subtest node => sub {
        ok 1;
    };

};

done_testing;
