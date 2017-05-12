
use strict;
use warnings;

use Collision::2D ':all';

use Test::More tests => 4;
#use Test::Number::Delta;
use Data::Dumper;
{
   my $death_cube = hash2rect { x=>-3, y=>0, h=>2,w=>2, xv=>1};
   my $hans = hash2rect {x=>0, y=>0, h=>2, w=>2};
   my $collision = Collision::2D::Collision->new(
      ent1=>$death_cube,
      ent2=>$hans,
      time=>1,
      axis=>'x',
   );
   
   is ($collision->ent1->x, -3);
   is ($collision->ent1->h, 2);
   is ($collision->ent1->h, 2);
   is ($collision->ent1->h, 2);
}
