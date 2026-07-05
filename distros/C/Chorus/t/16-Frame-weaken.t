#!perl -T

use Test::More tests => 1;

use strict;
use Chorus::Frame; # qw(%FMAP);

diag( "Testing Chorus::Frame WEAKEN $Chorus::Frame::VERSION, Perl $], $^X" );

  
sub set_weak_frame {
	
  my $f = Chorus::Frame->new(
      WEAK_FRAME => 'Y' 
  );
  
}

sub test_weaken {
  set_weak_frame();
  return undef if fmatch(slot => 'WEAK_FRAME');
  return 1; 
}

ok(test_weaken, 'test weaken');
done_testing();


