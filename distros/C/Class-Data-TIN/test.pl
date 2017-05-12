#!/usr/bin/perl

use Test::Simple tests=>48;

# create test objects & data structs
package CDT_Top;
use Class::Data::TIN qw(get set append);
our $tin=Class::Data::TIN->new(__PACKAGE__,
		      {
		       string=>"a string",
		       string2=>"another string",
		       array=>['foo','bar'],
		       hash=>{
			      foo=>'bar',
			      jaja=>'neinein',
			     },
		       code=>sub{return "bla"}
		      });
#our $tin=Class::Data::TIN->new(__PACKAGE__,{require_file=>'./muni.cfg'});

sub new {
   return bless {},shift;
}

package CDT_Top::Sub1;
@ISA=('CDT_Top');
our $tin_sub1=Class::Data::TIN->new(__PACKAGE__);

package CDT_Top::Sub2;
@ISA=('CDT_Top');
our $tin_sub2=Class::Data::TIN->new(__PACKAGE__);

# start tests
package main;
my $top=CDT_Top->new;
my $sub1=CDT_Top::Sub1->new;
my $sub2=CDT_Top::Sub2->new;

print "testing 'get'\n";
ok($top->get('string') eq "a string");
ok(ref($top->get('array')) eq "ARRAY");
ok(@{$top->get('array')} ==2);
ok(ref($top->get('hash')) eq "HASH");
ok(keys %{$top->get('hash')} ==2);
ok(values %{$top->get('hash')} ==2);
ok(ref($top->get('code')) eq "CODE");
ok(&{$top->get('code')} eq "bla");

print "and now in child\n";
ok($sub1->get('string') eq "a string");
ok(ref($sub1->get('array')) eq "ARRAY");
ok(@{$sub1->get('array')} ==2);
ok(ref($sub1->get('hash')) eq "HASH");
ok(keys %{$sub1->get('hash')} ==2);
ok(values %{$sub1->get('hash')} ==2);
ok(ref($sub1->get('code')) eq "CODE");
ok(&{$sub1->get('code')} eq "bla");


print "testing 'set'\n";
$tin->set('newstring',"one more string");
ok($top->get('newstring') eq "one more string");
ok($sub1->get('newstring') eq "one more string");
ok($sub2->get('newstring') eq "one more string");

$tin_sub1->set('subnewstring',"and another one");
ok($sub1->get('subnewstring') eq "and another one");
ok($top->get('subnewstring') eq undef);
ok($sub2->get('subnewstring') eq undef);

print "testing 'append' on string\n";
$tin->append('string'," or two");
ok($top->get('string') eq "a string or two");
ok($sub1->get('string') eq "a string or two");

$tin_sub1->append('string'," or n");
ok($sub1->get('string') eq "a string or two or n");
ok($top->get('string') eq "a string or two");
ok($sub2->get('string') eq "a string or two");

print "testing 'append' on array\n";
$tin->append('array',"baz");
ok(@{$top->get('array')} ==3);
ok(@{$sub1->get('array')} ==3);
$tin_sub1->append('array',"fuu");
ok(@{$top->get('array')} ==3);
ok(@{$sub2->get('array')} ==3);
ok(@{$sub1->get('array')} ==4);

print "testing 'append' on hash\n";
$tin->append('hash',"baz","fuu");
ok(keys %{$top->get('hash')} ==3);
ok(values %{$top->get('hash')} ==3);
ok(keys %{$sub1->get('hash')} ==3);
ok(values %{$sub1->get('hash')} ==3);

$tin_sub1->append('hash',"noch","was");
ok(keys %{$top->get('hash')} ==3);
ok(values %{$top->get('hash')} ==3);
ok(keys %{$sub1->get('hash')} ==4);
ok(values %{$sub1->get('hash')} ==4);

print "testing 'append' on empty val\n";
ok($tin->get('newthing') == undef);
$tin->append('newthing',"hey I exist");
ok($tin->get('newthing') eq "hey I exist");

print "testing object invocation\n";
undef $@;
eval {
   $top->set('false','this must crash');
};
ok(defined $@);

print "testing nested data structures\n";
$tin->set('complex',{var1=>[a,b,c],var2=>[d,e,f]});
ok($tin->get('complex')->{var1}->[2] eq "c");

$tin_sub1->append('complex',var3,[g,h,i]);
ok($tin_sub1->get('complex')->{var3}->[1] eq "h");

$tin_sub2->append('complex',var1,[j,k,l]);
ok($tin->get('complex')->{var1}->[2] eq "c");
ok($tin_sub1->get('complex')->{var1}->[2] eq "c");
ok($tin_sub2->get('complex')->{var1}->[2] eq "l");

1;

























