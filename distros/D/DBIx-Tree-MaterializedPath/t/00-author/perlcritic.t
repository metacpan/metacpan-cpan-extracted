use strict;
use warnings;

use File::Spec;
use Test::More;

unless ($ENV{TEST_AUTHOR})
{
    my $msg = 'Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan(skip_all => $msg);
}

eval { require Test::Perl::Critic; };
if ($@)
{
    my $msg = 'Test::Perl::Critic required to criticize code.';
    plan(skip_all => $msg);
}

my $rcfile = File::Spec->catfile('t', '00-author', 'perlcriticrc');
Test::Perl::Critic->import(-profile => $rcfile);

all_critic_ok();

