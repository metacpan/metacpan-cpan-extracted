# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2015-09-21 10:19:13 +0100 (Mon, 21 Sep 2015) $ $Author: zerojinx $
# Id:            $Id: 00-critic.t 470 2015-09-21 09:19:13Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-critic.t,v $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = q[475.3.3];

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
			     -exclude => [qw(tidy
                                             PodSpelling
					     NamingConventions::Capitalization
					     ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok();
}

1;
