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

use Test::More tests => 6;
BEGIN { use_ok('Archive::Tar::Wrapper') };

SKIP: {
    if($] < 5.008) {
        skip "Unicode tests skipped with perl < 5.8", 5;
    }
    umask(0);
    my $arch = Archive::Tar::Wrapper->new();
    
    ok($arch->read("$TARDIR/foo.tgz"), "opening compressed tarfile");
    
    # Add data
    my $data = "this is data \x{00fc}";
    ok($arch->add("foo/bar/string", \$data, {binmode => ":utf8"}), 
       "adding data");
    
    # Make a tarball
    my($fh, $filename) = tempfile(UNLINK => 1);
    ok($arch->write($filename), "Tarring up");
    
    # List 
    my $a2 = Archive::Tar::Wrapper->new();
    ok($a2->read($filename), "Reading in new tarball");
    
    my $f1 = $a2->locate("foo/bar/string");
    open FILE, "<:utf8", $f1 or die "Cannot open $f1";
    my $got_data = join '', <FILE>;
    close FILE;
    is($got_data, $data, "comparing file utf8 data");
}
