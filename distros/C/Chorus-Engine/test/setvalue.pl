use strict;
use Chorus::Frame;

use Data::Dumper;

my $f1 = Chorus::Frame->new(
          b => {
        	  _DEFAULT => 'inheritated default value for b'
          }	
        );

my $f2 = Chorus::Frame->new(
                   ID => 'FRAME F2 !!', 
                   a => {
                     b1 => sub { $SELF->get('a b2') },
                     b2 => {
        	              	  _ISA    => $f1->{b},
        	              	  _NEEDED => 'needed for b' # (needs mode Z)
        	               }
                   },     
        );
                    
Chorus::Frame::setMode(GET => 'N');
print $f2->get('a b1') . "\n"; # will print 'inheritated default value for b'

$f1->set('b _BEFORE', sub { print "F1 BEFORE .. " . $SELF->ID . "\n"});
$f2->set('a b2', 'aaaa');
# WORKS !!!