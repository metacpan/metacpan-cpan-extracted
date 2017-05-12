use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

my $MIN_PERL_VERSION = 5.00600;
my @TEST_MODULES     = qw(
   inc/Module/Build/Alien/Codepress.pm
   Build.PL
   Makefile.PL
   bin/codepress-install
);

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{ALIEN_CODEPRESS_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{ALIEN_CODEPRESS_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::MinimumVersion'; ## no critic

if ( $EVAL_ERROR ) {
    my $msg = 'Test::MinimumVersion required';
    plan( skip_all => $msg );
}

plan( tests => scalar @TEST_MODULES );

Test__MinimumVersion->import;
for my $module (@TEST_MODULES) {
   minimum_version_ok($module, $MIN_PERL_VERSION);
}
