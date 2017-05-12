#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 32;

use_ok('Class::Interfaces' =>  (
    Serializable   => [ 'pack', 'unpack' ],
    Iterable       => [ 'iterator' ],
    Visitable      => [ 'visit' ],
    Saveable       => { isa => 'Serializable', methods => [ 'save', 'restore' ] },
    VisitOrIterate => { isa => [ 'Visitable', 'Iterable' ] },
    Printable      => { methods => [ 'toString', 'stringValue' ] },
    ));

can_ok("Serializable", 'pack');
can_ok("Serializable", 'unpack');

can_ok("Iterable", 'iterator');

can_ok("Visitable", 'visit');

isa_ok(bless({}, 'Saveable'), 'Serializable');
can_ok("Saveable", 'pack');
can_ok("Saveable", 'unpack');
can_ok("Saveable", 'save');
can_ok("Saveable", 'restore');

isa_ok(bless({}, 'VisitOrIterate'), 'Visitable');
isa_ok(bless({}, 'VisitOrIterate'), 'Iterable');
can_ok("VisitOrIterate", 'iterator');
can_ok("VisitOrIterate", 'visit');

can_ok("Printable", 'toString');
can_ok("Printable", 'stringValue');

# now check the error handling

eval {
    Class::Interfaces->import(
        Fail => sub {}
        );
};
like($@, qr/Cannot use a (.*?) to build an interface/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        Fail => { isa => sub {} }
        );
};
like($@, qr/Interface \(Fail\) isa list must be an array reference/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        Fail => { methods => sub {} }
        );
};
like($@, qr/Method list for Interface \(Fail\) must be an array reference/, '... got the error we exepected');

eval {
    Class::Interfaces->import(
        '+' => []
        );
};
like($@, qr/Could not create Interface \(\+\) because \: /, '... got the error we exepected');


eval {
    Class::Interfaces->import(
        Pass => [ 'my_import_sub' ]
        );
};	
ok(!$@, '... this passed fine');

eval {
    Class::Interfaces->import(
        Fail => [ 'BEGIN' ]
        );
};
like($@, qr/Could not create sub methods for Interface \(Fail\) because \: Cannot create an interface using reserved perl methods/, '... got the error we exepected');

eval {
    Class::Interfaces->_method_stub();
};
like($@, qr/Method Not Implemented/, '... got the error we expected');

eval {
    Serializable->pack();
};
like($@, qr/Method Not Implemented/, '... got the error we expected');

# test the subclass ability
{
    package My::Test::Interfaces;
    
    our @ISA = 'Class::Interfaces';
    
    sub _build_interface_package {
        my $pkg = (shift)->SUPER::_build_interface_package(@_);
        $pkg .= "\nsub other_method { 'other_method' }";
        return $pkg;
    }
    sub _error_handler { die "Error Has Been Handled" }
    sub _method_stub { die "My Custom Exception" }
}

eval {
    My::Test::Interfaces->import(
        '+' => []
        );
};
like($@, qr/Error Has Been Handled/, '... got the error we exepected');

eval {
    My::Test::Interfaces->import(TestInterface => [ 'test' ]);
};
ok(!$@, '... created our Class::Interfaces subclass ok');
    
eval {
    TestInterface->test();
};
like($@, qr/My Custom Exception/, '... got the error we expected');    

can_ok('TestInterface', 'other_method');
is(TestInterface->other_method(), 'other_method', '... got the value we expected');

# test the subclass ability
{
    package My::Other::Test::Interfaces;
    
    our @ISA = 'Class::Interfaces';
}

eval {
    My::Other::Test::Interfaces->import(OtherTestInterface => [ 'test' ]);
};
ok(!$@, '... created our Class::Interfaces subclass ok');
    
eval {
    OtherTestInterface->test();
};
like($@, qr/Method Not Implemented/, '... got the error we expected');  

# test marker interfaces

Class::Interfaces->import(
    Marker => undef
    );

eval "package MarkerTest; use base 'Marker';";
ok(!$@, '... we should not get an exception here');
