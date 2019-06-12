use utf8;
use strict;
use warnings;
use Test::More;

use Dir::Self;
use Encode qw/ str2bytes /;
use File::Spec;
use File::Temp 'tempdir';
use lib File::Spec->catdir(__DIR__, 'lib');

use DigestTest::Schema;

BEGIN {
  if( eval 'require Digest' && eval 'require Digest::SHA' ){
    plan tests => 38;
  } else {
    plan skip_all => 'Digest::SHA not available';
    exit;
  }
}

DigestTest::Schema->load_classes('SHA');

my $tmp = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile($tmp, 'testdb.sqlite');
my $schema = DigestTest::Schema->connect("dbi:SQLite:dbname=${db_file}");
$schema->deploy({}, File::Spec->catdir(__DIR__, 'var'));

my @test_values = qw( test1 test2 テスト );

my $checks = {};
for my $algorithm( qw/SHA-1 SHA-256/){
  my $maker = Digest->new($algorithm);
  my $encodings = $checks->{$algorithm} = {};
  for my $encoding (qw/base64 hex/){
    my $values = $encodings->{$encoding} = {};
    my $encoding_method = $encoding eq 'binary' ? 'digest' :
      ($encoding eq 'hex' ? 'hexdigest' : 'b64digest');
    for my $value (@test_values){
      $maker->add(str2bytes("utf-8", $value));
      $values->{$value} = $maker->$encoding_method;
    }
  }
}

my $str = shift @test_values;

my %create_values = map { $_ => $str }
  qw( dummy_col sha1_hex sha1_b64 sha256_hex sha256_b64 sha256_b64_salted );

my $row = $schema->resultset('SHA')->create( \%create_values );
is($row->dummy_col,  $str,'dummy on create');
ok(!$row->can('check_dummy_col'), 'no "check_dummy_col" method');

is($row->sha1_hex,   $checks->{'SHA-1'}{hex}{$str},     'hex sha1 on create');
is($row->sha1_b64,   $checks->{'SHA-1'}{base64}{$str},  'b64 sha1 on create');
is($row->sha256_hex, $checks->{'SHA-256'}{hex}{$str},   'hex sha256 on create');
is($row->sha256b64,  $checks->{'SHA-256'}{base64}{$str},'b64 sha256 on create');
is( length($row->sha256_b64_salted), 57, 'correct salted length');

can_ok($row, qw/check_sha1_hex check_sha1_b64/);
ok($row->check_sha1_hex($str),'Checking hex digest_check_method');
ok($row->check_sha1_b64($str),'Checking b64 digest_check_method');
ok($row->check_sha256_b64_salted($str), 'Checking salted digest_check_method');

foreach my $str2 (@test_values) {

    $row->sha1_hex($str2);
    is($row->sha1_hex, $checks->{'SHA-1'}{hex}{$str2}, 'Checking accessor');

    $row->update({sha1_b64 => $str2,  dummy_col => $str2});
    is($row->sha1_b64, $checks->{'SHA-1'}{base64}{$str2}, 'Checking update');
    is($row->dummy_col,  $str2, 'dummy on update');

    $row->set_column(sha256_hex => $str2);
    is($row->sha256_hex, $checks->{'SHA-256'}{hex}{$str2}, 'Checking set_column');

    $row->sha256b64($str2);
    is($row->sha256b64, $checks->{'SHA-256'}{base64}{$str2}, 'custom accessor');

    $row->update;

    my $copy = $row->copy({sha256_b64 => $str2});
    is($copy->sha1_hex,   $checks->{'SHA-1'}{hex}{$str2},     'hex sha1 on copy');
    is($copy->sha1_b64,   $checks->{'SHA-1'}{base64}{$str2},  'b64 sha1 on copy');
    is($copy->sha256_hex, $checks->{'SHA-256'}{hex}{$str2},   'hex sha256 on copy');
    is($copy->sha256b64,  $checks->{'SHA-256'}{base64}{$str2},'b64 sha256 on copy');

    my $new = $schema->resultset('SHA')->new( \%create_values );
    is($new->sha1_hex,   $checks->{'SHA-1'}{hex}{$str},      'hex sha1 on new');
    is($new->sha1_b64,   $checks->{'SHA-1'}{base64}{$str},   'b64 sha1 on new');
    is($new->sha256_hex, $checks->{'SHA-256'}{hex}{$str},    'hex sha256 on new');
    is($new->sha256b64,  $checks->{'SHA-256'}{base64}{$str}, 'b64 sha256 on new');

}

$row->sha1_hex(undef);
$row->update;
is($row->sha1_hex, undef, 'Check undef is passed through');
