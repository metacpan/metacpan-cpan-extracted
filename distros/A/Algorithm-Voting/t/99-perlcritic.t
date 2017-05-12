use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

unless ($ENV{TEST_AUTHOR}) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan(skip_all => $msg);
}

eval "use Test::Perl::Critic (-severity => 1);";

if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

my $rcfile = File::Spec->catfile( 't', 'perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );
all_critic_ok();

