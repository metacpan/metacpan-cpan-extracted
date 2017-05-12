use Test::More;
use Test::Exception;

use Csistck;
use Csistck::Test::File;
use File::Temp qw/tempfile/;

plan tests => 2;

# Print null data file, get src and dest
my ($h, $src) = tempfile();
print $h "NULL";
close($h);
my $dest = "/tmp/THIS_FILE_DOES_NOT_EXIST";

dies_ok( sub { Csistck::Test::File::file_diff($src, $dest); }, 'Non-existant file detected'); 
dies_ok( sub { Csistck::Test::Template::template_diff($src, $dest); }, 'Non-existant template detected');

