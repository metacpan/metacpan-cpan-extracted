use strict;
use warnings;

use Test::More tests => 7;
use Test::WWW::Mechanize::PSGI; 

{
    package MyApp;

    use Dancer2;

    set views => 't/views';

    set show_errors => 1;
    set traces => 1;

    set engines => {
        mustache => { 
        },
    };

    set template => 'mustache';

    get '/' => sub {
        template 'index';
    };

    get '/style/:style' => sub {
        template 'index' => {
            style => param('style')
        };
    };

    get '/partial' => sub {
        template 'partial';
    };
}

my $mech = Test::WWW::Mechanize::PSGI->new( app => MyApp->to_app );

$mech->get_ok( '/' );
$mech->content_contains( 'Welcome manly mustached man' );
$mech->content_lacks( 'Nice', 'undef section' );

$mech->get_ok( '/style/pencil' );
$mech->content_contains( 'Nice pencil mustache', 'interpolation and section' );

$mech->get_ok( '/partial' );
$mech->content_contains( ':})=', 'partials work' );
