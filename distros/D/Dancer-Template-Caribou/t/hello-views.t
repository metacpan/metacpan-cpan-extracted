package MyApp;

use strict;
use warnings;

use Test::More tests => 2;

use Dancer '!pass';
use Dancer::Test;

set appdir => 't';
config->{engines}{Caribou}{default_template} = 'inner_page';
set template => 'Caribou';
set show_errors => 1;
set logger => 'console';

{
    package Welcome;
    use Template::Caribou;

    has name => is => 'ro';

    template inner_page => sub { 'hello ' . $_[0]->name };
}

get '/hi/:name' => sub {
    template '+Welcome' => { name => param('name') };
};

response_content_like '/hi/yanick' => qr/hello yanick/;

{
    package MyLayout;

    use Moose::Role;

    use Template::Caribou;

    template page => sub { my $self = shift; $self->inner_page; print '!!!' };


}

get '/hullo/:name' => sub {
    
    set layout => '+MyLayout';
    template '+Welcome' => { name => param('name') };
};

response_content_like '/hullo/yanick' => qr/hello yanick!!!/;
