#!perl -T

use Test::More tests => 2;

BEGIN {
}

use strict;
use Chorus::Frame;

diag( "Testing Chorus::Frame::getZ and getN $Chorus::Frame::VERSION, Perl $], $^X" );


my $f1 = Chorus::Frame->new(
          b => {
        	  _DEFAULT => 'inherited default value for b'
          }	
);

my $f2 = Chorus::Frame->new(
                   a => { 
                     b1 => sub { $SELF->get('a b2') },    # $SELF is the current context
                     b2 => {
        	              	  _ISA    => $f1->{b},
        	              	  _NEEDED => 'needed for b'   # needs mode Z to preceed inheritated _DEFAULT
        	               }
                   },     
        );
                    
Chorus::Frame::setMode(GET => 'N');
is($f2->get('a b1'), 'inherited default value for b', 'Test 1');

Chorus::Frame::setMode(GET => 'Z'); # DEFAULT
is($f2->get('a b1'), 'needed for b', 'Test 2');

done_testing();
