#########
# Author:        rmp
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: critic.t 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /cvsroot/Bio-DasLite/Bio-DasLite/t/00-critic.t,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/t/critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 687 $ =~ /\d+/mxsg); $v; };

if (!$ENV{TEST_AUTHOR}) {
  my $msg = 'Author test.  Set the TEST_AUTHOR environment variable to a true value to run.';
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
           -profile => File::Spec->catfile( 't', 'criticrc' ),
           -exclude => [qw(tidy
               Subroutines::ProhibitExcessComplexity
               ValuesAndExpressions::RequireConstantVersion
               ValuesAndExpressions::ProhibitImplicitNewlines
               Miscellanea::ProhibitUnrestrictedNoCritic
               BuiltinFunctions::ProhibitReverseSortBlock)],
          );
  #all_critic_ok('lib/Bio/Das/ProServer/SourceAdaptor/');
  #plan tests => 1;
  #critic_ok('lib/Bio/Das/ProServer/Config.pm');
  all_critic_ok();
}

1;
