package TestApp::Controller::Root;
use strict;
use warnings;
use utf8;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

# your actions replace this one
sub main :Path { 
    $_[1]->res->body('<h1>It works</h1>') 
}

sub unicode :Local {
    my ($self, $c) = @_;
    my $data = "ほげ"; # hoge!
    $c->response->body($data); # should be decoded
}

sub not_unicode :Local {
    my ($self, $c) = @_;
    my $data = "\x{1234}\x{5678}";
    utf8::encode($data); # DO NOT WANT unicode
    $c->response->body($data); # just some octets
}

sub file :Local {
    my ($self, $c) = @_;
    close *STDERR; # i am evil.
    $c->response->body($main::TEST_FILE); # filehandle from test file
}

1;
