use Test2::V0 -no_srand => 1;
use 5.020;
use Archive::Libarchive::Entry;
use utf8;

subtest 'basic' => sub {

  my $e = Archive::Libarchive::Entry->new;
  isa_ok $e, 'Archive::Libarchive::Entry';

};

subtest 'utf-8' => sub {

  my $e = Archive::Libarchive::Entry->new;
  $e->set_pathname_utf8('Привет.txt');
  my $ret = $e->pathname_utf8;

  use Encode qw( decode );

  is($ret, 'Привет.txt');

};

subtest 'filetype' => sub {

  my $reg_int = oct('100000');

  subtest 'set with string' => sub {

    my $e = Archive::Libarchive::Entry->new;
    $e->set_filetype('reg');

    is($e->filetype, 'reg');
    is($e->filetype, number $reg_int);

  };

  subtest 'set with string' => sub {

    my $e = Archive::Libarchive::Entry->new;
    $e->set_filetype($reg_int);

    is($e->filetype, 'reg');
    is($e->filetype, number $reg_int);

  };

};

subtest 'xattr' => sub {

  my $e = Archive::Libarchive::Entry->new;
  $e->xattr_add_entry( foo => "bar\0baz" );

  my($name, $value);

  is($e->xattr_reset, 1);

  is $e->xattr_next(\$name, \$value), 0;
  is($name, "foo" );
  is($value, "bar\0baz" );

  is $e->xattr_next(\$name, \$value), -20;
  is($name,  undef);
  is($value, undef );

};

subtest 'stat' => sub {

  # https://github.com/uperl/Archive-Libarchive/issues/19
  skip_all 'not implemented on windows'
    if $^O eq 'MSWin32';

  require FFI::C::Stat;

  my $e = Archive::Libarchive::Entry->new;
  my $stat = FFI::C::Stat->new(__FILE__);

  try_ok { $e->copy_stat($stat) };
  is( $e->size, $stat->size );

  my $stat2;
  try_ok { $stat2 = $e->stat };
  try_ok { is( $stat2->size, $stat->size ) };

};

subtest 'clone' => sub {

  my $e = Archive::Libarchive::Entry->new;
  $e->set_pathname('foo/bar.txt');

  my $e2 = $e->clone;

  is($e2->pathname, 'foo/bar.txt');

  undef $e;

  is($e2->pathname, 'foo/bar.txt');

};

subtest 'mac metadata' => sub {
  my $e = Archive::Libarchive::Entry->new;
  $e->copy_mac_metadata("foo\0bar");
  is($e->mac_metadata, "foo\0bar");
};

done_testing;
