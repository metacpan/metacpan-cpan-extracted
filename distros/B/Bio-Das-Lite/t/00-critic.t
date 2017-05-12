#########
# Author:        rmp
# Last Modified: $Date: 2010-03-24 19:29:46 +0000 (Wed, 24 Mar 2010) $ $Author: zerojinx $
# Id:            $Id: 00-critic.t 19 2010-03-24 19:29:46Z zerojinx $
# Source:        $Source: /var/lib/cvsd/cvsroot/Bio-DasLite/Bio-DasLite/t/00-critic.t,v $
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 19 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 1,
			     -exclude => [qw(tidy ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok();
}

1;
