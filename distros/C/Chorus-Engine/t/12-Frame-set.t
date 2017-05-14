#!perl -T

use Test::More tests => 2;
use Chorus::Frame;

diag( "Testing Chorus::Frame::set $Chorus::Frame::VERSION, Perl $], $^X" );

my ($before, $after);

sub test_BEFORE_AFTER {
	
   my $f1 = Chorus::Frame->new (
    val => {
 	 _BEFORE => sub { 
 	 	    $SELF->set('BEFORE', "BEFORE FROM F1") 
 	  },
 	  
 	 _AFTER => sub { 
 	 	$SELF->set('AFTER', "AFTER FROM F1") 
 	  }
    }
  );

  my $f2 = Chorus::Frame->new (
    val => { 
     _ISA => $f1->{val},
 	 _AFTER => sub {
 	 	$SELF->set('AFTER', "AFTER FROM F2") 
 	 }
    }
  );

  my $f3 = Chorus::Frame->new (
    val => {
      _ISA  => $f2->{val},
      _VALUE => 'current VALUE'	
    }
  );
  
  $f3->set('val', 'something');
  
  $before = $f3->BEFORE; 
  $after  = $f3->AFTER; 
}

# --

test_BEFORE_AFTER();

is($before, 'BEFORE FROM F1', 'TESTING BEFORE');
is($after, 'AFTER FROM F2', 'TESTING AFTER');

done_testing();


