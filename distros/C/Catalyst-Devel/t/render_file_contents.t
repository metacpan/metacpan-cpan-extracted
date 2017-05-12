use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Catalyst::Helper;

use Test::More;

my $helper = bless {}, 'Catalyst::Helper';

use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile;
close $fh;

ok( $helper->render_file_contents('example1',  $fn,
        { test_var => 'test_val' }, 0677
    ),
    "file contents rendered" ); 
ok -r $fn;
ok -s $fn;
my $perms = ( stat $fn )[2] & 07777;
unless ($^O eq 'MSWin32') {
    is $perms, 0677;
}
unlink $fn;

done_testing;
