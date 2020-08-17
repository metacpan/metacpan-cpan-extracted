use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all =>
        'Must set DATETIME_FORMAT_ISO8601_TEST_DEPS to true in order to run these tests'
        unless $ENV{DATETIME_FORMAT_ISO8601_TEST_DEPS};
}

use Test::DependentModules qw( test_all_dependents );

local $ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my %exclude = map { $_ => 1 } (

    # Tests hit live MetaCPAN and are very slow
    'App-RetroPAN',

    # undeclared dep on DBD-mysql
    'CPAN-Testers-Schema',

    # Fails tests out of the box
    'Marketplace-Rakuten',

    # Generated Makefile doesn't work
    'SReview',
);

test_all_dependents(
    'DateTime-Format-ISO8601',
    {
        filter => sub { !$exclude{ $_[0] } }
    },
);
