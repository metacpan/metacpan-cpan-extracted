#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Complete::Util qw(complete_comma_sep);

local $Complete::Common::OPT_WORD_MODE = 0;
local $Complete::Common::OPT_CHAR_MODE = 0;
local $Complete::Common::OPT_MAP_CASE = 0;
local $Complete::Common::OPT_FUZZY = 0;
local $Complete::Common::OPT_CI = 0;

test_complete(
    word      => '',
    elems     => [qw(a aa b)],
    result    => [qw(a aa b)],
);
test_complete(
    word      => 'a',
    elems     => [qw(a aa b)],
    result    => [qw(a aa)],
);
test_complete(
    word      => 'aa',
    elems     => [qw(a aa b)],
    result    => [{word=>'aa,', is_partial=>1}],
);
test_complete(
    word      => 'aaa',
    elems     => [qw(a aa b)],
    result    => [qw()],
);
test_complete(
    word      => 'aa,',
    elems     => [qw(a aa b)],
    result    => ['aa,a', 'aa,aa', 'aa,b'],
);
test_complete(
    word      => 'aa,,',
    elems     => [qw(a aa b)],
    result    => ['aa,,a', 'aa,,aa', 'aa,,b'],
);
test_complete(
    word      => 'aa,aa',
    elems     => [qw(a aa b)],
    result    => [{word=>'aa,aa,', is_partial=>1}],
);
test_complete(
    word      => 'aa,b',
    elems     => [qw(a aa b)],
    result    => [{word=>'aa,b,', is_partial=>1}],
);
test_complete(
    word      => 'aa,c',
    elems     => [qw(a aa b)],
    result    => [qw()],
);
test_complete(
    word      => 'aa,c,',
    elems     => [qw(a aa b)],
    result    => ['aa,c,a', 'aa,c,aa', 'aa,c,b'],
);

subtest "arg:uniq" => sub {
    test_complete(
        word      => 'aa,',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => ['aa,a', 'aa,b'],
    );
    test_complete(
        word      => 'aa,aa',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => [qw()],
    );
    test_complete(
        word      => 'aa,aa,',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => ['aa,aa,a', 'aa,aa,b'],
    );
    test_complete(
        word      => 'aa,a',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => [{word=>'aa,a,', is_partial=>1}],
    );
    test_complete(
        word      => 'aa,a,b',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => ['aa,a,b'], # no more commas, all elems have been listed
    );
    test_complete(
        word      => 'aa,a,b,',
        elems     => [qw(a aa b)],
        uniq      => 1,
        result    => [qw()],
    );
};

my $remaining1 = sub {
    my ($seen_elems, $elems) = @_;

    my %seen;
    for (@$seen_elems) {
        (my $nodash = $_) =~ s/^-//;
        $seen{$nodash}++;
    }

    my @remaining;
    for (@$elems) {
        (my $nodash = $_) =~ s/^-//;
        push @remaining, $_ unless $seen{$nodash};
    }

    \@remaining;
};

subtest "arg:remaining" => sub {
    test_complete(
        word => '',
        elems => [qw/a -a b -b/],
        remaining => $remaining1,
        result => [qw/-a -b a b/],
    );
    test_complete(
        word => 'a,',
        elems => [qw/a -a b -b/],
        remaining => $remaining1,
        result => ['a,-b', 'a,b'],
    );
    test_complete(
        word => '-a,',
        elems => [qw/a -a b -b/],
        remaining => $remaining1,
        result => ['-a,-b', '-a,b'],
    );
};

subtest "arg:summaries" => sub {
    test_complete(
        word      => 'aa,a,c,',
        elems     => [qw(a aa b)],
        summaries => [qw(Sa Saa Sb)],
        uniq      => 1,
        result    => [{word=>'aa,a,c,b', summary=>'Sb'}],
    );
    test_complete(
        word      => 'aa,c,',
        elems     => [qw(a aa b)],
        summaries => [qw(Sa Saa Sb)],
        result    => [{word=>'aa,c,a', summary=>'Sa'}, {word=>'aa,c,aa', summary=>'Saa'}, {word=>'aa,c,b',summary=>'Sb'}],
    );
    test_complete(
        word => '-a,',
        elems => [qw/a -a b -b/],
        summaries => [qw/Sa S-a Sb S-b/],
        remaining => $remaining1,
        result => [{word=>'-a,-b',summary=>'S-b'}, {word=>'-a,b',summary=>'Sb'}],
    );
};

# XXX arg:exclude
# XXX opt:ci
# XXX opt:map_case
# XXX opt:word_mode
# XXX opt:char_mode
# XXX opt:fuzzy
# XXX arg:replace_map

# XXX arg:sep (not yet implemented)

DONE_TESTING:
done_testing;

sub test_complete {
    my (%args) = @_;

    my $name = $args{name} // $args{word};
    my $res = complete_comma_sep(
        word=>$args{word}, elems=>$args{elems},
        exclude=>$args{exclude},
        replace_map=>$args{replace_map},
        uniq=>$args{uniq},
        sep=>$args{sep},
        remaining=>$args{remaining},
        summaries=>$args{summaries},
    );
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
