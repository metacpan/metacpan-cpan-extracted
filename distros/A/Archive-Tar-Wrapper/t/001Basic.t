use warnings;
use strict;
use Log::Log4perl qw(:easy);
use FindBin qw($Bin);
Log::Log4perl->easy_init($ERROR);

use File::Temp qw(tempfile);

my $TARDIR = "data";
$TARDIR = "t/$TARDIR" unless -d $TARDIR;

use Test::More tests => 24;
BEGIN { use_ok('Archive::Tar::Wrapper') }

umask(0);
my $arch = Archive::Tar::Wrapper->new();
ok( $arch->read("$TARDIR/foo.tgz"), "opening compressed tarfile" );
ok( $arch->locate("001Basic.t"),    "find 001Basic.t" );
ok( $arch->locate("./001Basic.t"),  "find ./001Basic.t" );
ok( !$arch->locate("nonexist"),     "find nonexist" );

# Add a new file
my $tmploc = $arch->locate("001Basic.t");
ok( $arch->add( "foo/bar/baz", $tmploc ), "adding file" );

# Add data
my $data = "this is data";
ok( $arch->add( "foo/bar/string", \$data ), "adding data" );
ok( $arch->locate("foo/bar/baz"), "find added file" );
ok( $arch->add( "foo/bar/permtest", $tmploc, { perm => 0770 } ),
    "adding file" );

# Make a tarball
my ( $fh, $filename ) = tempfile( UNLINK => 1 );
ok( $arch->write($filename), "Tarring up" );

# List
my $a2 = Archive::Tar::Wrapper->new();
ok( $a2->read($filename), "Reading in new tarball" );
my $elements = $a2->list_all();
my $got = join " ", sort map { $_->[0] } @$elements;
is( $got, "001Basic.t foo/bar/baz foo/bar/permtest foo/bar/string",
    "Check list" );

my $f1 = $a2->locate("001Basic.t");
my $f2 = $a2->locate("foo/bar/baz");
ok( -s $f1 > 0, "Checking tarball files sizes" );
ok( -s $f2 > 0, "Checking tarball files sizes" );

is( -s $f1, -s $f2, "Comparing tarball files sizes" );

my $f3 = $a2->locate("foo/bar/permtest");
my $perm = ( ( stat($f3) )[2] & 07777 );
is( $perm, 0770, "permtest" );

my $f4 = $a2->locate("foo/bar/string");
open FILE, "<$f4" or die "Cannot open $f4";
my $got_data = join '', <FILE>;
close FILE;
is( $got_data, $data, "comparing file data" );

# Iterators
$arch->list_reset();
my @elements = ();
while ( my $entry = $arch->list_next() ) {
    push @elements, $entry->[0];
}
$got = join " ", sort @elements;
is( $got, "001Basic.t foo/bar/baz foo/bar/permtest foo/bar/string",
    "Check list" );

# Check optional file names for extraction
#data/bar.tar
#drwxrwxr-x mschilli/mschilli 0 2005-07-24 12:15:34 bar/
#-rw-rw-r-- mschilli/mschilli 11 2005-07-24 12:15:27 bar/bar.dat
#-rw-rw-r-- mschilli/mschilli 11 2005-07-24 12:15:34 bar/foo.dat

my $a3 = Archive::Tar::Wrapper->new();
$a3->read( "$TARDIR/bar.tar", "bar/bar.dat" );
$elements = $a3->list_all();

is( scalar @$elements,   1,             "only one file extracted" );
is( $elements->[0]->[0], "bar/bar.dat", "only one file extracted" );

# Ask for non-existent files in tarball
my $a4 = Archive::Tar::Wrapper->new();

# Suppress the warning
Log::Log4perl->get_logger("")->level($FATAL);

my $rc;

SKIP: {
    $rc = $a4->read( "$TARDIR/bar.tar", "bar/bar.dat", "quack/schmack" );
    if ( $^O =~ /freebsd/i ) {
        skip( "FreeBSD's tar is too lenient - skipping", 1 );
    }
    is( $rc, undef, "Failure to ask for non-existent files" );
}

# Permissions
umask(022);
my $a5 = Archive::Tar::Wrapper->new( tar_read_options => 'p', );
$a5->read("$TARDIR/bar.tar");
$f1 = $a5->locate('bar/bar.dat');

if ($f1) {
    $perm = ( ( stat($f1) )[2] & 07777 );
}
else {
    note("Could not locate 'bar/bar.dat' inside the tarball '$TARDIR/bar.tar'");
}

SKIP: {
    skip 'Cannot check permissions on a non-existent file', 1 unless $f1;
    is( $perm, 0664, 'testing file permissions' );
}

SKIP: {
    # gnu options
    my $a6 =
      Archive::Tar::Wrapper->new( tar_gnu_read_options => ["--numeric-owner"],
      );

    my $is_gnu = $a6->is_gnu();
    note( $a6->{tar_error_msg} );

    skip "Only with gnu tar", 1 unless $is_gnu;

    $a6->read("$TARDIR/bar.tar");
    $f1 = $a6->locate("bar/bar.dat");

    ok( defined $f1, "numeric owner works" );

}

SKIP: {
    # gnu options
    my $tar =
      Archive::Tar::Wrapper->new( tar_gnu_write_options => ["--exclude=foo"], );

    my $is_gnu = $tar->is_gnu();
    note( $tar->{tar_error_msg} );
    skip "Only with gnu tar", 1 unless $is_gnu;

    my $file_loc = $tar->locate("001Basic.t");
    $tar->add( "foo/bar/baz", $0 );
    $tar->add( "boo/bar/baz", $0 );

    my ( $fh, $filename ) = tempfile( UNLINK => 1, SUFFIX => ".tgz" );
    $tar->write( $filename, 1 );

    my $tar_read = Archive::Tar::Wrapper->new();
    $tar_read->read($filename);

    for my $entry ( @{ $tar_read->list_all() } ) {
        my ( $tar_path, $real_path ) = @$entry;

        is( $tar_path, "boo/bar/baz", "foo excluded" );
    }
}
