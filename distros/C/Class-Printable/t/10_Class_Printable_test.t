#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { 
    use_ok('Class::Printable');
}

# check the default values
can_ok("Class::Printable", 'toString');
is(Class::Printable->toString(), 'Class::Printable', '... got the default value we expected');

can_ok("Class::Printable", 'stringValue');
is(Class::Printable->stringValue(), 'Class::Printable', '... got the default value we expected');

# test is on a few packages

{
    package TestPackage;
    our @ISA = ('Class::Printable');
    
    sub new {
        my ($class, $value) = @_;
        return bless { value => $value }, $class;
    }
    
    sub toString {
        my ($self) = @_;
        return $self->{value}
    }
}

can_ok("TestPackage", 'new');

{
    my $test = TestPackage->new("Hello World");
    isa_ok($test, 'TestPackage');
    isa_ok($test, 'Class::Printable');    
    
    can_ok($test, 'toString');
    can_ok($test, 'stringValue');
    
    is($test->toString(), 'Hello World', '... got the toString value');
    is("$test", 'Hello World', '... got the overload value');
    like($test->stringValue(), qr/TestPackage\=HASH\(0x[a-z0-9]+\)/, '... got the string value');
}

# and another package

{
    package TestOtherPackage;
    our @ISA = ('Class::Printable');
    
    sub new {
        my ($class, $value) = @_;
        return bless { value => $value }, $class;
    }
}

can_ok("TestOtherPackage", 'new');

{
    my $test = TestOtherPackage->new("Hello Other World");
    isa_ok($test, 'TestOtherPackage');
    isa_ok($test, 'Class::Printable');    
    
    can_ok($test, 'toString');
    can_ok($test, 'stringValue');
    
    like($test->toString(), qr/TestOtherPackage\=HASH\(0x[a-z0-9]+\)/, '... got the toString value');    
    like("$test", qr/TestOtherPackage\=HASH\(0x[a-z0-9]+\)/, '... got the overload value');
    like($test->stringValue(), qr/TestOtherPackage\=HASH\(0x[a-z0-9]+\)/, '... got the string value');
}

{
    my $test = TestOtherPackage->new("Hello Other World");
    isa_ok($test, 'TestOtherPackage');

    my $test2 = TestOtherPackage->new("Hello Other World");
    isa_ok($test2, 'TestOtherPackage');    
    
    ok($test ne $test2, '... these objects are not equal and they dont try to find overloads');
}

