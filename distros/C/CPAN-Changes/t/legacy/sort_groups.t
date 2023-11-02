use strict;
use warnings;

use Test::More;

use CPAN::Changes;

my $changes = CPAN::Changes->load_string(<<'END_CHANGES');
1.05 2011-04-17
    [A]
    - stuff
    [B]
    - mo' stuff
1.04 2011-04-16
    [C]
    - stuff
    [D]
    - mo' stuff
END_CHANGES

like $changes->serialize => expected_order(qw/ A B C D/ );
like $changes->serialize( group_sort => \&reverse_order ) => expected_order(qw/ B A D C/ );

my ($release) = reverse $changes->releases;
like $release->serialize => expected_order(qw/ A B / );
like $release->serialize( group_sort => \&reverse_order ) => expected_order(qw/ B A / );

is_deeply [ $release->groups ], [qw/ A B /];
is_deeply [ $release->groups( sort => \&reverse_order ) ], [qw/ B A /];

sub reverse_order {
    return reverse sort @_;
}

sub expected_order {
    my @groups = @_;
    my $re = join '.*', map { "\\[$_\\]" } @groups;
    return qr/$re/s;
}

done_testing;
