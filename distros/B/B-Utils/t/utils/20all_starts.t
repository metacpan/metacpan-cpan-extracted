#!perl
use Test::More tests => 4;
use B 'svref_2object';
use B::Utils 'all_starts';

sub find_this { 1 }

{
    # List context
    my %starts = all_starts();
    ok( $starts{'main::find_this'},
        "Found start" );
    is( ${svref_2object( \ &find_this )->START},
        ${$starts{'main::find_this'}},
        "Found correct start" );
}
{
    # Scalar context
    my $starts = all_starts();
    ok( $starts->{'main::find_this'},
        "Found start" );
    is( ${svref_2object( \ &find_this )->START},
        ${$starts->{'main::find_this'}},
        "Found correct start" );
}

