use strict;
use warnings;
use Path::Tiny ();

exec $^X,
  '-I' => Path::Tiny->new('lib'),
  Path::Tiny->new( bin => 'wallflower' ),
  '--application' => Path::Tiny->new( t => 'rand.psgi' ),
  '--parallel'    => 2,
  '--tap',
  ;
