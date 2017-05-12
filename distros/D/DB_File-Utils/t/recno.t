use warnings;
use strict;

use Test::More tests => 11;

use App::Cmd::Tester;

use DB_File::Utils;
use File::Temp qw/ tempfile /;

my ($x, $filename) = tempfile(SUFFIX => '.db');
close $x;

## test 'new'
my $result = testApp("--recno new $filename");
print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

ok(-f "$filename", "new file");

my ($fh, $name) = tempfile(SUFFIX => '.key');
print $fh "value";
close $fh;

for (1..10) {
	$result = testApp("--recno put -i $name $filename $_");
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;
}

for (1..10) {
	$result = testApp("--recno get $filename $_");
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

	is ($result->stdout, "value\n", "value correctly obtained reading from file");
}




sub testApp {
	return test_app('DB_File::Utils' => [split /\s+/, $_[0]]);
}
