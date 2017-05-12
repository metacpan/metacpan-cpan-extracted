package RPC::ExtDirect::Test::Env;

use strict;
use warnings;
no  warnings 'uninitialized';

use RPC::ExtDirect class => 'Env';

sub http_list : ExtDirect(0) {
    my ($class, $env) = @_;

    my @list = $env->http();

    return [ @list ];
}

sub http_header : ExtDirect(1) {
    my ($class, $header, $env) = @_;

    return $env->http($header);
}

sub param_list : ExtDirect(0) {
    my ($class, $env) = @_;

    my @list = $env->param();

    return [ @list ];
}

sub param_get : ExtDirect(1) {
    my ($class, $name, $env) = @_;

    return $env->param($name);
}

sub cookie_list : ExtDirect(0) {
    my ($class, $env) = @_;

    my @cookies = $env->cookie();

    return [ @cookies ];
}

sub cookie_get : ExtDirect(1) {
    my ($class, $name, $env) = @_;

    return $env->cookie($name);
}

1;

