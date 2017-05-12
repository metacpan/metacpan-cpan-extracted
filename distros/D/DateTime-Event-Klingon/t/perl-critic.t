#!perl -T
#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/t/perl-critic.t 323 2008-04-01T06:37:25.246199Z jaldhar  $
#
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;

my $test = Test::Builder->new;

if ( !$ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval " use Test::Perl::Critic (-profile => 't/perlcriticrc'); ";
if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan( skip_all => $msg );
}

all_critic_ok();

