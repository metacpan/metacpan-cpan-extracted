package App::Test::Generator::LCSAJ::Coverage;

use strict;
use warnings;

use autodie qw(:all);
use Carp qw(croak);
use JSON::MaybeXS;

our $VERSION = '0.33';

=head1 NAME

App::Test::Generator::LCSAJ::Coverage - Merge LCSAJ path data with runtime hits

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Merges static LCSAJ path data produced by L<App::Test::Generator::LCSAJ>
with runtime line hit data to determine which LCSAJ paths were covered
during test execution. The merged result is written as JSON for
consumption by C<bin/test-generator-index>.

=head2 merge

Merge a static LCSAJ path JSON file with a runtime line hits JSON file
and write the annotated result to an output file.

    App::Test::Generator::LCSAJ::Coverage::merge(
        'cover_db/lcsaj/MyModule.pm.lcsaj.json',
        'cover_db/lcsaj/MyModule.pm.hits.json',
        'cover_db/lcsaj/MyModule.pm.covered.json',
    );

=head3 Arguments

=over 4

=item * C<$lcsaj_file>

Path to the C<.lcsaj.json> file produced by
L<App::Test::Generator::LCSAJ>. Required.

=item * C<$hits_file>

Path to a JSON file mapping line numbers (as strings) to hit counts,
as produced by L<Devel::App::Test::Generator::LCSAJ::Runtime>.
Required.

=item * C<$out_file>

Path to write the merged output JSON file. Required.

=back

=head3 Returns

Nothing. Writes the annotated LCSAJ path data to C<$out_file>, with
a C<covered> key added to each path record.

=head3 Side effects

Writes to C<$out_file>. Croaks if any file cannot be read or written.

=head3 Notes

A path is considered covered if any line in the range C<start..end>
was executed at least once. This is a conservative approximation —
it does not verify that the jump target was actually reached. As a
result, coverage may be slightly overstated for paths where only the
beginning of the sequence was executed.

=head3 API specification

=head4 input

    {
        lcsaj_file => { type => SCALAR },
        hits_file  => { type => SCALAR },
        out_file   => { type => SCALAR },
    }

=head4 output

    { type => UNDEF }

=cut

sub merge {
	my ($lcsaj_file, $hits_file, $out_file) = @_;

	# Validate all three file arguments before attempting any IO
	croak 'lcsaj_file required' unless defined $lcsaj_file;
	croak 'hits_file required'  unless defined $hits_file;
	croak 'out_file required'   unless defined $out_file;

	# Load static LCSAJ path data extracted by App::Test::Generator::LCSAJ
	my $paths = decode_json(_slurp($lcsaj_file));

	# Load runtime line hit counts from Devel::App::Test::Generator::LCSAJ::Runtime
	my $hits  = decode_json(_slurp($hits_file));

	# Annotate each path with a covered flag — a path is considered
	# covered if any line in the start..end range was executed
	for my $path (@{$paths}) {
		my $covered = 0;

		for my $line ($path->{start} .. $path->{end}) {
			if($hits->{$line}) {
				$covered = 1;
				last;
			}
		}

		$path->{covered} = $covered;
	}

	# Write the annotated paths to the output file
	open my $fh, '>', $out_file or croak "Cannot write coverage output to $out_file: $!";
	print $fh encode_json($paths);
	close $fh;
}

# --------------------------------------------------
# _slurp
#
# Purpose:    Read the entire contents of a file and
#             return it as a string.
#
# Entry:      $file - path to the file to read.
#
# Exit:       Returns the file contents as a scalar
#             string. Croaks if the file cannot be
#             opened.
#
# Side effects: None beyond opening and closing the
#               file handle.
#
# Notes:      Uses three-argument open for safety with
#             filenames containing special characters.
#             Sets $/ to undef to slurp the whole file
#             in one read, localised to avoid affecting
#             other code.
# --------------------------------------------------
sub _slurp {
	my $file = $_[0];

	open my $fh, '<', $file or croak "Cannot read $file: $!";

	# Localise $/ to undef to slurp entire file in one read
	local $/;
	return <$fh>;
}

1;
