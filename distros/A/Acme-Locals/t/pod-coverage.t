#!perl -T
# $Id: pod-coverage.t 24 2007-10-29 17:15:19Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/trunk/t/pod-coverage.t $
# $Revision: 24 $
# $Date: 2007-10-29 18:15:19 +0100 (Mon, 29 Oct 2007) $

use Test::More;

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{CLASS_DOT_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{CLASS_DOT_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
