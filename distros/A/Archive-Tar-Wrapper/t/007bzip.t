######################################################################
# Test suite for Archive::Tar::Wrapper
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use File::Temp qw(tempfile);

my $TARDIR = "data";
$TARDIR = "t/$TARDIR" unless -d $TARDIR;

use Test::More tests => 5;
BEGIN { use_ok('Archive::Tar::Wrapper') };

umask(0);
my $arch = Archive::Tar::Wrapper->new();

ok($arch->read("$TARDIR/foo.tar.bz2"), "opening compressed tarfile");

ok($arch->locate("001Basic.t"), "find 001Basic.t");
ok($arch->locate("./001Basic.t"), "find ./001Basic.t");

ok(!$arch->locate("nonexist"), "find nonexist");

