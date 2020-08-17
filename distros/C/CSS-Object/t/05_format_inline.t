#!/usr/local/bin/perl

use Test::More qw( no_plan );
use constant DEBUG => 0;

$expected_output = "display: inline-block; background-image: url(/some/file.png); font-size: 1.2rem; /* Maybe we should vertical align this too? */ text-align: center;";

use_ok( 'CSS::Object' );
use_ok( 'CSS::Object::Rule' );
use_ok( 'CSS::Object::Property' );

my $css = CSS::Object->new(
    format => 'CSS::Object::Format::Inline',
    debug => DEBUG
) || BAIL_OUT( CSS::Object->error );
isa_ok( $css, 'CSS::Object', 'CSS::Object object' );
diag( "CSS::Object format is ", ref( $css->format ) ) if( DEBUG );
isa_ok( $css->format, 'CSS::Object::Format::Inline', 'CSS::Object::Format::Inline object' );

my $rule = $css->new_rule;
BAIL_OUT( "Error getting a new rule: ", $css->error ) if( !defined( $rule ) );

isa_ok( $rule, 'CSS::Object::Rule', 'CSS::Object::Rule object' );
isa_ok( $rule->format, 'CSS::Object::Format::Inline', 'Rule uses a CSS::Object::Format::Inline object' );

$rule->add_property( $css->new_property(
    name => 'display',
    value => 'inline-block',
) )->add_property( $css->new_property(
    name => 'background-image',
    value => 'url(/some/file.png)',
) )->add_property( $css->new_property(
    name => 'font-size',
    value => '1.2rem',
) )->add_element( $css->new_comment(
    "Maybe we should vertical align this too?",
) )->add_property( $css->new_property(
    name => 'text-align',
    value => 'center',
) ) || die( $rule->error );

is( $rule->elements->length, 5, "Rule has 5 elements" );
my $prop_format_isa_ok = 0;
$rule->elements->foreach(sub
{
    isa_ok( $_->format->class, 'CSS::Object::Format::Inline', 'Rule element uses CSS::Object::Format::Inline formatter' );
});

my $res = $rule->as_string;
is( $res, $expected_output, 'Rule stringified for inline style' );
