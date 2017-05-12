#!perl -T
# $Id: 00-main.t,v 1.2 2007/09/28 08:29:38 pauldoom Exp $

use Test::More tests => 1;

BEGIN {
    # When PERL_DL_NOLAZY is set to 1, Apache::Request fails to preload a
    # .so.  This turns the flag off long enough to load what we need, then
    # restores it.
    my $nolazy = 0;
    if ($ENV{PERL_DL_NONLAZY}) {
        $ENV{PERL_DL_NONLAZY} = 0;
        $nolazy = 1;
    }
	
    use_ok( 'Apache::AppSamurai' );
    
    ($nolazy) && ($ENV{PERL_DL_NONLAZY} = 1);
}

diag( "Testing Apache::AppSamurai $Apache::AppSamurai::VERSION, Perl $], $^X" );
