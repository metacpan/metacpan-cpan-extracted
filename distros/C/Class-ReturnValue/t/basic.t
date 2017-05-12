#!perl -w

use Test::More tests => 32;

use_ok( Class::ReturnValue);

sub foo {
    my $r = Class::ReturnValue->new();
    $r->as_array('one', 'two',  'three');
   return $r->return_value();
   
   
   
}

my @array;
ok(@array = foo());
is($array[0] , 'one','dereferencing to an array is ok');
is($array[1] , 'two','dereferencing to an array is ok');
is($array[2] , 'three','dereferencing to an array is ok');
is($array[3] , undef ,'dereferencing to an array is ok');

ok(my $ref = foo());
ok(my @array2 = $ref->as_array());
is($array2[0] , 'one','dereferencing to an arrayref is ok');

is($array2[1] , 'two','dereferencing to an arrayref is ok');
is($array2[2] , 'three','dereferencing to an arrayref is ok');
is($array2[3] , undef ,'dereferencing to an arrayref is ok');
ok(foo(),"Foo returns true in a boolean context");

my ($a, $b, $c) = foo();
is ($a , 'one', "first element is 1");
is ($b, 'two' , "Second element is two");
is ($c , 'three', "Third element is three");

my ($a2, $b2, $c2) = foo();
is ($a2 , 'one', "first element is 1");
is ($b2, 'two' , "Second element is two");
is ($c2 , 'three', "Third element is three");


sub bing {
    my $ret = Class::ReturnValue->new();
    return $ret->return_value;
    return("Dead");
}

ok(bing());
ok(bing() ne 'Dead');



sub bar {
    my $retval3 = Class::ReturnValue->new();
    $retval3->as_array(1,'asq');
   return_value $retval3;
}
ok(bar());
sub baz {
    my $retval = Class::ReturnValue->new();
    $retval->as_error(errno=> 1);
   return_value  $retval;
}

if(baz()){
 ok (0,"returning an error evals as true");
} else {
 ok (1,"returning an error evals as false");

}

ok(my $retval = Class::ReturnValue->new());
ok($retval->as_error( errno => 20,
                        message => "You've been eited",
                        do_backtrace => 1));
like($retval->backtrace, qr{Trace begun at t[\\/]basic.t line});
is($retval->error_message,"You've been eited");


ok(my $retval2 = Class::ReturnValue->new());
ok($retval2->as_error( errno => 1,
                            message => "You've been eited",
                             do_backtrace => 0 ));
is($retval2->backtrace ,undef);
is($retval2->errno, 1, "Got the errno");
isnt($retval2->errno,20, "Errno knows that 20 != 1");

1;
