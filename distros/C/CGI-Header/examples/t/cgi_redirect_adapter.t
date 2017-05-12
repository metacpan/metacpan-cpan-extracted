use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok 'CGI::Redirect::Adapter';
}

my $redirect = CGI::Redirect::Adapter->new;

is $redirect->as_string, $redirect->query->redirect;
