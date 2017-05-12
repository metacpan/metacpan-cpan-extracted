#########
# Author:        rmp
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: distribution.t 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /cvsroot/Bio-DasLite/Bio-DasLite/t/00-distribution.t,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/t/distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use lib qw(t/dummy);

our $VERSION = do { my ($v) = (q$LastChangedRevision: 687 $ =~ /\d+/mxg); $v; };

if (!$ENV{TEST_AUTHOR}) {
  my $msg = 'Author test.  Set the TEST_AUTHOR environment variable to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';

} else {
  Test::Distribution->import();
}

1;
