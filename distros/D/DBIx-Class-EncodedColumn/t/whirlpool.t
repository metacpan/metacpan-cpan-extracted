use strict;
use warnings;
use Test::More;

use Dir::Self;
use File::Spec;
use File::Temp 'tempdir';
use lib File::Spec->catdir(__DIR__, 'lib');
use DigestTest::Schema;

BEGIN {
  if( eval 'require Digest; 1' && eval 'require Digest::Whirlpool; 1' ){
    plan tests => 7;
  } else {
    plan skip_all => 'Digest::Whirlpool not available';
    exit;
  }
}

#1
DigestTest::Schema->load_classes('Whirlpool');

my $tmp = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile($tmp, 'testdb.sqlite');
my $schema = DigestTest::Schema->connect("dbi:SQLite:dbname=${db_file}");
$schema->deploy({}, File::Spec->catdir(__DIR__, 'var'));

my $checks = {};
for my $algorithm( qw/Whirlpool/){
  my $maker = Digest->new($algorithm);
  my $encodings = $checks->{$algorithm} = {};
  for my $encoding (qw/base64 hex/){
    my $values = $encodings->{$encoding} = {};
    my $encoding_method = $encoding eq 'binary' ? 'digest' :
      ($encoding eq 'hex' ? 'hexdigest' : 'b64digest');
    for my $value (qw/test1 test2/){
      $maker->reset()->add($value);
      $values->{$value} = $maker->$encoding_method;
    }
  }
}

my %create_values = (whirlpool_hex => 'test1', whirlpool_b64 => 'test1');
my $row = $schema->resultset('Whirlpool')->create( \%create_values );
is( $row->whirlpool_hex, $checks->{'Whirlpool'}{hex}{test1}, 'Whirlpool hex');
is( $row->whirlpool_b64, $checks->{'Whirlpool'}{base64}{test1}, 'Whirlpool b64');

can_ok( $row, qw/check_whirlpool_hex check_whirlpool_b64/ );
ok( $row->check_whirlpool_hex('test1'), 'Checking hex digest_check_method for Whirlpool');
ok( $row->check_whirlpool_b64('test1'), 'Checking b64 digest_check_method for Whirlpool');

$row->whirlpool_hex('test2');
is( $row->whirlpool_hex, $checks->{'Whirlpool'}{hex}{test2}, 'Checking accessor (Whirlpool)');

$row->update({ whirlpool_b64 => 'test2' });
is( $row->whirlpool_b64, $checks->{'Whirlpool'}{base64}{test2}, 'Checking Update (Whirlpool)');
