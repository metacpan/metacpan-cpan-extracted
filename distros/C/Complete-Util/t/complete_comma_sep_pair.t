#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Complete::Util qw(complete_comma_sep_pair);

local $Complete::Common::OPT_WORD_MODE = 0;
local $Complete::Common::OPT_CHAR_MODE = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_FUZZY = 0;
local $Complete::Common::OPT_CI = 0;

subtest "completing keys" => sub {
    test_complete(
        word           => '',
        keys           => [qw(a aa b)],
        result         => [qw(a aa b)],
    );
    test_complete(
        word           => 'a',
        keys           => [qw(a aa b)],
        result         => [qw(a aa)],
    );
    test_complete(
        word           => 'b,v,',
        keys           => [qw(a aa b)],
        result         => ['b,v,a', 'b,v,aa'],
    );
    test_complete(
        word           => 'aa',
        keys           => [qw(a aa b)],
        result         => [{is_partial=>1, word=>'aa,'}],
    );
    test_complete(
        word           => 'a,v,a',
        keys           => [qw(a aa b)],
        result         => [{is_partial=>1, word=>'a,v,aa,'}],
    );
};

subtest "completing values" => sub {
    test_complete(
        word           => 'a,',
        keys           => [qw(a aa b)],
        result         => [],
    );
    test_complete(
        word           => 'a,',
        keys           => [qw(a aa b)],
        complete_value => sub { [qw/v1 v2/] },
        result         => ['a,v1', 'a,v2'],
    );
    test_complete(
        word           => 'a,v,b,',
        keys           => [qw(a aa b)],
        complete_value => sub { [qw/v1 v2/] },
        result         => ['a,v,b,v1', 'a,v,b,v2'],
    );
};

subtest "arg:keys_summaries" => sub {
    test_complete(
        word           => '',
        keys           => [qw(a aa b)],
        keys_summaries => [qw(Sa Saa Sb)],
        result         => [{word=>'a',summary=>"Sa"}, {word=>'aa',summary=>"Saa"}, {word=>'b',summary=>"Sb"}],
    );
};

goto DONE_TESTING;

# XXX arg:remaining_keys
# XXX arg:uniq=0
# XXX opt:ci
# XXX arg:sep

DONE_TESTING:
done_testing;

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_comma_sep_pair(
        word=>$args{word},
        keys=>$args{keys},
        keys_summaries=>$args{keys_summaries},
        uniq=>$args{uniq},
        sep=>$args{sep},
        remaining_keys=>$args{remaining_keys},
        complete_value=>$args{complete_value},
    );
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
