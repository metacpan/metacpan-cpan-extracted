use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);

use DB::Berkeley qw(DB_RDONLY);

my ($fh, $file) = tempfile();
close $fh;
unlink $file;  # Ensure the file does not exist

# Try opening a non-existent DB in read-only mode
throws_ok {
	DB::Berkeley->new($file, DB_RDONLY, 0600);
} qr/(no such file|does not exist|ENOENT|open)/i,
	'Opening nonexistent file in read-only mode croaks';

done_testing();
