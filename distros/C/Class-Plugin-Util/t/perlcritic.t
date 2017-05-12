use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{CLASSPLUGINUTIL_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{CLASSPLUGINUTIL_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
# TODO inc/M/ + inc/Module/Build/M.pm
all_critic_ok('lib/Class/Plugin/', 'lib/Modwheel.pm', 'lib/Modwheel/');

