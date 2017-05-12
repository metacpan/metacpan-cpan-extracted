#!perl

=head1 PURPOSE

Check Perl files for encoding issues.

=cut

use strict;
use warnings;

use Test::More;


# Load module.
eval
{
	require Test::Mojibake;
};
plan( skip_all => 'Test::Mojibake required for source encoding testing' )
	if $@;

# Test encoding for all files.
Test::Mojibake::all_files_encoding_ok();
