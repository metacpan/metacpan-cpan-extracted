# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: Tabfile.pm 340 2010-07-23 13:19:27Z tfrayner $

package Bio::MAGETAB::Util::Reader::Tabfile;

use Moose;
use MooseX::FollowPBP;

use MooseX::Types::Moose qw( Str FileHandle );
use Bio::MAGETAB::Types qw( Uri );

use Carp;
use charnames qw( :full );
use Text::CSV_XS;

use Bio::MAGETAB::Util::Builder;

has 'uri'                => ( is         => 'rw',
                              isa        => Uri,
                              coerce     => 1,
                              required   => 1 );

has 'eol_char'           => ( is         => 'rw',
                              isa        => Str,
                              required   => 0 );

has 'filehandle'         => ( is         => 'rw',
                              isa        => FileHandle,
                              required   => 0 );

has 'csv_parser'         => ( is         => 'rw',
                              isa        => 'Text::CSV_XS',
                              required   => 0,
                              handles    => [ qw(print) ]);

has 'builder'            => ( is         => 'ro',
                              isa        => 'Bio::MAGETAB::Util::Builder',
                              default    => sub { Bio::MAGETAB::Util::Builder->new() },
                              required   => 1 );

# Define some standard regexps:
my $RE_EMPTY_STRING             = qr{\A \s* \z}xms;
my $RE_COMMENTED_STRING         = qr{\A [\"\s]* \#}xms;
my $RE_SURROUNDED_BY_WHITESPACE = qr{\A [\"\s]* (.*?) [\"\s]* \z}xms;

sub BUILD {

    my ( $self, $params ) = @_;

    $self->_calculate_eol_char();
    $self->_construct_csv_parser();
    $self->_cache_filehandle();

    return;
}

sub getline {

    my ( $self, $fh ) = @_;

    $fh ||= $self->get_filehandle();

    return $self->get_csv_parser()->getline($fh);
}

sub can_ignore {

    my ( $self, $larry ) = @_;

    # Skip empty lines.
    my $line = join( q{}, @$larry );
    return 1 if ( $line =~ $RE_EMPTY_STRING );

    # Allow hash comments.
    return 1 if ( $line =~ $RE_COMMENTED_STRING );

    return;
}

sub strip_whitespace {

    my ( $self, $larry ) = @_;

    # Strip surrounding whitespace from each element.
    foreach my $element ( @$larry ) {
        $element =~ s/$RE_SURROUNDED_BY_WHITESPACE/$1/xms;
    }

    return $larry;
}

sub confirm_full_parse {

    my ( $self, $nextline ) = @_;

    # $nextline is an optional argument used to check for correct
    # parsing in the middle of a file (where $error != 2012, but we
    # don't want to throw an exception if we have a real $nextline).
    my $csv_parser = $self->get_csv_parser();

    # Check we've parsed to the end of the file.
    my ( $error, $mess ) = $csv_parser->error_diag();
    unless ( $nextline || $error == 2012 ) {    # 2012 is the Text::CSV_XS EOF code.
	croak(
	    sprintf(
		"Error in tab-delimited format: %s. Bad input was:\n\n%s\n",
		$mess,
		$csv_parser->error_input(),
	    ),
	);
    }
}

###################
# PRIVATE METHODS #
###################

sub _calculate_eol_char {

    my ( $self ) = @_;

    unless ( $self->get_eol_char() ) {
	my ($eols, $eol_char) = $self->_check_linebreaks();
	unless ( $eol_char ) {
	    croak(
		sprintf(
		    "Error: Cannot correctly parse linebreaks in file %s"
			. " (%s unix, %s dos, %s mac)\n",
		    $self->_get_filepath(),
		    $eols->{unix},
		    $eols->{dos},
		    $eols->{mac},
		)
	    );
	}
	$self->set_eol_char( $eol_char );
    }

    if (    ( $self->get_eol_char() eq "\015" )
         && ( $Text::CSV_XS::VERSION < 0.27 ) ) {

	# Mac linebreaks not supported by older versions of Text::CSV_XS.
	die("Error: Mac linebreaks not supported by this version"
	  . " of Text::CSV_XS. Please upgrade to version 0.27 or higher.\n");
    }

    return $self->get_eol_char();
}

sub _construct_csv_parser {

    my ( $self ) = @_;

    # We cache this in a private attribute so each file only gets one
    # parser (better for error trackage).
    unless ( $self->get_csv_parser() ) {
        my $csv_parser = Text::CSV_XS->new(
            {   sep_char    => qq{\t},
                quote_char  => qq{"},                   # default
                escape_char => qq{"},                   # default
                binary      => 1,
                eol         => ( $self->_calculate_eol_char() || "\n" ),
                allow_loose_quotes => 1,
            }
        );
        $self->set_csv_parser( $csv_parser );
    }

    return $self->get_csv_parser();
}

sub _get_filepath {

    my ( $self, $dir ) = @_;

    my $uri = $self->get_uri();

    # Assume file as default URI scheme.
    my $path;
    if ( ! $uri->scheme() || $uri->scheme() eq 'file' ) {

	$uri->scheme('file');

	# URI::File specific, this avoids quoting e.g. spaces in filenames.
	my $uri_path = $uri->file();

	if ( $dir ) {
	    $path = File::Spec->file_name_is_absolute( $uri_path )
		  ? $uri_path
		  : File::Spec->catfile( $dir, $uri_path );
	}
	else {
	    $path = File::Spec->rel2abs( $uri_path );
	}
    }
    # Add the common network URI schemes.
    elsif ( $uri->scheme() eq 'http' || $uri->scheme() eq 'ftp' ) {
	$path = $self->_cache_network_file( $uri, $dir );
    }
    else {
	croak(sprintf(
	    "ERROR: Unsupported URI scheme: %s\n", $uri->scheme(),
	));
    }

    return $path;
}

sub _cache_filehandle {

    my ( $self ) = @_;

    my $fh;
    unless ( $fh = $self->get_filehandle ) {
        my $path = $self->_get_filepath();
        open( $fh, '<', $path )
            or croak(qq{Error: Unable to open file "$path": $!});
        $self->set_filehandle( $fh );
    }

    return $fh;
}
        

sub _cache_network_file {

    my ( $self, $uri, $dir ) = @_;

    require LWP::UserAgent;

    # N.B. we don't handle URI fragments, just the path.
    my ( $basename ) = ( $uri->path() =~ m!/([^/]+) \z!xms );

    my $target;
    if ( $dir ) {
	$target = File::Spec->catfile( $dir, $basename );
    }
    else {
	$target = $basename;
    }

    # Only download the file once.
    unless ( -f $target ) {

	printf STDOUT (
	    qq{Downloading network file "%s"...\n},
	    $uri->as_string(),
	);

	# Download the $uri->as_string()
	my $ua = LWP::UserAgent->new();

	my $response = $ua->get(
	    $uri->as_string(),
	    ':content_file' => $target,
	);

	unless ( $response->is_success() ) {
	    croak(sprintf(
		qq{Error downloading network file "%s" : %s\n},
		$uri->as_string(),
		$response->status_line(),
	    ));
	}
    }

    return $target;
}

sub _check_linebreaks {

    # Checks for Mac, Unix or Dos line endings by reading the whole
    # file in chunks, and regexp matching the various linebreak types.
    # Returns the appropriate linebreak for acceptable line breaks
    # (N.B. line breaks *must* be unanimous), undef for not.

    my ( $self ) = @_;

    my $path = $self->_get_filepath();

    my $bytelength = -s $path;

    my $fh = $self->_cache_filehandle();

    # Count all the line endings. This can get memory intensive
    # (implicit list generation, can be over 1,000,000 entries for
    # Affy CEL). We read the file in defined chunks to address this.
    my ( $unix_count, $mac_count, $dos_count );
    my $chunk_size          = 3_000_000;    # ~10 chunks to a big CEL file.
    my $previous_final_char = q{};
    for ( my $offset = 0; $offset < $bytelength; $offset += $chunk_size ) {

        my $chunk;

	my $bytes_read = read( $fh, $chunk, $chunk_size );

	unless ( defined($bytes_read) ) {
	    croak("Error reading file chunk at offset $offset ($path): $!\n");
	}

	# Lists generated implicitly here.
        $unix_count += () = ( $chunk =~ m{\N{LINE FEED}}g );
        $mac_count  += () = ( $chunk =~ m{\N{CARRIAGE RETURN}}g );
        $dos_count  += () = ( $chunk =~ m{\N{CARRIAGE RETURN}\N{LINE FEED}}g );

        # DOS line endings could conceivably be split between chunks.
	if ( $bytes_read ) {    # Skip if at end of file.
	    if (   ( substr( $chunk, 0, 1 ) eq "\N{LINE FEED}" )
		&& ( $previous_final_char eq "\N{CARRIAGE RETURN}" ) ) {
		$dos_count++;
	    }
	    $previous_final_char = substr( $chunk, -1, 1 );
	}
    }

    seek($fh, 0, 0)
        or croak("Error rewinding file $path in sub _check_linebreaks: $!\n");

    my $dos  = $dos_count;
    my $mac  = $mac_count  - $dos_count;
    my $unix = $unix_count - $dos_count;

    # Set to undef on failure.
    my $line_ending = undef;

    # Determine the file line endings format, return the "standard" line
    # ending to use
    if ( $unix && !$mac && !$dos ) {    # Unix
        $line_ending = "\N{LINE FEED}";
    }
    elsif ( $mac && !$unix && !$dos ) {    # Mac
        $line_ending = "\N{CARRIAGE RETURN}";
    }
    elsif ( $dos && !$mac && !$unix ) {    # DOS
        $line_ending = "\N{CARRIAGE RETURN}\N{LINE FEED}";
    }

    # Calling in scalar context just gives $line_ending.
    my $counts = {
        unix => $unix,
        dos  => $dos,
        mac  => $mac,
    };
    
    return wantarray ? ( $counts, $line_ending ) : $line_ending;
}

# Make the classes immutable. In theory this speeds up object
# instantiation for a small compilation time cost.
__PACKAGE__->meta->make_immutable();

no Moose;

=head1 NAME

Bio::MAGETAB::Util::Reader::Tabfile - An abstract class providing methods for
handling tab-delimited files.

=head1 SYNOPSIS

 use base qw(Bio::MAGETAB::Util::Reader::Tabfile);

=head1 DESCRIPTION

This abstract class acts as a wrapper for the Text::CSV_XS module and
line ending detection code used by the rest of the
Bio::MAGETAB::Util::Reader modules. It is not designed to be used
directly.

=head1 ATTRIBUTES

=over 2

=item uri

Required URI path to the file to be parsed.

=item eol_char

The end-of-line character to use while parsing. Typically this is set
by the Reader subclasses.

=item filehandle

The filehandle for the file being parsed.

=item csv_parser

A Text::CSV_XS parser object.

=item builder

A Bio::MAGETAB::Util::Builder object, used by subclasses to track
MAGE-TAB object creation.

=back

=head1 METHODS

=over 2

=item getline

A simple wrapper for the Text::CSV_XS C<getline()> method which takes
an optional filehandle argument, using the cached filehandle returned
by C<get_filehandle()> as the default. This filehandle argument can be
useful when explicitly controlling the read position of the script
within the file (e.g. as in ADF parsing).

=item can_ignore

When passed an arrayref of column values for a given line, returns 1
if the line is ignorable (typically blank or commented lines fall into
this category) or undef if not.

=item strip_whitespace

This method strips any whitespace surrounding the string values passed
to it in an arrayref.

=item confirm_full_parse

Raises an exception if the file has not been parsed to completion
(i.e., EOF). Takes a line arrayref as returned by
C<$self-E<gt>getline()> as an optional argument to allow testing
for either (a) the existence of a next line in the file, or (b)
EOF. This is useful when pausing parsing partway through a file,
e.g. after parsing the ADF header section.

=back

In addition, each attribute has accessor (get_*) and mutator (set_*) methods.

=head1 SEE ALSO

L<Bio::MAGETAB::Util::Reader>
L<Bio::MAGETAB::Util::Reader::TagValueFile>

=head1 AUTHOR

Tim F. Rayner <tfrayner@gmail.com>

=head1 LICENSE

This library is released under version 2 of the GNU General Public
License (GPL).

=cut

1;
