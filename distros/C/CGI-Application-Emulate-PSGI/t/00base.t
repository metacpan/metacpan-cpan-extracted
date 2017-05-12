use strict;
use warnings;

use Plack::Test;
use Test::More;

use_ok 'CGI::Application::Emulate::PSGI';

test_psgi
    app    => CGI::Application::Emulate::PSGI->handler(sub {
        my $ca = MyCGIApp->new;
        $ca->run;
    }),
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => 'http://localhost/');
        my $res = $cb->($req);
        is $res->code, 200, 'status code is 200';
        is $res->content_type, 'application/x-hello-world', 'content-type';
        is $res->content, 'hello world', 'body';
    };

done_testing;

package MyCGIApp;

use base qw(CGI::Application);

sub setup {
    my $self = shift;
    $self->run_modes('start' => 'start');
}

sub start {
    my $self = shift;
    $self->header_add(-type => 'application/x-hello-world');
    "hello world";
}
