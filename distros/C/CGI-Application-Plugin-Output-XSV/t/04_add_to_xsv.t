#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
  use_ok( 'CGI::Application::Plugin::Output::XSV', qw(:all) );
  use_ok( 'Text::CSV_XS' );
}

# add to xsv
my $csv= Text::CSV_XS->new();

foreach(
  [ qw(foo bar baz) ], [ qw(qux quux quuux) ], [ qw(alpha bravo charlie) ],
)
{
  my $out= add_to_xsv( $csv, $_, "\n" );

  is( $out, join( ',' => @$_ ) . "\n", "add_to_xsv [@$_]" );
}

my $out= add_to_xsv( $csv, [], "\n" );

is( $out, "\n", "add_to_xsv empty list returns line ending only" );
