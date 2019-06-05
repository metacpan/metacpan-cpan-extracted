use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

eval { require Test::Perl::Critic; };

if ( $EVAL_ERROR ) {
   my $msg = 'Test::Perl::Critic required to criticise code';
   plan( skip_all => $msg );
}

Test::Perl::Critic->import( -severity => 4 );
all_critic_ok();
