use strict;
use warnings;
use Test::More;

use Data::Enumerator qw/
    pattern
    EACH_LAST
    /;
{
    my $where_count = 0;
    my $p           = pattern( 1 .. 100 )->where(
        sub {
            $where_count++;
            return $_[0] < 10;
        }
    );
    my $take_while_count = 0;
    my $q                = pattern( 1 .. 100 )->take_while(
        sub {
            $take_while_count++;
            return $_[0] < 10;
        }
    );

    ::is_deeply( [ $p->list ], [ $q->list ] );
    ::is( $where_count,      100 );
    ::is( $take_while_count, 10 );
}
{
    my $p = pattern(qw/12 25 31 55 47 28 9/)->take_while(sub{$_[0]<50});
    ::is_deeply([$p->list],[12,25,31]);
}
{
    my $where_count = 0;
    my $p           = pattern( 1 .. 20 )->where(
        sub {
            $where_count++;
            return not($_[0] < 10);
        }
    );
    my $skip_while_count = 0;
    my $q                = pattern( 1 .. 20 )->skip_while(
        sub {
            $skip_while_count++;
            return $_[0] < 10;
        }
    );
    ::is_deeply([$p->list],[$q->list]);
    ::is( $where_count,      20 );
    ::is( $skip_while_count, 10 );

}

::done_testing;
