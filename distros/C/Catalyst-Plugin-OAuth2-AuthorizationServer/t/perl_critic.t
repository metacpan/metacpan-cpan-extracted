#! perl
use strict;
use warnings;
use Test::More;

# Author/maintainer test: only runs when explicitly requested, so a normal
# `prove -lr t` (and CPAN smoke testers) skip it. Gated on the PERL_CRITIC_TEST
# env var and written for Test::More.
if ( not $ENV{PERL_CRITIC_TEST} ) {
    plan skip_all => 'Set $ENV{PERL_CRITIC_TEST} to a true value to run.';
}

eval { require Test::Perl::Critic; 1 }
    or plan skip_all => 'Test::Perl::Critic required to criticise code';

Test::Perl::Critic->import(
    -exclude => [
        'BuiltinFunctions::RequireBlockMap',        # unnecessarily picky
        'CodeLayout::RequireUseUTF8',
        'Subroutines::ProhibitExplicitReturnUndef',
        'ValuesAndExpressions::ProhibitVersionStrings', # project uses use v5.36
        'ErrorHandling::RequireCarping',            # we throw structured errors/objects, not strings
        'Moose::RequireCleanNamespace',             # misses MooseX::MarkAsMethods
        'Subroutines::ProhibitUnusedPrivateSubroutines', # Moo lazy builders (_build_*) are called by Moo internals
    ],
    -include => [ 'CodeLayout::ProhibitTrailingWhitespace' ],
);

Test::Perl::Critic::all_critic_ok('lib');
