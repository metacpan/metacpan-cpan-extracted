package Compress::DSRC;

use 5.012;
use strict;
use warnings;

our $VERSION = "0.003";

require XSLoader;
XSLoader::load('Compress::DSRC', $VERSION);

# define an alternative, more Perl-ish interface to Reader
*Compress::DSRC::Reader::next_record = sub {

    my ($self) = @_;

    my $read = Compress::DSRC::Record->new();
    my $bool = $self->read_record($read);

    return $bool ? $read : undef;

};

1;

__END__

=head1 NAME

Compress::DSRC - Perl bindings to the DSRC compression library

=head1 SYNOPSIS

Single-shot (de)compression

    use Compress::DSRC;

    my $engine   = Compress::DSRC::Module->new;
    my $settings = Compress::DSRC::Settings->new;
    my $threads  = 8;

    $settings->set_dna_level(2);
    $settings->set_lossy(1);
    $engine->compress(
        'foo.fq' => 'foo.fq.dsrc',
         $settings,
         $threads,
    ) or die $engine->error;
    $engine->decompress(
        'foo.fq.dsrc' => 'bar.fq',
         $threads,
    ) or die $engine->error;

Per-record (de)compression

    use Compress::DSRC;

    my $reader = Compress::DSRC::Reader->new;

    $reader->start( 'bar.fq.dsrc', $threads,)
        or die $reader->error;

    my $record = Compress::DSRC::Record->new;
    while ($reader->read_record($record) {
        print $record->get_tag,      "\n";
        print $record->get_sequence, "\n";
        print $record->get_plus,     "\n";
        print $record->get_quality,  "\n";
        # or, more likely, do something else with record
    }
    $reader->finish;


=head1 DESCRIPTION

This module provides bindings to the DSRC compression library. It provides
basic access to the DsrcModule (one-shot (de)compression) and DsrcArchive
(record-by-record (de)compression) APIs. 

=head1 CLASSES

C<Compress::DSRC> provides the following classes used in compression and
decompression:

=over 4

=item C<Compress::DSRC::Module>

Objects of this class are used for one-shot compression and decompression
(providing an input filename and output filename, along with some other
optional parameters).

=item C<Compress::DSRC::Reader>

Objects of this class are used to read record-by-record from a compressed
archive.

=item C<Compress::DSRC::Writer>

Objects of this class are used to writer record-by-record to a compressed
archive.

=item C<Compress::DSRC::Settings>

Objects of this class contain compression settings and are provided as
arguments to several methods that write compressed data.

=item C<Compress::DSRC::Record>

Objects of this class contain a single FASTQ record with accessors to each of
the four data slots.

=back

=head1 METHODS

=head2 Compress::DSRC::Module

=over 4

=item new

    my $engine = Compress::DSRC::Module->new;

Creates a new one-shot (de)compression engine

=item compress

    $engine->compress(
        'foo.fq',
        'foo.fq.dsrc',
        $settings,
        $threads,
    ) or die $engine->error;

Compress a FASTQ file in one shot. Required arguments are (in order) input filename,
output filename, and a C<Compress::DSRC::Settings> object. Number of threads
to use for compression is an optional fourth argument (default: 1).

=item decompress

    $engine->decompress(
        'foo.fq.dsrc',
        'foo.fq',
        $threads,
    ) or die $engine->error;

As with C<compress()> but in the other direction. Required arguments are (in
order) input filename and output filename. Number of threads to use for
decompression is an optional third argument (default: 1).

=item error

If an error occurs, a description can be retrieving using this method.

=back 

=head2 Compress::DSRC::Reader

=over 4
    
=item new

    my $reader = Compress::DSRC::Reader->new;

Create a new Reader object

=item start

    $reader->start( 'foo.fq', $threads );

Initialize a decompression session. Arguments are the input filename
(required) and the number of threads to use (default: 1).
        
=item read_record

    while ($reader->read_record( $record )) {
        # do something with $record;
    }

Read the next record in the file. A single argument is expected - a
Compress::DSRC::Record object whose data slots will be populated from the
record read.

=item next_record

    while (my $record = $reader->next_record()) {
        # do something with $record;
    }

This provides a slightly more Perl-ish alternative to C<read_record()> for
those who prefer it, at the cost of ~ 1.5x longer run times (a new
Compress::DSRC::Record object is generated for each call).

=item finish

    $reader->finish;

Finalize the session.
    
=item error

If an error occurs, a description can be retrieving using this method.

=back

=head2 Compress::DSRC::Writer

=over 4
    
=item new

    my $writer = Compress::DSRC::Writer->new;

Create a new Writer object

=item start

    $writer->start( 'foo.fq', $settings, $threads );

Initialize a compression session. Arguments are the input filename and 
Compress::DSRC::Settings object (required) and the number of threads to use (default: 1).
        
=item write_record

    $writer->write_record( $record );

Write a record to file. A single argument is expected - a
Compress::DSRC::Record object.

=item finish

    $writer->finish;

Finalize the session.
    
=item error

If an error occurs, a description can be retrieving using this method.

=back

=head2 Compress::DSRC::Record

The underlying class is a C++ struct, so all methods are accessors to class
member variables. See FASTQ documentation for more information. C<get_plus>
and C<set_plus> will be rarely used (This slot in the FASTQ specification is
generally redundant and usually empty) but are included for completeness.

    my $record = Compress::DSRC::Record->new;
    $record->set_tag( '@read1 other info' );
    $records->set_sequence( 'ATGGCCTA' );
    $records->set_quality( '998398A8' );
    # do something with $record;

=over 4

=item get_tag / set_tag

=item get_sequence / set_sequence

=item get_plus / set_plus

=item get_quality / set_quality

=back

=head2 Compress::DSRC::Settings

The underlying class is a C++ struct, so all methods are accessors to class
member variables. For more information on the meaning of settings, see DSRC
documentation.

=over 4

=item get_dna_level / set_dna_level

Get/set the DNA compression level.

=item get_qual_level / set_qual_level

Get/set the quality compression level.

=item get_lossy / set_lossy

Get/set whether to use lossy (binning) quality compression

=item get_calc_crc32 / set_calc_crc32

Get/set whether to do CRC32 checking during compression

=item get_buffer_size / set_buffer_size

See DSRC documentation.

=item get_tag_mask / set_tag_mask

See DSRC documentation.

=back

=head1 DEPENDENCIES

Requires a C++ compiler and the Boost system/thread libraries. There are no
other external dependencies.

=head1 CAVEATS AND BUGS

Currently the underlying C++ library (and thus this module) does not handle the edge case of a FASTQ
file containing a single record. A bug report has been filed upstream.

Please report bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
