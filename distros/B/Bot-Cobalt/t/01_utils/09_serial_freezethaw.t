use Test::More tests => 13;

use Encode;

BEGIN {
  use_ok( 'Bot::Cobalt::Serializer' );
}

new_ok( 'Bot::Cobalt::Serializer' => [ Format => 'JSON' ] );
new_ok( 'Bot::Cobalt::Serializer' );

my $str = "a\372\360b";
my $hash = {
  Scalar => "A string",
  Int => 3,
  Array => [ qw/Two Items/ ],
  Hash  => { Some => { Deep => 'Hash' } },
  Decoded => $str,
  Encoded => encode('utf8', $str),
};

## JSON and YAMLXS (default) are the only ones we use in core

JSON: {
  my $js_ser = new_ok( 'Bot::Cobalt::Serializer' => [ 'JSON' ] );
  can_ok($js_ser, 'freeze', 'thaw');
  my $json = $js_ser->freeze($hash);
  ok( $json, 'JSON freeze');

  my $json_thawed = $js_ser->thaw($json);
  ok( $json_thawed, 'JSON thaw');

  is_deeply($hash, $json_thawed, 'JSON comparison' );
}

YAML: {
  my $yml_ser = new_ok( 'Bot::Cobalt::Serializer' );
  can_ok($yml_ser, 'freeze', 'thaw');
  my $yml = $yml_ser->freeze($hash);
  ok( $yml, 'YAML freeze');

  my $yml_thawed = $yml_ser->thaw($yml);
  ok( $yml_thawed, 'YAML thaw');

  is_deeply($hash, $yml_thawed, 'YAML comparison' );
}
