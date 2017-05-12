#!perl -T
# 01-connect.t
use 5.006;
use strict;
use warnings FATAL => 'all';
use ARS::Simple;
use Test::More;

plan tests => 1;

BEGIN
{
    eval {require './t/config.cache'; };
    if ($@)
    {
        plan( skip_all => "Testing configuration was not set, test not possible" );
    }
}

plan( skip_all => "Automated testing") if ($ENV{PERL_MM_USE_DEFAULT} || $ENV{AUTOMATED_TESTING});

diag( "Testing against server: " .  CCACHE::server());

my $ars = ARS::Simple->new({
        server   => CCACHE::server(),
        user     => CCACHE::user(),
        password => CCACHE::password(),
        });

ok(defined($ars), 'connected to Remedy ARSystem');