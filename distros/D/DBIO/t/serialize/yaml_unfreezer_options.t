use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  eval { require YAML; 1 } or plan skip_all => 'YAML not installed';
}

use DBIO::InflateColumn::Serializer::YAML;

# The YAML serializer (karr k393) loads a stored value as plain data: no
# blessed objects and no code, whatever the process-wide $YAML::LoadBlessed
# and $YAML::LoadCode say.

my $unfreeze = DBIO::InflateColumn::Serializer::YAML->get_unfreezer;

{
  local $YAML::LoadBlessed = 1;
  local $YAML::LoadCode    = 1;

  my $data = $unfreeze->("--- !!perl/hash:Some::Class\na: 1\n");
  is ref($data), 'HASH', 'a blessed value comes back as a plain hash';
  is $data->{a}, 1, 'with its data';

  my $code = eval { $unfreeze->("--- !!perl/code '{ 42 }'\n") };
  my $ran = ref($code) eq 'CODE' ? $code->() : undef;
  ok !(defined $ran && $ran == 42), 'a code value does not come back as the stored code';
}

{
  local $YAML::LoadBlessed = 1;
  $unfreeze->("--- 1\n");
  is $YAML::LoadBlessed, 1, 'the setting is local to the unfreezer';
}

my $plain = $unfreeze->(YAML::Dump({ x => [ 1, 2 ] }));
is_deeply $plain, { x => [ 1, 2 ] }, 'plain structures roundtrip';

done_testing;
