package MyClass::Attribute::DumpRun;

use strict;
use warnings;
use base 'Class::Component::Attribute';

use YAML;

sub register {
    my($class, $plugin, $c, $method, $value, $code) = @_;
    no strict 'refs'; 
    no warnings 'redefine';
    my $cname = ref($plugin) or return;
    *{"$cname\::$method"} = sub {
        (Dump($_[2]), Dump($value->()));
    };
}

1;
