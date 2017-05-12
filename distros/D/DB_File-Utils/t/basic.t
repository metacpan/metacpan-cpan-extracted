
use warnings;
use strict;

use Test::More tests => 2 * 3;

use App::Cmd::Tester;

use DB_File::Utils;
use File::Temp qw/ tempfile /;

for my $type (qw.btree hash.) {

	my ($x, $filename) = tempfile(SUFFIX => '.db');
	close $x;

	## test 'new'
	my $result = test_app('DB_File::Utils' => [ "--$type",  new => $filename ]);
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

	ok(-f "$filename", "new file [$type]");

	## test 'put' from STDIN and 'get' 
	my ($fh, $name) = tempfile(SUFFIX => '.key');
	print $fh "value";
	close $fh;

	{
		open STDIN, "<", $name;

		$result = test_app('DB_File::Utils' => [ "--$type", put => $filename, 'key']);
		print STDERR "ERROR>", $result->error, "\n\n" if $result->error;
	}

	$result = test_app('DB_File::Utils' => [ "--$type", get => $filename, 'key']);
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

	is ($result->stdout, "value\n", "value correctly obtained reading from stdin[$type]");

	## test 'put' from file and 'get'
	$result = test_app('DB_File::Utils' => [ "--$type", "put", "-i", $name, $filename, 'foo']);
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

	$result = test_app('DB_File::Utils' => [ "--$type", get => $filename, 'foo']);
	print STDERR "ERROR>", $result->error, "\n\n" if $result->error;

	is ($result->stdout, "value\n", "value correctly obtained reading from file [$type]");

}
