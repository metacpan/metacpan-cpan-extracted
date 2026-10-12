package Clay::Test::ChildPerl;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
use File::Temp qw(tempfile);

our $VERSION = '0.01';

our @EXPORT_OK = qw(child_perl);

# The command that runs $code in a child perl with this perl's @INC.
# The code goes through a file, not -e: Windows hands the child one
# command line, which mangles multi-line code with quotes in it.
sub child_perl ($code) {
	my ($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
	print {$fh} $code;
	close $fh or die "cannot write $file: $!";
	return ($^X, (map { "-I$_" } @INC), $file);
}

1;
