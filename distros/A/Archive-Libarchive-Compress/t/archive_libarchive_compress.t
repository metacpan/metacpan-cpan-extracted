use Test2::V0 -no_srand => 1;
use Archive::Libarchive::Compress;
use Archive::Libarchive::Peek;
use experimental qw( signatures );

subtest 'constructor errors' => sub {

  is(
    dies { Archive::Libarchive::Compress->new },
    match qr/^Required option: one of filename or memory/,
  );

  is(
    dies { Archive::Libarchive::Compress->new( filename => 'foo', memory => \'' ) },
    match qr/^Exactly one of filename or memory is required/,
  );

  is(
    dies { Archive::Libarchive::Compress->new( bogus => 'foo', filename => 'foo' ) },
    match qr/^Illegal options: bogus/,
  );

  is(
    dies { Archive::Libarchive::Compress->new( memory => '' ) },
    match qr/^Option memory must be a scalar reference to a plain non-reference scalar/,
  );

  is(
    dies { Archive::Libarchive::Compress->new( memory => \'', entry => 1 ) },
    match qr/^Entry is not a code reference/,
  );

};

subtest 'memory' => sub {

  my $out = '';

  my $w = Archive::Libarchive::Compress->new( memory => \$out );

  is ref($w), 'Archive::Libarchive::Compress';

  $w->compress( from => 'corpus/single' );

  is(
    Archive::Libarchive::Peek->new( memory => \$out)->file('hello.txt'),
    "hello world\n",
  );

};

subtest 'file' => sub {

  my $out = Path::Tiny->tempfile;

  my $w = Archive::Libarchive::Compress->new( filename => "$out" );

  is ref($w), 'Archive::Libarchive::Compress';

  $w->compress( from => 'corpus/single' );

  is(
    Archive::Libarchive::Peek->new( filename => "$out" )->file('hello.txt'),
    "hello world\n",
  );

};

subtest 'entry' => sub {

  my $out = '';

  my $w = Archive::Libarchive::Compress->new(
    memory => \$out,
    entry => sub ($e) {
      if($e->pathname eq 'hello.txt') {
        $e->set_pathname('x/hello.txt');
        return 1;
      } else {
        return 0;
      }
    },
  );

  is ref($w), 'Archive::Libarchive::Compress';

  $w->compress( from => 'corpus/single' );

  is(
    Archive::Libarchive::Peek->new( memory => \$out)->file('x/hello.txt'),
    "hello world\n",
  );

};

subtest 'prep' => sub {

  my $out = '';
  my $class;

  my $w = Archive::Libarchive::Compress->new(
    memory => \$out,
    prep => sub ($ar) {
      $class = ref $ar;
      $ar->set_format_pax_restricted;
    },
  );

  is ref($w), 'Archive::Libarchive::Compress';

  $w->compress( from => 'corpus/single' );

  is($class, 'Archive::Libarchive::ArchiveWrite');

  is(
    Archive::Libarchive::Peek->new( memory => \$out)->file('hello.txt'),
    "hello world\n",
  );

};

done_testing;
