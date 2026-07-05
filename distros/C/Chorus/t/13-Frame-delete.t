#!perl -T

use Test::More tests => 2;

BEGIN {
}

use strict;
use Chorus::Frame;

diag( "Testing Chorus::Frame::delete $Chorus::Frame::VERSION, Perl $], $^X" );


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


$f2->set('a foo', 'foo');
is($f2->get('a foo'), 'foo', 'Test 1');

$f2->delete('a foo');
is($f2->get('a foo'), undef, 'Test 2');

done_testing();
