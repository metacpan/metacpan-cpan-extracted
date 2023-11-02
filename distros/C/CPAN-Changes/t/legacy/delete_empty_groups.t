use strict;
use warnings;

use Test::More;

use CPAN::Changes;

subtest basic => sub {
    plan tests => 2;

    my $changes = CPAN::Changes->load_string(<<'END_CHANGES');
0.2 2012-02-01
    [D]
    [E]
    - Yadah

0.1 2011-01-01
    [A]
    - Stuff
    [B]
    [C]
    - Blah
END_CHANGES

    $changes->delete_empty_groups;

    is_deeply( [ sort( ($changes->releases)[0]->groups ) ], [ qw/ A C / ] );
    is_deeply( [ sort( ($changes->releases)[1]->groups ) ], [ 'E' ] );
};

subtest mixed => sub {
    plan tests => 1;

    my $changes = CPAN::Changes->load_string(<<'END_CHANGES');
Revision history for {{$dist->name}}

0.2.0
    [BUGS FIXES]
    - A
    - B

0.1.0     2012-03-19
    - C
END_CHANGES

    $changes->delete_empty_groups;

    is_deeply( [ sort( ($changes->releases)[0]->changes ) ], [ {
        '' => [ 'C' ],
    } ] );

};

done_testing;
