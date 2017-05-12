use Test::More tests => 9;

use Fcntl qw/ :flock /;
use File::Temp qw/ tempfile tempdir /;

BEGIN {
  use_ok( 'Bot::Cobalt::Serializer' );
}

my $hash = {
  Scalar => "A string",
  Int => 3,
  Array => [ qw/Two Items/ ],
  Hash  => { Some => { Deep => 'Hash' } },
  Unicode => "\x{263A}",
};

JSONRW: {
  my $js_ser = Bot::Cobalt::Serializer->new( 'JSON' );
  can_ok($js_ser, 'readfile', 'writefile' );

  my ($fh, $fname) = _newtemp();
  ok( $js_ser->writefile($fname, $hash), 'JSON file write');
  
  my $jsref;
  ok( $jsref = $js_ser->readfile($fname), 'JSON file read');
  
  is_deeply($hash, $jsref, 'JSON file read-write compare' );
}

YAMLRW: {
  my $yml_ser = Bot::Cobalt::Serializer->new();
  can_ok($yml_ser, 'readfile', 'writefile' );

  my ($fh, $fname) = _newtemp();
  ok( $yml_ser->writefile($fname, $hash), 'YAML file write');
  
  my $ymlref;
  ok( $ymlref = $yml_ser->readfile($fname), 'YAML file read');
  
  is_deeply($hash, $ymlref, 'YAML file read-write compare' );
}

sub _newtemp {
    my ($fh, $filename) = tempfile( 'tmpdbXXXXX', 
      DIR => tempdir( CLEANUP => 1 ), UNLINK => 1
    );
    flock $fh, LOCK_UN;
    return($fh, $filename)
}
