#!/usr/local/bin/perl

use Test::More qw( no_plan );
use constant DEBUG => 0;
use open ':std' => ':utf8';

use_ok( 'CSS::Object' );

my $format_name = 'CSS::Object::Format';
my $expected_output = "a\n{\n    b: c;\n}";

my $css = CSS::Object->new({
    format => $format_name,
    debug   => DEBUG,
});
isa_ok( $css, 'CSS::Object', 'CSS::Object object' );
my $rc = $css->read_file( 't/css_tiny' );
ok( $rc, 't/css_tiny loaded' );

my $css_string = $css->as_string;
ok( defined( $css_string ), 'Got a formated string' );

ok( $css_string eq $expected_output, 'formated string ok' );

if( $css_string ne $expected_output )
{
	$css_string =~ s/\n/\\n/g;
	$css_string =~ s/\t/\\t/g;
	print( "output was $css_string" );
}
diag( "Resulting css is:\n$css_string" ) if( DEBUG );
