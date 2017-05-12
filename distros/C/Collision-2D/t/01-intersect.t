use strict;
use warnings;

use Collision::2D ':all';

use Test::More  tests => 21;

#circle-rect
{
   my $pie = hash2circle {x=>-1, y=> -4, radius=> 2*sqrt(2)}; #motionless
   ok ($pie->intersect_rect (hash2rect({x=>-1, y=> -4, w=>3, h=>2 }) ), 'explicit case');
   
   #corner cases
   ok ($pie->intersect_rect (hash2rect({x=>-5.99, y=> -8, w=>3, h=>2 }) ), 'hit');
   ok (!$pie->intersect_rect (hash2rect({x=>-6.01, y=> -8, w=>3, h=>2 }) ), 'miss');
   
   ok ($pie->intersect_rect (hash2rect({x=>.99, y=> -8, w=>3, h=>2 }) ), 'hit');
   ok (!$pie->intersect_rect (hash2rect({x=>1.01, y=> -8, w=>3, h=>2 }) ), 'miss');
   
   ok ($pie->intersect_rect (hash2rect({x=>-5.99, y=> -2, w=>3, h=>2 }) ), 'hit');
   ok (!$pie->intersect_rect (hash2rect({x=>-6.01, y=> -2, w=>3, h=>2 }) ), 'miss');
   
   ok ($pie->intersect_rect (hash2rect({x=>.99, y=> -2, w=>3, h=>2 }) ), 'hit');
   ok (!$pie->intersect_rect (hash2rect({x=>1.01, y=> -2, w=>3, h=>2 }) ), 'miss');
   
   
   #edge cases
   my $pie2 = hash2circle {x=>-1, y=> -2, radius=>1}; #motionless
   ok ($pie2->intersect_rect (hash2rect({x=>-.01, y=> -8, w=>3, h=>16 }) ), 'edge hit');
   ok (!$pie2->intersect_rect (hash2rect({x=>.01, y=> -8, w=>3, h=>16 }) ), 'edge miss');
   
   ok ($pie2->intersect_rect (hash2rect({x=>-4.99, y=> -8, w=>3, h=>16 }) ), 'edge hit');
   ok (!$pie2->intersect_rect (hash2rect({x=>-5.01, y=> -8, w=>3, h=>16 }) ), 'edge miss');
   
   #x<->y
   my $pie3 = hash2circle {y=>-1, x=> -2, radius=>1}; #motionless
   ok ($pie3->intersect_rect (hash2rect({y=>-.01, x=> -8, h=>3, w=>16 }) ), 'edge hit');
   ok (!$pie3->intersect_rect (hash2rect({y=>.01, x=> -8, h=>3, w=>16 }) ), 'edge miss');
   
   ok ($pie3->intersect_rect (hash2rect({y=>-4.99, x=> -8, h=>3, w=>16 }) ), 'edge hit');
   ok (!$pie3->intersect_rect (hash2rect({y=>-5.01, x=> -8, h=>3, w=>16 }) ), 'edge miss');
   
   
}

#circle-circle
{
   my $pie = hash2circle {x=>1, y=> -4, radius=> sqrt(2)/2}; 
   my $pie_in = hash2circle {x=>0.01, y=> -5, radius=> sqrt(2)/2};
   my $pie_out = hash2circle {x=>-0.01, y=> -5, radius=> sqrt(2)/2};
   
   ok ($pie->intersect ($pie_in));
   ok (!$pie->intersect ($pie_out));
   ok ($pie->intersect ($pie_in, $pie_out));
   ok ($pie->intersect ($pie_out, $pie_in));
}

