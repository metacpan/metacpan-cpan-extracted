use strict;
use warnings;

package MyApp;

use Test2::V0; plan 2;
use Dancer2;
use Test::WWW::Mechanize::PSGI;

{ 
    package Dancer2::View::MyView;

    use Template::Caribou;

    use Test::More;

    with qw/ 
        Dancer2::Template::Caribou::DancerVariables 
    /;

    template page => sub {
        my $self = shift;
        
        is $self->uri_for( '/foo' ) => 'http://localhost/foo';
    };

}

setting template => 'Caribou';

get '/' => sub { template 'MyView' };

my $mech = Test::WWW::Mechanize::PSGI->new(
    app => MyApp->to_app 
);

$mech->get_ok('/');
