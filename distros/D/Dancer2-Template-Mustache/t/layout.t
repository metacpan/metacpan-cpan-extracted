use strict;
use warnings;

use Test::More tests => 2;

{
    package MyApp;

    use Dancer2;

    set views => 't/views';
    set layout => 'face';

    set engines => {
        mustache => { 
        },
    };

    set template => 'mustache';

    get '/style/:style' => sub {
        template 'layout' => {
            style => param('style')
        };
    };
}

use Test::WWW::Mechanize::PSGI; 

my $mech = Test::WWW::Mechanize::PSGI->new( app => MyApp->to_app );

$mech->get_ok( '/style/fu_manchu' );
$mech->content_contains( "Manly fu_manchu mustache \n you have there" ); 

