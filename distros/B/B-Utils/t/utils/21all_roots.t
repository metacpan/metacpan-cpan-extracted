#!perl
use Test::More tests => 4;
use B 'svref_2object';
use B::Utils 'all_roots';

sub find_this { 1 }

{
    # List context
    my %roots = all_roots();

    ok( $roots{'main::find_this'},
        "Found root" );
    is( ${svref_2object( \ &find_this )->ROOT},
        ${$roots{'main::find_this'}},
        "Found correct root" );
}
{
    # Scalar context
    my $roots = all_roots();
    ok( $roots->{'main::find_this'},
        "Found root" );
    is( ${svref_2object( \ &find_this )->ROOT},
        ${$roots->{'main::find_this'}},
        "Found correct root" );
}

