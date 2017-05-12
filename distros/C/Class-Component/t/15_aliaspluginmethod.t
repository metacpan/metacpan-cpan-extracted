#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More;

eval " use YAML ";
plan skip_all => "YAML is not installed." if $@;
plan 'no_plan';

use MyClass;
for my $plugin (qw/ AliasMethod AliasMethod2 /) {
    my $obj = MyClass->new({ load_plugins => [$plugin] });
    is $obj->call('bar'), 'baz';

    MyClass->load_components(qw/ Autocall::InjectMethod /);
    my $obj2 = MyClass->new({ load_plugins => [$plugin] });
    is $obj2->bar, 'baz';
    clear_isa();
    { no strict 'refs'; delete ${'MyClass::'}{bar}; }

    MyClass->load_components(qw/ Autocall::SingletonMethod /);
    my $obj3 = MyClass->new({ load_plugins => [$plugin] });
    is $obj3->bar, 'baz';
    clear_isa();
    { no strict 'refs'; delete ${'MyClass::_Singletons::0::'}{bar}; }

    MyClass->load_components(qw/ Autocall::Autoload /);
    my $obj4 = MyClass->new({ load_plugins => [$plugin] });
    is $obj4->bar, 'baz';
    clear_isa();
}

sub clear_isa {
    @MyClass::ISA = ('Class::Component');
    for my $key (keys %{ Class::Component::Implement->default_components } ) {
        delete Class::Component::Implement->default_components->{$key};
    }
}

