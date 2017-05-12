use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $slicer = new_ok($mod, [{
  config => {
    opt                 => 'main config val',
    'Plug.attr'         => 'pa',
    'Mod::Name.opt'     => 'val',
    'Moose.and[]'       => 'squirrel',
    'BigMoose.and'      => 'little squirrel',
    'Hunting.season[0]' => 'duck',
    'Hunting.season[1]' => 'wabbit',
    'Hunting.season[9]' => 'fudd',
    # keys are sorted very simply (alphabetically)
    'Hunting2.season[1.09]' => 'bunny',
    'Hunting2.season[1.10]' => 'bird',
    'Hunting2.season[1.08]' => 'wabbit',
    'Hunting2.season[1.11]' => 'duck',
    'Hunting2.season[z]' => 'zombie',
    'Hunting3.season' => 'fudd',
    'BadPlug.foo'       => 'bar',
  },
}]);

# TODO: should we allow updating of non-Moose plugins?  just overwrite the blessed hash?

{ package # no_index
    Config::MVP::Slicer::Test::Role::Plugin;
  use Moose;
  has plugin_name => ( is => 'ro', isa => 'Str', init_arg => 'name' );
}
foreach my $spec (
  [qw( X::Plug    attr   Str )],
  [qw( Mod::Name  opt    Str )],
  [qw( X::Hunting season ArrayRef[Str] )],
  [qw( X::Moose   and    Any )],
){
  my ($pack, $attr, $type) = @$spec;
  eval "{ package $pack; use Moose;" .
  "has plugin_name => ( is => 'ro', isa => 'Str', init_arg => 'name' );" .
  "has $attr => ( is => 'rw', isa => '$type' ); }; 1"
    or die $@;
}

is_deeply
  $slicer->merge(X::Plug->new({name => 'Plug'})),
  X::Plug->new({name => 'Plug', attr => 'pa' }),
  'merge previously unassigned attribute into plugin based on name';

my $previous = Mod::Name->new({name => 'ModName', previous => 'config'});
my $exp = Mod::Name->new({name => 'ModName', previous => 'config', opt => 'val'});
is_deeply
  $slicer->merge($previous),
  $exp,
  'merge previously unassigned attribute into plugin based on package';

is_deeply
  $previous,
  $exp,
  'merge modifies object';

is_deeply
  $slicer->merge(X::Moose->new({name => 'Moose'})),
  X::Moose->new({name => Moose => and => [qw(squirrel)] }),
  'set as arrayref when specified as []';

is_deeply
  $slicer->merge(X::Moose->new({name => Moose => and => 'cow'})),
  X::Moose->new({name => Moose => and => [qw(cow squirrel)] }),
  'convert previous string to array ref when specified as []';

is_deeply
  $slicer->merge(X::Moose->new({name => BigMoose => and => ['cow']})),
  X::Moose->new({name => BigMoose => and => ['cow', 'little squirrel'] }),
  'merged array ref when previous value was arrayref';

is_deeply
  $slicer->merge(X::Moose->new({name => BigMoose => and => 'mouse' })),
  X::Moose->new({name => BigMoose => and => 'little squirrel'}),
  'overwrite when neither is arrayref';

is_deeply
  $slicer->merge(X::Hunting->new({name => Hunting => -shot => 'gun', season => ['looney'] })),
  X::Hunting->new({name => Hunting => -shot => 'gun', season => [qw(looney duck wabbit fudd)] }),
  'merge array ref';

is_deeply
  $slicer->merge(X::Hunting->new({name => Hunting2 => -shot => 'gun', season => ['looney'] })),
  X::Hunting->new({name => Hunting2 => -shot => 'gun', season => [qw(looney wabbit bunny bird duck zombie)] }),
  'merged arrayref in order';

is_deeply
  $slicer->merge(X::Hunting->new({name => 'Hunting3'})),
  X::Hunting->new({name => Hunting3 => season => ['fudd'] }),
  'assigned as arrayref because attribute is typed as such';

is_deeply
  $slicer->merge(X::Plug->new({ name => Plug => attr => 'ibute' })),
  X::Plug->new({ name => Plug => attr => 'pa' }),
  'overwrite Str attribute';

like
  exception { $slicer->merge(X::Plug->new({name => 'BadPlug'})) },
  qr/not found/,
  'croaked on invalid attribute';

done_testing;
