package Algorithm::Classifier::IsolationForest::App::Command::pack;

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest ();
use Algorithm::Classifier::IsolationForest::App -command;
use File::Slurp  qw(read_file write_file);
use Scalar::Util qw(looks_like_number);

# .iforest-packed v1 file layout (all little-endian):
#
#   offset  size  field
#   -----------------------------------------------------------
#        0    8   magic  -- ASCII "IFPKD\0\0\0"
#        8    2   version (uint16, currently 1)
#       10    2   reserved (uint16, must be 0)
#       12    4   n_pts   (uint32)
#       16    4   n_feats (uint32)
#       20  ...   n_pts * n_feats packed doubles ('d' pack format,
#                 little-endian per the IEEE-754 native layout)
#
# The format is intentionally minimal: the goal is to skip the CSV
# parse + pack_input_xs cost on subsequent scoring runs.  Models are
# not embedded -- the caller must pair the .iforest-packed file with a
# model that has the same n_features at score time.
use constant MAGIC      => 'IFPKD' . "\0\0\0";    # 8 bytes
use constant VERSION    => 1;
use constant HEADER_LEN => 20;

# Read a .iforest-packed file back into the pieces a scoring command
# needs.  Every field in the header above is checked, so a truncated or
# foreign file is reported by name rather than silently scored as noise.
#
# Args:
#   $path :: path to the .iforest-packed file, which must be readable.
#
# Returns: the three-element list ($n_pts, $n_feats, $bytes) -- the row
# count, the feature width, and the raw row-major double buffer as a
# string.  Dies with a message naming $path on a bad magic, an unsupported
# version, a non-zero reserved field, or a short read.
#
# Example:
#   my ( $n_pts, $n_feats, $bytes ) = _read_packed('data.iforest-packed');
#   length($bytes) == $n_pts * $n_feats * 8;   # true
sub _read_packed {
	my ($path) = @_;
	open my $fh, '<:raw', $path or die "open '$path' for read: $!\n";
	my $hdr;
	read( $fh, $hdr, HEADER_LEN ) == HEADER_LEN
		or die "'$path' is shorter than a packed-file header\n";
	my ( $magic, $version, $reserved, $n_pts, $n_feats ) = unpack( 'a8 v v V V', $hdr );
	die "'$path' does not look like a .iforest-packed file\n"
		unless $magic eq MAGIC;
	die "'$path' is .iforest-packed version $version; only " . VERSION . " is supported\n"
		unless $version == VERSION;
	die "'$path' has non-zero reserved field $reserved\n"
		unless $reserved == 0;
	my $bytes;
	my $want = $n_pts * $n_feats * 8;
	read( $fh, $bytes, $want ) == $want
		or die "'$path' truncated: wanted $want bytes, got " . ( defined $bytes ? length($bytes) : 0 ) . "\n";
	close $fh;
	return ( $n_pts, $n_feats, $bytes );
} ## end sub _read_packed

# Write a .iforest-packed file: the header above followed by the buffer.
# The write is atomic, so a consumer never sees a half-written file even
# if the pack is interrupted.
#
# Args:
#   $path :: where to write.  An existing file is replaced.
#   $n_pts :: the row count, recorded in the header.
#   $n_feats :: the feature width, recorded in the header.
#   $bytes :: the row-major double buffer as a string, normally straight
#             from pack_data.  Must be $n_pts * $n_feats * 8 bytes long --
#             nothing re-checks that here.
#
# Returns: nothing.  Dies through File::Slurp if the write fails.
#
# Example:
#   _write_packed( 'data.iforest-packed', $n_pts, $n_feats, $packed->{packed} );
sub _write_packed {
	my ( $path, $n_pts, $n_feats, $bytes ) = @_;
	my $hdr = pack( 'a8 v v V V', MAGIC, VERSION, 0, $n_pts, $n_feats );
	write_file( $path, { 'atomic' => 1, 'binmode' => ':raw' }, $hdr . $bytes );
}

# The public face of _read_packed; see the POD below.  Exists so predict,
# explain and bench all read the format the same way rather than each
# reaching for the underscore name.
sub read_packed_file { _read_packed(@_) }

# Cheap, allocation-light magic check; see the POD below.  This is how -i
# decides between a CSV and a packed file without being told which it was
# handed.
sub is_packed_file {
	my ($path) = @_;
	open my $fh, '<:raw', $path or return 0;
	my $magic;
	my $ok = read( $fh, $magic, 8 ) == 8;
	close $fh;
	return $ok && $magic eq MAGIC;
}

sub opt_spec {
	return (
		[
			'm=s',
			'Model JSON to validate n_features against.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' }
		],
		[ 'i=s', 'Input CSV to pack.',                { 'completion' => 'files' } ],
		[ 'o=s', 'Output .iforest-packed file path.', { 'completion' => 'files' } ],
		[ 'w',   'Overwrite -o if it already exists.' ],
	);
} ## end sub opt_spec

sub abstract { 'Pre-pack a CSV dataset into a binary file the scoring commands can read directly' }

sub description {
	'Reads a CSV, validates that every row has the same numeric
column count as the model expects, runs the data through pack_data, and
writes a self-contained binary (.iforest-packed) the other iforest
commands can consume directly.

This skips the CSV parse + pack_input_xs cost on subsequent scoring
runs.  It is most useful when the same data set is scored repeatedly
with different thresholds, e.g. during interactive tuning:

    iforest pack    -m model.json -i data.csv -o data.packed
    iforest predict -m model.json -i data.packed -t 0.55 -o pred-55.csv
    iforest predict -m model.json -i data.packed -t 0.65 -o pred-65.csv
    iforest predict -m model.json -i data.packed -t 0.75 -o pred-75.csv

The file format begins with the magic bytes "IFPKD\0\0\0".  predict
auto-detects it on its -i input.

Requires the Inline::C backend; pure-Perl installs cannot produce or
consume the packed format.
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined $opt->{'i'} ) {
		$self->usage_error('-i has not been specified');
	} elsif ( !-f $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
	}

	if ( !defined $opt->{'o'} ) {
		$self->usage_error('-o has not been specified');
	} elsif ( -e $opt->{'o'} && !$opt->{'w'} ) {
		$self->usage_error( '-o, "' . $opt->{'o'} . '", already exists and -w was not specified' );
	}

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	} elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	die "iforest pack requires the Inline::C backend\n"
		unless $Algorithm::Classifier::IsolationForest::HAS_C;

	my $model = Algorithm::Classifier::IsolationForest->load( $opt->{'m'} );
	my $nf    = $model->{n_features};

	my @data;
	my $line = 0;
	for my $row ( read_file( $opt->{'i'} ) ) {
		$line++;
		chomp $row;
		next if $row =~ /^\s*$/;
		my @f = split /,/, $row, -1;
		die "line $line of '$opt->{i}' has " . scalar(@f) . " columns but model has $nf features\n"
			unless scalar @f == $nf;
		for my $v (@f) {
			die "line $line of '$opt->{i}' value '$v' is not numeric\n"
				unless looks_like_number($v);
		}
		push @data, \@f;
	} ## end for my $row ( read_file( $opt->{'i'} ) )
	die "input '$opt->{i}' contains no rows\n" unless @data;

	my $packed = $model->pack_data( \@data );
	_write_packed( $opt->{'o'}, $packed->n_pts, $packed->n_feats, $packed->{packed} );

	printf "wrote %s (%d rows, %d features, %d bytes payload)\n",
		$opt->{'o'}, $packed->n_pts, $packed->n_feats,
		$packed->n_pts * $packed->n_feats * 8;

	return 1;
} ## end sub execute

=head1 NAME

Algorithm::Classifier::IsolationForest::App::Command::pack - Pre-pack a CSV dataset into a binary file the scoring commands can read directly

=head1 DESCRIPTION

Converts a CSV into the C<.iforest-packed> binary format, so repeated
scoring runs over the same dataset skip the CSV parse and the input-packing
step.  C<iforest predict> and C<iforest explain> detect the format by its
magic bytes and take it wherever they take a CSV.

The file holds only the packed doubles and their dimensions -- no model is
embedded, so it is on the caller to pair it with a model of the same
feature width.

Run it as C<iforest pack>; C<iforest help pack> lists every option.

=head1 METHODS

L<App::Cmd> calls these while dispatching the subcommand.  Nothing else
should.

=head2 opt_spec

Returns this command's option specifications, as the list of arrayrefs
L<Getopt::Long::Descriptive> expects.

=head2 abstract

Returns the one-line summary C<iforest commands> prints beside the
command name.

=head2 description

Returns the long help text C<iforest help pack> prints under the option
list.

=head2 validate

Checks the parsed options before anything is read or written, so a
mistake costs nothing.

Checks that C<-i> and C<-o> were given, that C<-i> is readable, and that
C<-m> names a readable model.

Takes the parsed options hashref and the arrayref of remaining
arguments.  Calls C<usage_error>, which prints the usage and exits, on
the first problem it finds, and returns 1 when everything checks out.

=head2 execute

Reads the CSV, packs it through the model, and writes the binary to C<-o>.

Takes the parsed options hashref and the arrayref of remaining
arguments, and returns 1.

=head2 read_packed_file

Reads a C<.iforest-packed> file, so the scoring commands all parse the
format the same way.

Takes the path and returns the three-element list of the row count, the
feature width, and the raw row-major double buffer.  It dies naming the
path on a bad magic number, an unsupported version, or a truncated file.

    my ( $n_pts, $n_feats, $bytes ) = $class->read_packed_file($path);

=head2 is_packed_file

Cheap check for whether a path holds a C<.iforest-packed> file, so a
command can tell a packed input from a CSV without slurping either.

Takes the path and returns true when the first eight bytes are the
format's magic number.  A missing or unreadable path is simply false, so
this never dies and needs no C<-f> test first.

    if ( is_packed_file($input) ) { ... }

=cut

return 1;
