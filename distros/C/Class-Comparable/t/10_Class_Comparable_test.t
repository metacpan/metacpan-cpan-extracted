#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 57;

BEGIN { 
    use_ok('Class::Comparable');
}

# test the code in the SYNOPSIS
{
    package Currency::USD;
    
    use base 'Class::Comparable';
    
    sub new { 
        my $class = shift;
        bless { value => shift }, $class;
    }
    
    sub value { (shift)->{value} }
    
    sub compare {
        my ($left, $right) = @_;
        # if we are comparing against another
        # currency object, then compare values
        if (ref($right) && $right->isa('Currency::USD')) {
            return $left->value <=> $right->value;
        }
        # otherwise assume we are comparing 
        # against a numeric value of some kind
        else {
            return $left->value <=> $right;
        }
    }
}
  

{  
    my $buck_fifty = Currency::USD->new(1.50);
    isa_ok($buck_fifty, 'Currency::USD');
    
    my $dollar_n_half = Currency::USD->new(1.50);
    isa_ok($dollar_n_half, 'Currency::USD');
    
    ok($buck_fifty == $dollar_n_half, '... these are equal');
    ok(1.75 > $buck_fifty, '... 1.75 is more than a buck fifty');    
    
    my $two_bits = Currency::USD->new(0.25);
    isa_ok($two_bits, 'Currency::USD');
    
    ok($two_bits < $dollar_n_half, '... 2 bits is less than a dollar and a half');
    ok($two_bits == 0.25, '... two bits is equal to 25 cents');
}

# now test the module as a whole ....

{
    package Number;
    our @ISA = ('Class::Comparable');
    sub new { bless { num => $_[1] } => $_[0] }
    
    sub compare {
        my ($left, $right, $is_reversed) = @_;
        ($left, $right) = ($right, $left) if $is_reversed;
        return $left->{num} <=> $right->{num};
    }
}
can_ok("Number", 'new');

{
    my $three = Number->new(3);
    isa_ok($three, 'Number');
    isa_ok($three, 'Class::Comparable');

    my $four = Number->new(4);
    isa_ok($four, 'Number');
    isa_ok($four, 'Class::Comparable');

    my $five = Number->new(5);    
    isa_ok($five, 'Number');
    isa_ok($five, 'Class::Comparable');    
    
    cmp_ok($three, '<',  $four,  '... three is less than four');
    cmp_ok($three, '<=', $three, '... three is less than or equal to three');
    cmp_ok($three, '<=', $four,  '... three is less than or equal to four');
    cmp_ok($three, '==', $three, '... three equals three');
    cmp_ok($three, '!=', $four,  '... three does not equal four');
    cmp_ok($three, '>=', $three, '... three is greater than or equal to three');
    cmp_ok($four,  '>=', $three, '... four is greater than or equal to three');    
    cmp_ok($four,  '>', $three,  '... four is greater than three'); 
    
    cmp_ok(($three <=> $three), '==',  0, '... three equals three');
    cmp_ok(($three <=> $four),  '==', -1, '... three less than four');
    cmp_ok(($four  <=> $three), '==',  1, '... four is greater than three');

    ok($three->equals($three), '... three equals three');    
    ok($three->notEquals($four), '... three not equal to four');  
    
    cmp_ok($three->compare($three), '==',  0, '... three equals three');
    cmp_ok($three->compare($four),  '==', -1, '... three less than four');
    cmp_ok($four->compare($three),  '==',  1, '... four is greater than three'); 
    
    ok($three->isBetween($three, $four), '... three is between three and four');    
    ok($four->isBetween($three, $five), '... four is between three and five');  
    ok($four->isBetween($three, $four), '... four is between three and four');  
    ok(!$three->isBetween($four, $five), '... three is not between four and five');  
    ok(!$five->isBetween($three, $four), '... five is not between three and four');  
           
    ok($three->isExactly($three), '... three is exactly three');
    ok(!$three->isExactly($four), '... three is not exactly four');                     
    
    ok(!$three->isExactly(), '... three is not exactly undef');                         
    ok(!$three->isExactly("Three"), '... three is not exactly "Three"');                         
    ok(!$three->isExactly([]), '... three is not exactly an array ref');                             
    ok(!$three->isExactly(bless({ num => 3}, 'NotNumber')), '... three is not exactly another object');                             

}

{
    package ReversalTest;
    our @ISA = ('Class::Comparable');
    
    sub new { bless { num => $_[1] } => $_[0] }  
    
    sub compare {
        my ($left, $right) = @_;
        return ($left->{num} <=> $right);
    }
      
}
can_ok('ReversalTest', 'new');
{
    my $t = ReversalTest->new(5);
    isa_ok($t, 'ReversalTest');
    
    ok((10 > $t), '... 10 is greater than 5');
    ok((1  < $t), '... 1 is less than 5');        

    ok(!(10 < $t), '... 10 is not less than 5');
    ok(!(1  > $t), '... 1 is not greater than 5'); 
      
    cmp_ok((5 <=> $t), '==', 0, '... 5 is equal to 5');    
          
}

{
    package String;
    our @ISA = ('Class::Comparable');
    use overload q|""| => sub { $_[0]->{num} };
    sub new { bless { num => $_[1] } => $_[0] }
}
can_ok("String", 'new');

{
    my $is = String->new("is");
    isa_ok($is, 'String');
    isa_ok($is, 'Class::Comparable');

    my $isnt = String->new("isnt");
    isa_ok($isnt, 'String');
    isa_ok($isnt, 'Class::Comparable');
        
    ok($is->isExactly($is), '... is is exactly is');
    ok(!$is->isExactly($isnt), '... is is not exactly isnt');                     
}

# now check the error

eval {
    Class::Comparable->compare();
};
like($@, qr/Method Not Implemented/, '... this is an abstract method');
