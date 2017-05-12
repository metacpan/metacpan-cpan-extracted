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
    result    => ['aa,'],
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
    result    => ['aa,aa,'],
);
test_complete(
    word      => 'aa,b',
    elems     => [qw(a aa b)],
    result    => ['aa,b,'],
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
        result    => ['aa,a,'],
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

subtest "arg:remaining" => sub {
    my $remaining = sub {
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

    test_complete(
        word => '',
        elems => [qw/a -a b -b/],
        remaining => $remaining,
        result => [qw/-a -b a b/],
    );
    test_complete(
        word => 'a,',
        elems => [qw/a -a b -b/],
        remaining => $remaining,
        result => [qw/a,-b a,b/],
    );
    test_complete(
        word => '-a,',
        elems => [qw/a -a b -b/],
        remaining => $remaining,
        result => [qw/-a,-b -a,b/],
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
    );
    is_deeply($res, $args{result}, "$name (result)")
        or diag explain($res);
}
