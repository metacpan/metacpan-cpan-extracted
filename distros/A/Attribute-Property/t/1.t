#!/usr/bin/perl -I../blib/lib
# $Id: 1.t,v 1.20 2003/03/03 08:45:48 juerd Exp $
# make; perl -Iblib/lib t/1.t

use lib 't/lib';
use Test::More tests => 386;

# BEGIN {
#     my $ok = \&ok;
#     *ok = sub ($;$) { select(undef, undef, undef, 0.1); goto &$ok; }
# }

no strict;
no warnings;

BEGIN { use_ok('Attribute::Property') };

my $ok;

{
	package X::X;
	sub new { bless { }, shift }
	sub New1 : New;
	sub New2 : New { $ok = !$ok; shift }
	sub New3 : New { 3 };
	sub digits : Property { /^\d+$/ }
	sub any : Property;
	sub fail : Property { 0 }
	sub du_is_13 : Property { $ok = $_ == 13; 1 }
	sub du1_is_13 : Property { $ok = $_[1] == 13; 1 }
	sub du1_is_du : Property { $_ = 14; $ok = $_[1] == $_; 1 }
	sub du_is_du1 : Property { $_[1] = 14; $ok = $_ == $_[1]; 1 }
	sub foo2bar_du : Property { s/foo/bar/ }
	sub foo2bar_du1 : Property { $_[1] =~ s/foo/bar/ }
	sub ok2one : Property { $ok = 1 }
	sub ok2zero : Property { $ok = 0 }
	sub objectok : Property { $ok = shift->isa(__PACKAGE__) }
	sub DESTROY { $ok = 2; }
	BEGIN { *begin = sub : Property { 1 } }

        package X::Y;
        @ISA = 'X::X';
        sub xy_property : Property;
        
        package X::Z;
        @ISA = 'X::Y';
        sub new : New;
}

ok(my $object1 = eval { X::X->new }, "object1 construction");
ok(!$@, "no error during object1 construction");
ok(my $object2 = eval { X::X->New1 }, "object2 construction");
ok(!$@, "no error during object2 construction");
ok(my $object3 = eval { X::Y->New1 }, "object3 construction");
ok(!$@, "no error during object3 construction");
ok(my $object4 = eval { X::Z->new }, "object4 construction");
ok(!$@, "no error during object4 construction");

for my $y ([ $object1 => 'object1 (X)' ], [ $object2 => 'object2 (X)' ], 
    [ $object3 => 'object3 (Y)' ], [ $object4 => 'object4 (Z)' ],
    [ "X::X" => 'class1 (X)' ], [ "X::Y" => "class2 (Y)" ],
    [ "X::Z" => 'class3 (Z)' ]) {

my $x = $y->[0];
my $z = "($y->[1])";

isa_ok($x, 'X::X') if ref $x;
isa_ok($x, 'HASH') if ref $x;

can_ok($x, qw(digits any fail du_is_13 du1_is_13 du1_is_du du_is_du1 foo2bar_du
              foo2bar_du1 ok2one ok2zero objectok DESTROY));

$ok = 0; $x->objectok = 1;
ok($ok, "$z validation sub can access object");
$ok = 0; $x->ok2one = 1;
ok($ok, "$z assignment executes code");
$ok = 1; $x->ok2zero;
ok($ok, "$z retrieval doesn't execute code");

ok($x->digits = 123, "$z lvalue assignment");
ok($x->digits == 123, "$z lvalue assignment succeeds");
ok($x->digits == 123, "$z value doesn't change after test");
ok($x->{digits} == 123, "$z hash element gets set with lvalue assignment");

ok($x->digits(456), "$z archaic assignment");
ok($x->digits == 456, "$z archaic assignment succeeds");
ok($x->digits == 456, "$z value doesn't change after test");
ok($x->{digits} == 456, "$z hash element gets set with archaic assignment");

ok($x->any = "foo", "$z validationless lvalue assignment");
ok($x->any eq "foo", "$z validationless lvalue assignment succeeds");
ok($x->any eq "foo", "$z value doesn't change after test");
ok($x->{any} eq "foo", "$z hash element gets set with validationless lvalue " .
                       "assignment");

ok($x->any("bar"), "$z validationless archaic assignment");
ok($x->any eq "bar", "$z validationless archaic assignment succeeds");

ok(!eval { $x->fail = 1 }, "$z invalid lvalue assignment #1");
ok($@ =~ /fail property/, "$z error message mentions property name 'fail'");
ok($x->fail != 1, "$z invalid lvalue assignment #1 fails succesfully #1");
ok($x->{fail}!=1, "$z invalid lvalue assignment #1 fails succesfully #2");

ok(!eval { $x->digits = "abc" }, "$z invalid lvalue assignment #2");
ok($@ =~ /digits property/, "$z error message mentions property name 'digits'");
ok($x->digits ne 'abc', "$z invalid lvalue assignment #2 fails succesfully #1");
ok($x->{digits}ne'abc', "$z invalid lvalue assignment #2 fails succesfully #2");

ok(!eval { $x->fail(2) }, "$z invalid archaic assignment #1");
ok($@ =~ /fail property/, "$z error message mentions property name 'fail'");
ok($x->fail != 2, "$z invalid archaic assignment #1 fails succesfully #1");
ok($x->{fail}!=2, "$z invalid archaic assignment #1 fails succesfully #2");

ok(!eval { $x->digits("def") }, "$z invalid archaic assignment #2");
ok($@ =~ /digits property/, "$z error message mentions property name 'digits'");
ok($x->digits ne 'def',"$z invalid archaic assignment #2 fails succesfully #1");
ok($x->{digits}ne'def',"$z invalid archaic assignment #2 fails succesfully #2");

$ok = 0; $x->du_is_13 = 13;
ok($ok, "$z \$_ is set properly");
$ok = 0; $x->du1_is_13 = 13;
ok($ok, "$z \$_[1] is set properly");

$ok = 0; $x->du_is_du1 = 1;
ok($ok, "$z \$_ and \$_[1] are proper aliases #1");
$ok = 0; $x->du1_is_du = 1;
ok($ok, "$z \$_ and \$_[1] are proper aliases #2");

$x->foo2bar_du = 'foo';
ok($x->foo2bar_du eq 'bar', "$z Changing \$_ changes property value");

$x->foo2bar_du1 = 'foo';
ok($x->foo2bar_du1 eq 'bar', "$z Changing \$_[1] changes property value");

{ $x->any = 1; my $foo = \$x->any; $$foo = 2; }
ok($x->any == 2, "$z reference holds #1");

{ my $foo = \($x->any = 3); $$foo = 4; }
ok($x->any == 4, "$z reference holds #2");

my $foo = \$x->digits; 
ok(!eval { $$foo = "abc"; 1 }, "$z invalid reference assignment");
ok($x->digits ne"abc", "$z invalid reference assignment fails succesfully");
ok($$foo = 234, "$z reference assignment");
ok($$foo == 234, "$z reference assignment succeeds");
ok($$foo == 234, "$z value doesn't change after test");
ok($x->{digits} == 234, "$z hash element gets set with reference assignment");

} # end of for (object1, object2, class)

ok($object1->begin = 1, "generated property works");

$ok = 0; undef $object1;
ok($ok == 2, "object1 gets destroyed correctly");
$ok = 0; undef $object2;
ok($ok == 2, "object2 gets destroyed correctly");

my $o;

$ok = 0;
ok($o = X::X->New2, "constructor with initialization code block works");
ok($ok, "construction executes code");
ok(X::X->New3 == 3, "initialization code block returns 3");

$ok = 1;
ok(!eval { X::X->New2(blah => 1) }, "inexistent property fails");
ok($ok, "faulty construction does not execute code");
ok($@ =~ /No such property/, "error message says so");
ok($@ =~ /blah/, "error message mentions inexistent property name 'blah'");
ok($@ =~ /New2/, "error message mentions method name"); 

ok($o = X::X->New1(digits => 123), "initial property assignment");
ok($o->digits == 123, "initial property assignment succeeds");

ok(!eval { X::X->New1(digits => "abc") },"invalid initial property assignment");
ok($o->digits ne"abc", "invalid initial property assignment fails succesfully");
ok($@ =~ /digits property/, "error message mentions property name 'digits'");
ok($@ =~ /New1/, "error message mentions method name");

ok(!eval { X::X->New1(1) }, "odd number of args lets constructor croak");
ok($@ =~ /Odd number/, "error message says so");
ok($o = X::X->New1(digits => 123, any => "z"), "setting multiple properties");
ok($o->digits==123 && $o->any eq "z", "setting multiple properties succeeds");

ok(!eval q{my$a= sub : Property { }; 1 }, "anonymous sub can't be a property");
ok($@ =~ /Property attribute.*anonymous sub/, "error message says so");

ok($o = X::Y->New1(any => 135, xy_property => 196), "subclass recognises SUPER's property");
ok($o->any == 135, "initial inherited property assignment succeeds");
ok($o->xy_property == 196, "own property assignment succeeds");
ok($o = X::Z->new(any => 153, xy_property => 169), "sub-subclass works too");
ok($o->any == 153, "inherited inherited property assignment succeeds again");
ok($o->xy_property == 169, "another initial inherited property assignments succeeds");
ok($o->any = 15, "inherited property still an lvalue");
ok($o->any == 15, "inherited property assignment succeeds");
ok(!eval { $o->digits = "abc" }, "inherited property keeps restrictions");
ok($@ =~ /digits property/, "error message agrees");


# vim: ft=perl sts=0 noet sw=8 ts=8
