# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequireExplicitPackage)
use 5.016;
use strict;
use warnings;
use utf8;
use Readonly;

use File::Spec;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = v0.0.7;

## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Array my @FILES => qw(blib lib t xt Build.PL inc);
## use critic
## no critic (RequireExplicitPackage)
if (
    !eval {
        require Test::Perl::Critic;
        require Perl::Critic::StricterSubs;
        require Perl::Critic::Nits;
        1;
    }
  )
{
    Test::More::plan 'skip_all' =>
      q{Test::Perl::Critic, Perl::Critic::StricterSubs and Perl::Critic::Nits }
      . q{required for testing PBP compliance};
}
Test::Perl::Critic->import(
    '-profile' => File::Spec->catfile( 'xt', 'perlcriticrc' ) );
## no critic (ProhibitCallsToUnexportedSubs RequireEndWithOne)
Test::Perl::Critic::all_critic_ok(@FILES);
## use critic
