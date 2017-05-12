#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Test::More;

use Complete::Util qw(complete_hash_key);

local $Complete::Common::OPT_CI = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_WORD_MODE = 0;
local $Complete::Common::OPT_FUZZY = 0;

test_complete(
    word      => 'a',
    hash      => {a=>1, aa=>1, ab=>1, b=>1, A=>1},
    result    => [qw(a aa ab)],
);
test_complete(
    word      => 'c',
    hash      => {a=>1, aa=>1, ab=>1, b=>1, A=>1},
    result    => [qw()],
);

done_testing();

sub test_complete {
    my (%args) = @_;
    #$log->tracef("args=%s", \%args);

    my $name = $args{name} // $args{word};
    my $res = [sort @{complete_hash_key(
        word=>$args{word}, hash=>$args{hash},
        )}];
    is_deeply($res, $args{result}, "$name (result)") or explain($res);
}
