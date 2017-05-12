# $Id: minimum_version.t 52 2007-11-04 16:55:12Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/trunk/t/minimum_version.t $
# $Revision: 52 $
# $Date: 2007-11-04 17:55:12 +0100 (Sun, 04 Nov 2007) $
use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{CLASS_DOT_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{CLASS_DOT_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::MinimumVersion'; ## no critic

if ( $EVAL_ERROR ) {
    my $msg = 'Test::MinimumVersion required';
    plan( skip_all => $msg );
}


Test__MinimumVersion->import;
all_minimum_version_ok('5.00600');


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
