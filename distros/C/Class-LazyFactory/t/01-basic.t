package MyClass::Factory;
use strict;
use base qw/Class::LazyFactory/;

__PACKAGE__->initialize_factory( 
    namespace   => 'MyClass::Impl',
    constructor => 'new',
);


package MyClass::Impl::Abstract;
use strict;
use Carp;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    return $self;
}

sub get_greeting { croak "Unimplemented" }


package MyClass::Impl::Hello;
use strict;
use base qw/MyClass::Impl::Abstract/;

sub get_greeting { "hello" }


package MyClass::Impl::World;
use strict;
use base qw/MyClass::Impl::Abstract/;

sub get_greeting { "world" }


1;

package main;
use strict;
use warnings;
use Test::More qw/no_plan/;

my $x;

$x = MyClass::Factory->new("Hello");
ok defined($x);
isa_ok $x, q{MyClass::Impl::Hello};
is $x->get_greeting(), "hello";

$x = MyClass::Factory->new("World");
ok defined($x);
isa_ok $x, q{MyClass::Impl::World};
is $x->get_greeting(), "world";




__END__
