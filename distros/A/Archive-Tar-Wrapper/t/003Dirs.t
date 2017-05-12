######################################################################
# Test suite for Archive::Tar::Wrapper
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);
use File::Path;
use File::Temp qw(tempfile tempdir);

my $TARDIR = "data";
$TARDIR = "t/$TARDIR" unless -d $TARDIR;
my $TMPDIR = tempdir( CLEANUP => 1 );

use Test::More tests => 4;
BEGIN { use_ok('Archive::Tar::Wrapper') };

rmdir $TMPDIR if -d $TMPDIR;
mkdir $TMPDIR or die "Cannot mkdir $TMPDIR";
END { rmtree $TMPDIR }

my $arch = Archive::Tar::Wrapper->new(tmpdir => $TMPDIR, dirs => 1);

ok($arch->read("$TARDIR/bar.tar"), "opening compressed tarfile");

my $e = $arch->list_all();
my $all = join " ", sort(map { $_->[0] } @$e);
is($all, ". bar bar/bar.dat bar/foo.dat", "list all dirs");

my @dirs = map { $_->[0] } grep { $_->[2] eq "d" } @$e;
is("@dirs", ". bar", "dirs only");
