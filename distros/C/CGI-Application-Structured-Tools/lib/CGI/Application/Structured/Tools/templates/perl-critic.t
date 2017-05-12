#!perl -T
#
# $Id: perl-critic.t 52 2009-01-06 03:22:31Z jaldhar $
#
use strict;
use warnings;
use English qw( -no_match_vars );
use File::Find qw();
use Test::More;

if ( !$ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan skip_all => $msg;
}

eval " use Test::Perl::Critic (-profile => 't/perlcriticrc'); ";
if ($EVAL_ERROR) {
    my $msg = 'Test::Perl::Critic required to criticise code';
    plan skip_all => $msg;
}

my @files;

File::Find::find(
    {   untaint => 1,
        wanted  => sub {
            /^.*\.pm\z/msx
                && $File::Find::dir !~ /templates/mx
                && push @files, $File::Find::name;
            }
    },
    'blib/'
);

plan tests => scalar @files;

foreach (@files) {
    critic_ok($_);
}
