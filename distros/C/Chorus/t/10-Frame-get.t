#!perl -T

use Test::More tests => 4;

BEGIN {
}

use Chorus::Frame;

diag( "Testing Chorus::Frame::get $Chorus::Frame::VERSION, Perl $], $^X" );

my $res;

sub test_NEEDED_inherited {
	
   my $f1 = Chorus::Frame->new (
    val => {
 	 _DEFAULT => "DEFAULT FROM F1"
    }
  );

  my $f2 = Chorus::Frame->new (
    _ISA => $f1,
    val => { 
    	_NEEDED => "NEEDED FROM F2"
    }
  );

  my $f3 = Chorus::Frame->new (
    _ISA => $f2,
  );
  
  $res = $f3->val; 

}

sub test_DEFAULT_inherited {
   my $f1 = Chorus::Frame->new (
    val => {
 	 _DEFAULT => "DEFAULT FROM F1"
    }
  );

  my $f2 = Chorus::Frame->new (
    _ISA => $f1,
    val => {
 	 _DEFAULT => "DEFAULT FROM F2"
    }
  );

  my $f3 = Chorus::Frame->new (
    _ISA => $f2,
  );

  $res = $f3->val; 
}

sub test_MULTIPLE_inheritance_N {

   my $f1 = Chorus::Frame->new (
    val => {
 	 _NEEDED => "NEEDED FROM F1"
    }
  );

   my $f2 = Chorus::Frame->new (
    val => {
 	 _NEEDED => "NEEDED FROM F2"
    }
  );

  my $f3 = Chorus::Frame->new (
    _ISA => $f1,
    val => {
 	 _DEFAULT => "DEFAULT FROM F3"
    }
  );

  my $f4 = Chorus::Frame->new (
    _ISA => $f2,
  );

  $f4->_inherits($f3);        
  
  $res = $f4->val; 
}

sub test_MULTIPLE_inheritance_Z {

   setMode 'Z';
   
   my $f1 = Chorus::Frame->new (
    val => {
 	 _NEEDED => "NEEDED FROM F1"
    }
  );

   my $f2 = Chorus::Frame->new (
    val => {
 	 _NEEDED => "NEEDED FROM F2"
    }
  );

  my $f3 = Chorus::Frame->new (
    _ISA => $f1,
    val => {
 	 _DEFAULT => "DEFAULT FROM F3"
    }
  );

  my $f4 = Chorus::Frame->new (
    _ISA => $f2,
  );

  $f4->_inherits($f3);        
  
  $res = $f4->val; 
}

# --

test_NEEDED_inherited();
is ($res, 'NEEDED FROM F2' ,'TEST 1');

test_DEFAULT_inherited();
is ($res, 'DEFAULT FROM F2', 'TEST 2');

test_MULTIPLE_inheritance_N();
is ($res, 'NEEDED FROM F2', 'TEST 3');

test_MULTIPLE_inheritance_Z();
is ($res, 'DEFAULT FROM F3', 'TEST 4');

done_testing();
