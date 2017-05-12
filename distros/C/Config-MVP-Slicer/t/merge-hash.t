use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $slicer = new_ok($mod, [{
  config => {
    opt                 => 'main config val',
    'Plug.attr'         => 'pa',
    'Mod::Name.opt'     => 'val',
    'Moose.and[]'       => 'squirrel',
    'Hunting.season[0]' => 'duck',
    'Hunting.season[1]' => 'wabbit',
    'Hunting.season[9]' => 'fudd',
    # keys are sorted very simply (alphabetically)
    'Hunting2.season[1.09]' => 'bunny',
    'Hunting2.season[1.10]' => 'bird',
    'Hunting2.season[1.08]' => 'wabbit',
    'Hunting2.season[1.11]' => 'duck',
    'Hunting2.season[z]' => 'zombie',
  },
}]);

is_deeply
  $slicer->merge([Plug => 'X::Plug' => {}]),
  [Plug => 'X::Plug' => { attr => 'pa' }],
  'merge to empty hash';

my $previous = { previous => 'config' };
is_deeply
  $slicer->merge([ModName => 'Mod::Name' => $previous ])->[2],
  { previous => 'config', opt => 'val' },
  'matches on class name';

is_deeply
  $previous,
  { previous => 'config', opt => 'val' },
  'merge overwrites hash';

is_deeply
  $slicer->merge([Moose => Moose => { and => [qw(cow)] }])->[2],
  { and => [qw(cow squirrel)] },
  'merged array ref when specified as []';

is_deeply
  $slicer->merge([Hunting => 'X::Hunting' => { -shot => 'gun', season => 'looney' }])->[2],
  { -shot => 'gun', season => [qw(looney duck wabbit fudd)] },
  'convert previous string to array ref as specified';

is_deeply
  $slicer->merge([Hunting2 => 'X::Hunting' => { -shot => 'gun', season => ['looney'] }])->[2],
  { -shot => 'gun', season => [qw(looney wabbit bunny bird duck zombie)] },
  'merge arrayref in order';

is_deeply
  $slicer->merge([Plug => 'X::Plug' => { attr => [qw(ibute)] }])->[2],
  { attr => [qw(ibute pa)] },
  'merged array ref when previous value was arrayref';

is_deeply
  $slicer->merge([Plug => 'X::Plug' => { attr => 'ibute' }])->[2],
  { attr => 'pa' },
  'overwrite when neither is arrayref';

is_deeply
  $slicer->merge([Plug => 'X::Plug' => { attr => 'ibute' }],
    {slice => {attr => 'x'}})->[2],
  { attr => 'x' },
  'overwrite with passed in slice';

is_deeply
  $slicer->merge([Hunting2 => 'X::Hunting' => { -shot => 'gun', season => ['looney'] }],
    {slice => {season => [qw(tunes party)]}})->[2],
  { -shot => 'gun', season => [qw(looney tunes party)] },
  'merge arrayref with passed in slice';

done_testing;
