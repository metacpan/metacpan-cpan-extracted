#!/usr/bin/perl -w
use strict;
use Test::More tests=>85;  #qw(no_plan); #

BEGIN { use_ok( 'Class::Data::TIN' ); }
require_ok( 'Class::Data::TIN' );



# create test objects & data structs
package A;
use Class::Data::TIN qw(get_classdata set_classdata append_classdata merge_classdata);
our $a=Class::Data::TIN->new
  (__PACKAGE__,
   {
    string=>"a string",
    string2=>"another string",
    array=>['foo','bar'],
    hash=>{
	   foo=>'foo',
	   bar=>'bar',
	  },
    code=>sub{return "bla"}
   });


sub new { return bless {},shift }


package A::A;
our @ISA=('A');
our $a_a=Class::Data::TIN->new(__PACKAGE__);
$a_a->merge_classdata
  ({
    string=>" longer",
    array=>['blu'],
    hash=>{
	   foo=>'FOO',
	   blu=>'blu',
	  },

   });


package A::B;
our @ISA=('A');
our $a_b=Class::Data::TIN->new(__PACKAGE__);
$a_b->merge_classdata
  ({
    string=>" bb",
    array=>['blb'],
    hash=>{
	   foo=>'oof',
	  },

   });



package C;
use Class::Data::TIN qw(get_classdata set_classdata append_classdata merge_classdata);

our $c=Class::Data::TIN->new
  (__PACKAGE__,
   {
    string=>"gnirts",
    array=>['oof','rab'],
    hash=>{
	   oof=>'oof',
	   rab=>'rab',
	   foo=>'FOOBB',
	  },
    code=>sub{return "blu"}
   });

sub new { return bless {},shift }

package C::C;
our @ISA=('C');
our $c_c=Class::Data::TIN->new(__PACKAGE__);
$c_c->merge_classdata
  ({
    string=>" regonl",
    array=>['xxx'],
    hash=>{
	   xxx=>'xxx',
	   rab=>'RAB',
	  },

   });


package testing;
our @ISA=('A::A','C::C');
our $tin=Class::Data::TIN->new(__PACKAGE__);
$tin->merge_classdata
({
  string=>' test',
  array=>['test'],
  hash=>{
	 test=>'Test',
	}  
});

# start tests
package main;

my $t=testing->new;
my $ta=A->new;
my $ta_a=A::A->new;
my $ta_b=A::B->new;
my $tc=C->new;
my $tc_c=C::C->new;

$\="\n";


print "testing 'set_classdata' on empty val";
$t->set_classdata('string3','neu');
is($t->get_classdata('string3'),'neu');
is($a->get_classdata('string3'),undef);

print "testing 'get_classdata' on string";
is($t->get_classdata('string'),"gnirts regonla string longer test");
is($ta->get_classdata('string'),"a string");
is($ta_a->get_classdata('string'),"a string longer");
is($ta_b->get_classdata('string'),"a string bb");
is($tc->get_classdata('string'),"gnirts");
is($tc_c->get_classdata('string'),"gnirts regonl");

print "testing 'append_classdata' and 'set_classdata' on string";
$t->set_classdata('string','');
is($t->get_classdata('string'),'gnirts regonla string longer');
$t->set_classdata('string',' test');   # restore old value..
$ta_a->append_classdata('string',' neu');
is($ta_a->get_classdata('string'),'a string longer neu');
is($t->get_classdata('string'),"gnirts regonla string longer neu test");
$tc->set_classdata('string','blank');
is($tc->get_classdata('string'),'blank');
is($ta_a->get_classdata('string'),'a string longer neu');
is($t->get_classdata('string'),"blank regonla string longer neu test");
$c->append_classdata('string',', or is it');
is($tc_c->get_classdata('string'),"blank, or is it regonl");

print "testing 'merge_classdata' on strings";
$tc_c->merge_classdata({
		       string=>\ 'longer',
		       string2=>'yas',
		      });

is($tc_c->get_classdata('string'),'longer');
is($tc_c->get_classdata('string2'),'yas');
is($t->get_classdata('string'),'longera string longer neu test');
is($t->get_classdata('string2'),'yasanother string');

print "testing 'tinstop' on strings";
$t->set_classdata('string','using tinstop',1);
is($t->get_classdata('string'),'using tinstop');
$t->set_classdata('string2','end',1);
is($t->get_classdata('string2'),'end');
is($tc_c->get_classdata('string2'),'yas');
is($ta->get_classdata('string2'),'another string');
$t->set_classdata('string2','end');
is($t->get_classdata('string2'),'yasanother stringend');

$a_a->append_classdata('string',' appended',1);
is($a_a->get_classdata('string'),' longer neu appended');


print "testing stop with scalar ref (this feature might be removed..)";
$t->set_classdata('string','mal schaun');
$t->set_classdata('string',\ 'stopit');
is($t->get_classdata('string'),'stopit');
is($a_a->get_classdata('string'),' longer neu appended');
$t->set_classdata('string','stopit');
is($t->get_classdata('string'),' longer neu appendedstopit');


print "testing 'get_classdata' on array";
is(@{$t->get_classdata('array')},7);
is($t->get_classdata('array')->[3],'foo');
is(@{$ta_b->get_classdata('array')},3);
is($ta_b->get_classdata('array')->[2],'blb');

print "testing 'append_classdata' and 'set_classdata' on array";
$tc_c->set_classdata('array',['XXX']);
is($tc_c->get_classdata('array')->[2],'XXX');
is($t->get_classdata('array')->[2],'XXX');
is($t->get_classdata('array')->[3],'foo');
$tc_c->append_classdata('array',['YYY','ZZZ']);
is($tc_c->get_classdata('array')->[2],'XXX');
is($t->get_classdata('array')->[5],'foo');

print "testing 'merge_classdata' on array";
$ta_a->merge_classdata
  ({
    array=>['baz','zab'],
    array2=>[1..9],
   });
is(@{$t->get_classdata('array')},11);
is($t->get_classdata('array')->[8],'baz');
is($t->get_classdata('array2')->[7],8);


print "testing 'tinstop' on array";
is($t->get_classdata('array')->[10],'test');
$ta->set_classdata('array',['reset'],1);
is($t->get_classdata('array')->[4],'test');
$t->append_classdata('array',['test2','test3']);
is($t->get_classdata('array')->[6],'test3');

$t->append_classdata('array',['test4'],1);
is($t->get_classdata('array')->[3],'test4');
$t->append_classdata('array',['test5'],-1);
$ta->append_classdata('array',['doch'],-1);
is($t->get_classdata('array')->[10],'test');
is($t->get_classdata('array')->[14],'test5');

$ta_a->merge_classdata
  ({
    array=>['_tinstop',['ulb']],
   });
is($t->get_classdata('array')->[3],'ulb');
$ta_a->set_classdata('array',['blu','baz']);
is($t->get_classdata('array')->[7],'blu');


print "testing 'get_classdata' on hash";
my $h=$t->get_classdata('hash');
is($t->get_classdata('hash')->{'foo'},'FOO');
is($tc_c->get_classdata('hash')->{'foo'},'FOOBB');
is($ta->get_classdata('hash')->{'test'},undef);

print "testing 'append_classdata' and 'set_classdata' on hash";
$t->set_classdata('hash',{test2=>'test2'});
is($ta->get_classdata('hash')->{'test'},undef);
is($t->get_classdata('hash')->{'test'},undef);
is($t->get_classdata('hash')->{'test2'},'test2');
$t->append_classdata('hash',{test=>'test'});
is($t->get_classdata('hash')->{'test'},'test');
is($t->get_classdata('hash')->{'test2'},'test2');
is($t->get_classdata('hash')->{'rab'},'RAB');
$ta_a->append_classdata('hash',{del=>'it'},1);
is($ta_a->get_classdata('hash')->{'del'},'it');
is($t->get_classdata('hash')->{'del'},'it');
is($t->get_classdata('hash')->{'rab'},undef);
$ta_a->set_classdata('hash',{undel=>'it'},-1);
is($t->get_classdata('hash')->{'rab'},'RAB');

print "testing 'merge_classdata' on hash";
$ta_a->merge_classdata
  ({
    hash=>{bla=>'Bla!',
	   blu=>'Blu!',
	   foo=>'Foo!',
	  },
    hash2=>{foo=>'FOO2!!!',
	    bar=>'BAR2!!!',
	    },
   });
is($t->get_classdata('hash')->{'bla'},'Bla!');
is($t->get_classdata('hash')->{'foo'},'Foo!');
is($ta->get_classdata('hash')->{'foo'},'foo');
is($t->get_classdata('hash2')->{'foo'},'FOO2!!!');
is($ta->get_classdata('hash2'),undef);

print "testing 'tinstop' on hash";
$t->set_classdata('hash',['_tinstop',{undel=>'it'}]);
is($t->get_classdata('hash')->{'foo'},undef);
is($t->get_classdata('hash')->{'undel'},'it');
$t->append_classdata('hash',{test=>'test'});
is($t->get_classdata('hash')->{'foo'},undef);
$t->append_classdata('hash',{test=>'test2'},-1);
is($t->get_classdata('hash')->{'foo'},'Foo!');
is($t->get_classdata('hash')->{'test'},'test2');

print "testing on coderef";
is(ref($t->get_classdata('code')),"CODE");
is(&{$t->get_classdata('code')},"bla");
is(&{$tc->get_classdata('code')},"blu");
$ta_a->set_classdata('code',sub{return 'new'});
is(&{$t->get_classdata('code')},"new");
is(&{$ta->get_classdata('code')},"bla");

print "testing nested data structures";
$ta->set_classdata('complex',{var1=>['a','b','c'],var2=>['d','e','f']});
is($ta->get_classdata('complex')->{'var1'}->[2],"c");
is($t->get_classdata('complex')->{'var1'}->[2],"c");

$t->append_classdata('complex',{var3=>['g','h','i']});
$t->append_classdata('complex',{var1=>['g','h','i']});
is($t->get_classdata('complex')->{'var3'}->[1],"h");
is($t->get_classdata('complex')->{'var1'}->[2],"i");


$tc->append_classdata('complex',{var1=>['j','k','l']});
is($t->get_classdata('complex')->{var1}->[2],"i");
is($tc->get_classdata('complex')->{var1}->[2],"l");
is($ta->get_classdata('complex')->{var1}->[2],"c");







