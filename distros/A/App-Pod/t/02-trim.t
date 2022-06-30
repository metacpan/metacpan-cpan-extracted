#!perl
use v5.24;    # Postfix defef.
use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
    use_ok( 'App::Pod' ) || print "Bail out!\n";
}

diag( "Testing App::Pod $App::Pod::VERSION, Perl $], $^X" );

{
    no warnings qw( redefine once );
    *red                        = *App::Pod::_red;
    *yellow                     = *App::Pod::_yellow;
    *green                      = *App::Pod::_green;
    *Pod::Query::get_term_width = sub { 9 };
}

# Snippet for manually testing on the CLI:
# perl -Ilib -MApp::Pod -E 'say Pod::Query::get_term_width; App::Pod::_sayt( App::Pod::_red("1234567890") . App::Pod::_yellow("1234567890") . App::Pod::_green("1234567890") )'

my $replacement = " ...";
my @cases       = (

    # Less than term_width.
    {
        name            => "Less than term_width",
        input           => "12345678",
        expected_output => "12345678",
    },
    {
        name            => "Less than term_width (with color)",
        input           => red( "12345678" ),
        expected_output => red( "12345678" ),
    },
    {
        name            => "Less than term_width (with 3 colors)",
        input           => red( "123" ) . yellow( "456" ) . green( "78" ),
        expected_output => red( "123" ) . yellow( "456" ) . green( "78" ),
    },

    # Equal to term_width.
    {
        name            => "Equal to term_width",
        input           => "123456789",
        expected_output => "123456789",
    },
    {
        name            => "Equal to term_width (with color)",
        input           => red( "123456789" ),
        expected_output => red( "123456789" ),
    },
    {
        name            => "Equal to term_width (with 3 colors)",
        input           => red( "123" ) . yellow( "456" ) . green( "789" ),
        expected_output => red( "123" ) . yellow( "456" ) . green( "789" ),
    },

    # Greater than term_width.
    {
        name            => "Greater than term_width",
        input           => "1234567890",
        expected_output => "12345$replacement",
    },
    {
        name            => "Greater than term_width (with color)",
        input           => red( "1234567890" ),
        expected_output => red( "12345$replacement" ),
    },
    {
        name            => "Greater than term_width (with 3 colors)",
        input           => red( "123" ) . yellow( "456" ) . green( "7890" ),
        expected_output => red( "123" ) . yellow( "45$replacement" ),
    },
);

for my $case ( @cases ) {
    is(
        App::Pod::trim( $case->{input} ),
        $case->{expected_output},
        $case->{name},
    );
}

