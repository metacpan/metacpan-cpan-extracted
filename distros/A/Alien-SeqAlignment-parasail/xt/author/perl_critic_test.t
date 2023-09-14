use warnings;
use File::Spec;
use Test2::V0;
use Test::Perl::Critic;
use English qw(-no_match_vars);


## code lifted from https://metacpan.org/pod/Test::Perl::Critic 
if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Author test.  Set $ENV{AUTHOR_TESTING} to a true value to run.';
    plan( skip_all => $msg );
}
 
eval { require Test::Perl::Critic; };
 
if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

all_critic_ok();