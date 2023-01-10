use v5.10;
use strict;
use warnings;

use Test::More;
use Exporter qw(import);

our @EXPORT = qw(files_content_same);

sub files_content_same
{
	my (@files) = @_;

	die 'files_content_same expected two inputs'
		unless @files == 2;

	my @contents;
	for my $filename (@files) {
		if (ref $filename) {

			# handle later
			push @contents, $filename;
		}
		elsif (open my $fh, '<', $filename) {
			local $/ = undef;
			push @contents, scalar readline $fh;
		}
		else {
			fail "file $filename failed to open: $!";
			return;
		}
	}

	if (uc ref $contents[1] eq 'REGEXP') {
		like $contents[0], $contents[1], "file $files[0] matches";
	}
	else {
		is $contents[0], $contents[1], "files seem to have the same content: @files";
	}
}

1;

