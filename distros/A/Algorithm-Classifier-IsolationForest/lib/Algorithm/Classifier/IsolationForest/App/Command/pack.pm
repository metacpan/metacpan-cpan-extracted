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

sub _read_packed {
	my ($path) = @_;
	open my $fh, '<:raw', $path or die "open '$path' for read: $!\n";
	my $hdr;
	read( $fh, $hdr, HEADER_LEN ) == HEADER_LEN
		or die "'$path' is shorter than a packed-file header\n";
	my ( $magic, $version, $reserved, $n_pts, $n_feats ) = unpack( 'a8 v v V V', $hdr );
	die "'$path' does not look like a .iforest-packed file\n"
		unless $magic eq MAGIC;
	die "'$path' is .iforest-packed version $version; only "
		. VERSION . " is supported\n"
		unless $version == VERSION;
	die "'$path' has non-zero reserved field $reserved\n"
		unless $reserved == 0;
	my $bytes;
	my $want = $n_pts * $n_feats * 8;
	read( $fh, $bytes, $want ) == $want
		or die "'$path' truncated: wanted $want bytes, got "
		. ( defined $bytes ? length($bytes) : 0 ) . "\n";
	close $fh;
	return ( $n_pts, $n_feats, $bytes );
}

sub _write_packed {
	my ( $path, $n_pts, $n_feats, $bytes ) = @_;
	my $hdr = pack( 'a8 v v V V', MAGIC, VERSION, 0, $n_pts, $n_feats );
	write_file( $path, { 'atomic' => 1, 'binmode' => ':raw' }, $hdr . $bytes );
}

# Helper used by the other commands so they all read the same format
# the same way.  Returns ($n_pts, $n_feats, $bytes_str).
sub read_packed_file { _read_packed(@_) }

# Cheap, allocation-light magic check so consumer commands can peek at
# a path without slurping the whole file.
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
		[ 'm=s', 'Model JSON to validate n_features against.',
			{ 'default' => 'iforest_model.json', 'completion' => 'files' } ],
		[ 'i=s', 'Input CSV to pack.',
			{ 'completion' => 'files' } ],
		[ 'o=s', 'Output .iforest-packed file path.',
			{ 'completion' => 'files' } ],
		[ 'w',   'Overwrite -o if it already exists.' ],
	);
}

sub abstract { 'Pre-pack a CSV dataset into a binary file the scoring commands can read directly' }

sub description { 'Reads a CSV, validates that every row has the same numeric
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
' }

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined $opt->{'i'} ) {
		$self->usage_error('-i has not been specified');
	}
	elsif ( !-f $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not a file or does not exist' );
	}
	elsif ( !-r $opt->{'i'} ) {
		$self->usage_error( '-i, "' . $opt->{'i'} . '", is not readable' );
	}

	if ( !defined $opt->{'o'} ) {
		$self->usage_error('-o has not been specified');
	}
	elsif ( -e $opt->{'o'} && !$opt->{'w'} ) {
		$self->usage_error(
			'-o, "' . $opt->{'o'} . '", already exists and -w was not specified' );
	}

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}
	elsif ( !-r $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not readable' );
	}

	return 1;
}

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
		die "line $line of '$opt->{i}' has "
			. scalar(@f)
			. " columns but model has $nf features\n"
			unless scalar @f == $nf;
		for my $v (@f) {
			die "line $line of '$opt->{i}' value '$v' is not numeric\n"
				unless looks_like_number($v);
		}
		push @data, \@f;
	}
	die "input '$opt->{i}' contains no rows\n" unless @data;

	my $packed = $model->pack_data( \@data );
	_write_packed( $opt->{'o'},
		$packed->n_pts, $packed->n_feats, $packed->{packed} );

	printf "wrote %s (%d rows, %d features, %d bytes payload)\n",
		$opt->{'o'}, $packed->n_pts, $packed->n_feats,
		$packed->n_pts * $packed->n_feats * 8;

	return 1;
}

return 1;
