#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Complete::Util qw(complete_array_elem);

local $Complete::Common::OPT_WORD_MODE = 0;
local $Complete::Common::OPT_CHAR_MODE = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_FUZZY = 0;
local $Complete::Common::OPT_CI = 0;

test_complete(
    word      => 'a',
    array     => [qw(an apple a day keeps the doctor away)],
    result    => [qw(a an apple away)],
);
test_complete(
    word      => 'an',
    array     => [qw(an apple a day keeps the doctor away)],
    result    => [qw(an)],
);
test_complete(
    word      => 'any',
    array     => [qw(an apple a day keeps the doctor away)],
    result    => [qw()],
);

subtest "arg:exclude" => sub {
    test_complete(
        name      => 'arg:exclude',
        word      => 'a',
        array     => [qw(an apple a day keeps the doctor away)],
        exclude   => [qw(a apple foo)],
        result    => [qw(an away)],
    );
    {
        local $Complete::Common::OPT_MAP_CASE = 1;
        test_complete(
            name      => 'arg:exclude + opt:map_case',
            word      => 'a-',
            array     => [qw(a_b a_bc)],
            exclude   => [qw(a-b)],
            result    => [qw(a_bc)],
        );
    }
};

subtest 'opt:ci' => sub {
    local $Complete::Common::OPT_CI = 1;
    test_complete(
        name      => 'opt:ci',
        word      => 'an',
        array     => [qw(An apple a day keeps the doctor away)],
        result    => [qw(An)],
    );
    test_complete(
        name      => 'opt:ci + arg:exclude',
        word      => 'a',
        array     => [qw(an apple a day keeps the doctor away)],
        exclude   => [qw(A Apple foo)],
        result    => [qw(an away)],
    );
};

subtest "opt:map_case" => sub {
    local $Complete::Common::OPT_MAP_CASE;

    $Complete::Common::OPT_MAP_CASE = 0;
    test_complete(
        name      => 'opt:map_case=0',
        word      => 'a-',
        map_case  => 0,
        array     => [qw(a-1 A-2 a_3 A_4)],
        result    => [qw(a-1)],
    );

    $Complete::Common::OPT_MAP_CASE = 1;
    test_complete(
        name      => 'opt:map_case=1 (1)',
        word      => 'a-',
        map_case  => 1,
        array     => [qw(a-1 A-2 a_3 A_4)],
        result    => [qw(a-1 a_3)],
    );
    test_complete(
        name      => 'opt:map_case=1 (2)',
        word      => 'a_',
        map_case  => 1,
        array     => [qw(a-1 A-2 a_3 A_4)],
        result    => [qw(a-1 a_3)],
    );
};

subtest "opt:word_mode" => sub {
    local $Complete::Common::OPT_WORD_MODE;

    $Complete::Common::OPT_WORD_MODE = 0;
    test_complete(
        name      => 'opt:word_mode=0',
        word      => 'a-b',
        array     => [qw(a-f-B a-f-b a-f-ab a-f-g-b)],
        result    => [qw()],
    );

    $Complete::Common::OPT_WORD_MODE = 1;
    test_complete(
        name      => 'opt:word_mode=1',
        word      => 'a-b',
        array     => [qw(a-f-B a-f-b a-f-ab a-f-g-b)],
        result    => [qw(a-f-b a-f-g-b)],
    );
    test_complete(
        name      => 'opt:word_mode=1 searching non-first word',
        word      => '-b',
        array     => [qw(a-f-B a-f-b a-f-ab a-f-g-b)],
        result    => [qw(a-f-b a-f-g-b)],
    );
};

subtest "opt:char_mode (prefix)" => sub {
    local $Complete::Common::OPT_CHAR_MODE;

    $Complete::Common::OPT_CHAR_MODE = 0;
    test_complete(
        name      => 'opt:char_mode=0',
        word      => 'ab',
        array     => [qw(axb xaxb ba)],
        result    => [qw()],
    );

    $Complete::Common::OPT_CHAR_MODE = 1;
    test_complete(
        name      => 'opt:char_mode=1',
        word      => 'ab',
        array     => [qw(axb xaxb ba)],
        result    => [qw(axb)],
    );
};

subtest "opt:char_mode" => sub {
    local $Complete::Common::OPT_CHAR_MODE;

    $Complete::Common::OPT_CHAR_MODE = 0;
    test_complete(
        name      => 'opt:char_mode=0',
        word      => 'ab',
        array     => [qw(bxb xaxb ba)],
        result    => [qw()],
    );

    $Complete::Common::OPT_CHAR_MODE = 1;
    test_complete(
        name      => 'opt:char_mode=1',
        word      => 'ab',
        array     => [qw(bxb xaxb ba)],
        result    => [qw(xaxb)],
    );
};

subtest "opt:fuzzy" => sub {
    local $Complete::Common::OPT_FUZZY;

    $Complete::Common::OPT_FUZZY = 1;
    test_complete(
        name      => 'opt:fuzzy=1',
        word      => 'apl',
        array     => [qw(apple orange Apricot)],
        result    => [qw(apple)],
    );
};

subtest "arg:replace_map" => sub {
    test_complete(
        name   => 'arg:replace_map (1)',
        word   => "um",
        array  => ["mount", "unmount", "sync-to", "sync-from"],
        replace_map => {unmount => [qw/umount/]},
        result => ["unmount"],
    );
    test_complete(
        name   => 'arg:replace_map (2)',
        word   => "umount",
        array  => ["mount", "unmount", "sync-to", "sync-from"],
        replace_map => {unmount => [qw/umount/]},
        result => ["unmount"],
    );
    {
        local $Complete::Common::OPT_CHAR_MODE = 1;
        test_complete(
            name   => 'arg:replace_map + opt:char_mode=1',
            word   => "to",
            array  => ["mount", "unmount", "sync-to", "sync-from"],
            replace_map => {unmount => [qw/umount/]},
            result => ["sync-to"],
        );
    }
    {
        local $Complete::Common::OPT_CI = 1;
        test_complete(
            name   => 'arg:replace_map + opt:ci=1',
            word   => "uMO",
            array  => ["mount", "unmount"],
            replace_map => {Unmount => [qw/Umount/]},
            result => ["Unmount"],
        );
    }
};

subtest "arg:summaries" => sub {
    test_complete(
        word      => 'a',
        array     => [qw(an apple a day keeps the doctor away)],
        summaries => [qw(S1 S2    S3 S4 S5    S6  S7     S8)],
        result    => [
            {word=>"a"    , summary=>"S3"},
            {word=>"an"   , summary=>"S1"},
            {word=>"apple", summary=>"S2"},
            {word=>"away" , summary=>"S8"},
        ],
    );
};

DONE_TESTING:
done_testing();

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_array_elem(
        word=>$args{word}, array=>$args{array}, exclude=>$args{exclude},
        replace_map=>$args{replace_map},
        summaries=>$args{summaries},
    );
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
