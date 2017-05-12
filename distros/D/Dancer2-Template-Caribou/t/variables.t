use strict;
use warnings;

use Test::More tests => 2;
package MyApp;

use Dancer2;
use Dancer2::Test;

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

response_status_is '/' => 200;


