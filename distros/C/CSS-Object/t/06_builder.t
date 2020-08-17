#!/usr/local/bin/perl

use Test::More qw( no_plan );
use constant DEBUG => 0;

my $expected_result = <<'EOT';
#main_section > .article, section .article
{
    display: none;
    font-size: +0.2rem;
    /* Some multiline comment
that are made possible with array reference */
    text-align: center;
    /* Making it look pretty */
    padding: 5;
}

/* Keyframes goes here. */

@-webkit-keyframes error
{
    0%
    {
        -webkit-transform: translateX( 0px );
    }
    25%
    {
        -webkit-transform: translateX( 30px );
    }
    45%
    {
        -webkit-transform: translateX( -30px );
    }
    65%
    {
        -webkit-transform: translateX( 30px );
    }
    82%
    {
        -webkit-transform: translateX( -30px );
    }
    94%
    {
        -webkit-transform: translateX( 30px );
    }
    35%, 55%, 75%, 87%, 97%, 100%
    {
        -webkit-transform: translateX( 0px );
    }
}
EOT
chomp( $expected_result );

use_ok( 'CSS::Object' );

my $css = CSS::Object->new(
    format => 'CSS::Object::Format',
    debug => DEBUG
) || BAIL_OUT( CSS::Object->error );
isa_ok( $css, 'CSS::Object', 'CSS::Object object' );
diag( "CSS::Object format is ", ref( $css->format ) ) if( DEBUG );
isa_ok( $css->format, 'CSS::Object::Format', 'CSS::Object::Format object' );

my $b = $css->builder || BAIL_OUT( "Unable to get a CSS builder object: ", $css->error );
isa_ok( $b, 'CSS::Object::Builder', 'Get CSS::Object::Builder object' );

$b->charset( 'UTF-8' );

$b->select( ['#main_section > .article', 'section .article'] )
    ->display( 'none' )
    ->font_size( '+0.2rem' )
    ->comment( ['Some multiline comment', 'that are made possible with array reference'] )
    ->text_align( 'center' )
    ->comment( 'Making it look pretty' )
    ->padding( 5 );

$b->comment( 'Keyframes goes here.' );

$b->at( _webkit_keyframes => 'error' )
    ->frame( 0, { _webkit_transform => 'translateX( 0px )' })
    ->frame( 25, { _webkit_transform => 'translateX( 30px )' })
    ->frame( 45, { _webkit_transform => 'translateX( -30px )' })
    ->frame( 65, { _webkit_transform => 'translateX( 30px )' })
    ->frame( 82, { _webkit_transform => 'translateX( -30px )' })
    ->frame( 94, { _webkit_transform => 'translateX( 30px )' })
    ->frame( [qw( 35 55 75 87 97 100 )], { _webkit_transform => 'translateX( 0px )' } ) || die( $b->current_rule->error );

my $res = $css->as_string;
diag( "Result is:\n$res" ) if( DEBUG );
is( $res, $expected_result, 'Generated css' );

