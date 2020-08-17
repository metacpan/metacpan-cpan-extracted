#!/usr/local/bin/perl

use Test::More qw( no_plan );
use constant DEBUG => 0;

use_ok( 'CSS::Object' );
my $css = CSS::Object->new( debug => DEBUG );
isa_ok( $css, 'CSS::Object', 'CSS::Object' );

# SEARCH TESTS

my $rc = $css->read_file( 't/css_simple' );
ok( $rc, 'Parsed the simple file' );
diag( "Error parsing: ", $css->error ) if( !defined( $rc ) );

diag( $css->elements->length, " rules found in parsed file." ) if( DEBUG );
my $rule = $css->get_rule_by_selector( 'baz' );
isa_ok( $rule, 'CSS::Object::Rule', 'Got CSS::Object::Rule object' );

$rule || BAIL_OUT( "Cannot get a rule for 'baz'" );
my $prop = $rule->get_property_by_name( 'color' );
diag( "Property object found '$prop'." ) if( DEBUG );
isa_ok( $prop, 'CSS::Object::Property', 'Got CSS::Object::Property object' );

ok( $prop->value eq 'black', 'Got property value' );
