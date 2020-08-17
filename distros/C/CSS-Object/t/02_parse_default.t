#!/usr/local/bin/perl

use Test::More qw( no_plan );
use constant DEBUG => 0;

use CSS::Object;
my $css = CSS::Object->new({ parser => 'CSS::Object::Parser::Default', debug => DEBUG });
ok( $css, "Created the CSS object ok" );

# SIMPLE TESTS

my $rc = $css->read_file( 't/css_simple' ) || BAIL_OUT( "Cannot read fle \"t/css_simple\": ", $css->error );
ok( $rc, 'Parsed the simple file ok' );

diag( "Total number of rules: ", $css->rules->length ) if( DEBUG );
ok( $css->rules->length == 3, 'Correct number of rulesets' );
my $rule1 = $css->rules->get(0);
isa_ok( $rule1, 'CSS::Object::Rule', 'Rule #1 object' );
defined( $rule1 ) || BAIL_OUT( "Cannot get rule #1 object" );
is( $rule1->properties->length, 3, "Rule #1 has 3 properties" );
is( $rule1->comments->length, 1, "Rule #1 has 1 comment" );
is( $rule1->properties->get(2)->value->as_string, "/* bar is not a real property value */ \"bar\"", "Rule #1 3rd property value with comment" );

# PURGE TEST

$css->purge;
ok( $css->rules->length == 0, 'CSS::Object::purge worked' );

# SELECTOR GROUPS

$rc = $css->read_file( 't/css_selector_groups' );
my $is_ok = 1;
ok( $rc, 'Loaded t/css_selector_groups' );
my @selector_counts = (1,2,2,2,2,2,2,2,3,3);
ok( $css->rules->length == 10, 'Correct number of rulesets' );
diag( $css->rules->length, " rules found." ) if( DEBUG );
for( @{$css->rules} )
{
    # diag( "This rule has ", $_->selectors->length, " selectors vs $selector_counts[0] expected." );
	$is_ok = 0 if( $_->selectors->length != shift( @selector_counts ) );
}
ok( $is_ok, 'Correct number of selectors parsed' );

# test for odd rules

$css->purge;
$css->read_file( 't/css_oddities' );
diag( "First rule has ", $css->rules->first->properties->length, " properties." ) if( DEBUG );
my @props = $css->rules->get(0)->properties->list;
diag( "First prop value is: '", $props[0]->value, "'." ) if( DEBUG );
ok( $props[0]->value eq 'a', 'first property ok' );
diag( "Second prop value is: '", $props[1]->value, "'." ) if( DEBUG );
ok( $props[1]->value eq '0', 'second property ok' );

