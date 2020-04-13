use strict;
use warnings;

use Test::More tests => 2;

{

    package MyApp;

    use Dancer2;

    set views  => 't/views';
    set layout => 'layout';

    set engines => { handlebars => {}, };

    set template => 'handlebars';

    get '/' => sub {
        template 'hello' => { you => 'world', };
    };
}

use Test::WWW::Mechanize::PSGI;

my $mech = Test::WWW::Mechanize::PSGI->new( app => MyApp->to_app );

$mech->get_ok('/');
$mech->content_like( qr/!!! \s+ hello \s there, \s world \s+ !!!/xi, );

