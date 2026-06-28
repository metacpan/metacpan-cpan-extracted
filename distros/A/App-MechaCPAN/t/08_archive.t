use strict;
use FindBin;
use Test::More;
use File::Copy qw/copy/;
use File::Spec;
use File::Temp qw/tempdir/;
use Cwd qw/cwd/;
use autodie qw/:default copy/;

require q[./t/helper.pm];

my $src_tarball = "$FindBin::Bin/../test_dists/FakePerl-5.12.0.tar.gz";

my $pwd = cwd;

# Ensure that inflate_archive can handle paths with shell-meaningful characters
my @tricky_names = (
  'arch w space.tar.gz',
  q{arch's name.tar.gz},
  q{arch "name".tar.gz},
);

for my $name (@tricky_names)
{
  subtest "inflate_archive handles: `$name`" => sub
  {
    my $tmpdir = tempdir(
      TEMPLATE => File::Spec->tmpdir . "/mecha_inflate_XXXXXXXX",
      CLEANUP  => 1,
    );

    my $copied = File::Spec->catfile( $tmpdir, $name );
    copy( $src_tarball, $copied );

    my $dest = File::Spec->catdir( $tmpdir, 'extract' );
    mkdir $dest;

    chdir $tmpdir;
    local $@;
    my $result = eval { App::MechaCPAN::inflate_archive( $copied, $dest ) };
    my $err    = $@;
    chdir $pwd;

    warn $err
      if $err;

    is( $err, '', 'inflate_archive did not die' );
    isnt( $result, undef, 'inflate_archive returned something' );
    is( -d $result, 1, 'inflate_archive returned a directory' );
  };
}

my $shady_dir = "$FindBin::Bin/../test_dists/ShadyTars";

# Sanity: the benign control still extracts cleanly
subtest 'inflate_archive accepts benign archive' => sub
{
  my $archive = File::Spec->catfile( $shady_dir, 'benign.tar.gz' );
  my ( $result, $err, $dest ) = run_inflate_in_sandbox($archive);

  diag $err
    if $err;

  is( $err, '', 'inflate_archive succeeded on benign archive' );
  isnt( $result, undef, 'inflate_archive returned something' );
  is( -d $result, 1, 'inflate_archive returned an existing directory' );
};

sub run_inflate_in_sandbox
{
  my $archive = shift;

  my $tmpdir = tempdir(
    TEMPLATE => File::Spec->tmpdir . "/mecha_safety_XXXXXXXX",
    CLEANUP  => 1,
  );

  my $dest = File::Spec->catdir( $tmpdir, 'extract' );
  mkdir $dest;
  chdir $tmpdir;

  local $@;
  my $result = eval { App::MechaCPAN::inflate_archive( $archive, $dest ) };
  my $err    = $@;
  chdir $pwd;

  return ( $result, $err, $dest );
}

# Each malicious tar must be refused. The error message is expected to
# mention 'unsafe' so future renames stay loud.
my @shadys = (
  { name => 'traversal',         archive => 'traversal.tar.gz' },
  { name => 'absolute_path',     archive => 'absolute_path.tar.gz' },
  { name => 'symlink_absolute',  archive => 'symlink_absolute.tar.gz' },
  { name => 'symlink_traversal', archive => 'symlink_traversal.tar.gz' },
  { name => 'hardlink_absolute', archive => 'hardlink_absolute.tar.gz' },
  {
    name => 'symlink_writethrough', archive => 'symlink_writethrough.tar.gz'
  },
);

for my $shady (@shadys)
{
  subtest "inflate_archive rejects $shady->{name}" => sub
  {
    my $archive = File::Spec->catfile( $shady_dir, $shady->{archive} );
    my ( $result, $err, $dest ) = run_inflate_in_sandbox($archive);

    isnt( $err, '', "inflate_archive died on $shady->{name}" )
      or diag "Unexpected success; result: " . ( $result // '(undef)' );

    like( $err, qr/unsafe/i, 'error indicates an unsafe entry' );
    is( $result, undef, 'inflate_archive returned undef' );
  };
}

done_testing;
