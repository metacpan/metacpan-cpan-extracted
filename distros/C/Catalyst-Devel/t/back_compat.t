use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Temp qw/tempfile/;
use lib "$Bin/lib";

use MyTestHelper;

use Test::More;

my $helper = bless {}, 'MyTestHelper';

my $example1 = $helper->get_file('MyTestHelper', 'example1');
chomp $example1;

my $example2 = $helper->get_file('MyTestHelper', 'example2');
chomp $example2; 


is $example1, 'foobar[% test_var %]';
is $example2, 'bazquux';

package MyTestHelper;

use Test::More;
use File::Temp qw/tempfile/;

my ($fh, $fn) = tempfile( UNLINK => 1 );
close $fh;
$helper->render_file('example1',  $fn, { test_var => 'test_val' });
open $fh, $fn or die $@;
#seek $fh, 0, 0; # Rewind
my $contents;
{
    local $/; 
    $contents = <$fh>;
}
is $contents, "foobartest_val\n";

done_testing;
