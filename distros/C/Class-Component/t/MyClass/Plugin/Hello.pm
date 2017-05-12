package MyClass::Plugin::Hello;

use strict;
use warnings;
use base 'Class::Component::Plugin';

sub hello :Method {
    my($self, $c, $args) = @_;
    'hello'
}

sub hello_hook :Hook('hello') {
    my($self, $c, $args) = @_;
    'hook hello'
}

sub hello2 :Method {
    my($self, $c, $str) = @_;
    $str
}

sub hello_hook2 :Hook('hello2') {
    my($self, $c, $args) = @_;
    $args->{value}
}

1;
