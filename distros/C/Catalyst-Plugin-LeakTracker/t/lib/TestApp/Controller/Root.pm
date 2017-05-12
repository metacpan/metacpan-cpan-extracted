package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use Scalar::Util qw/weaken/;

use base 'Catalyst::Controller';

# your actions replace this one
sub main :Path {
    my ( $self, $c ) = @_;
    $c->res->body('<h1>It works</h1>');
}

sub leak :Local {
    my ( $self, $c ) = @_;

    my $object = bless {}, "class::a";
    $object->{foo}{self} = $object;


    my $object2 = bless {}, "class::b";
    $object2->{foo}{self} = $object2;
    weaken($object2->{foo}{self});

    my $object3 = bless [], "class::c";
    push @$object3,  $object3;

    $c->res->body("it leaks");
}

1;
