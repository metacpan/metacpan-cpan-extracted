package Bio::NEXUS::Import;

use warnings;
use strict;
use Carp;

use Bio::NEXUS;
use Bio::NEXUS::Functions;

use base 'Bio::NEXUS';

use version; our $VERSION = qv('0.2.0');

sub new {
    my ( $class, $filename, $fileformat, $verbose ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{'supported_file_formats'} = {
        'phylip' => {
            'PHYLIP_DIST_SQUARE'           => 1,
            'PHYLIP_DIST_LOWER'            => 1,
            'PHYLIP_DIST_SQUARE_BLANK'     => 1,
            'PHYLIP_DIST_LOWER_BLANK'      => 1,
            'PHYLIP_DIST_UPPER'            => 1,
            'PHYLIP_SEQ_INTERLEAVED'       => 1,
            'PHYLIP_SEQ_SEQUENTIAL'        => 1,
            'PHYLIP_SEQ_INTERLEAVED_BLANK' => 1,
            'PHYLIP_SEQ_SEQUENTIAL_BLANK'  => 1,
        },
        'nexus' => { 'NEXUS' => 1 },
    };
    if ( defined $filename ) {
        $self->import_file( $filename, $fileformat, $verbose );
        $self->set_name($filename);
    }
    return $self;
}

sub _say {
    my ( $self, $msg ) = @_;
    print "$msg\n" or croak q{Can't write to Terminal};
    return;
}

sub import_file {
    my ( $self, $filename, $fileformat, $verbose ) = @_;
    if ( !-e $filename ) {
        croak "ERROR: $filename is not a valid filename\n";
    }
    my @filecontent = split /\n/xms,
        $self->_load_file(
        {   'format'  => 'filename',
            'param'   => $filename,
            'verbose' => $verbose,
        }
        );
    if ( !defined $fileformat ) {
        if ($verbose) {
            $self->_say("Trying to detect format of $self->{filename}");
        }
        $fileformat = $self->_detect_fileformat( \@filecontent );
        if ($verbose) {
            $self->_say("$fileformat detected");
        }
    }
    my $sff = $self->{'supported_file_formats'};
    if ( defined $sff->{'phylip'}->{$fileformat} ) {
        $self->_import_phylip(
            {   'filecontent' => \@filecontent,
                'param'       => $filename,
                'verbose'     => $verbose,
                'fileformat'  => $fileformat,
            }
        );
    }
    elsif ( defined $sff->{'nexus'}->{$fileformat} ) {
        $self->read_file( $filename, $verbose );
    }
    else {
        croak "ERROR: $fileformat is not supported.\n";
    }
    return;
}

sub _detect_fileformat {
    my ( $self, $filecontent ) = @_;
    if ( $filecontent->[0] =~ m{\A \s* (\d+)\s+(\d+) \s* \z}xms ) {
        if ( $filecontent->[2] =~ m{\A [\sAGCTU]+ \z }xmsi ) {
            return 'PHYLIP_SEQ_SEQUENTIAL';
        }
        else {
            return 'PHYLIP_SEQ_INTERLEAVED';
        }
    }
    elsif ( $filecontent->[0] =~ m{\A \s* (\d+) \s* \z}xms ) {
        my $number_taxa = $1;
        my @fields = split( /\s+/, $filecontent->[1] );
        if ( length $filecontent->[1] <= 10
            || scalar(@fields) == 1 )
        {
            for my $i ( 1 .. ( scalar( @{$filecontent} ) - 1 ) ) {
                my @fields2 = split( /\s+/, $filecontent->[$i] );
                if ( scalar @fields2 != $i ) {
                    return 'PHYLIP_DIST_LOWER';
                }
            }
            return 'PHYLIP_DIST_LOWER_BLANK';
        }
        else {
            for my $i ( 1 .. ( scalar( @{$filecontent} ) - 1 ) ) {
                my @fields2 = split( /\s+/, $filecontent->[$i] );
                if ( scalar @fields2 != $number_taxa + 1 ) {
                    return 'PHYLIP_DIST_SQUARE';
                }
            }
            return 'PHYLIP_DIST_SQUARE_BLANK';
        }
    }
    elsif ( $filecontent->[0] =~ m{\A \s* \#NEXUS \s* \z}xms ) {
        return 'NEXUS';
    }
    else {
        croak("ERROR: Could not detect file format.\n");
    }
}

sub _load_file {
    my ( $self, $args ) = @_;
    $args->{'format'} ||= 'string';
    $args->{'param'}  ||= q{};
    my $verbose = $args->{'verbose'} || 0;
    my $file;
    my $filename;

    if ( lc $args->{'format'} eq 'string' ) {
        $file = $args->{'param'};
    }
    else {
        $filename = $args->{'param'};
        $file     = _slurp($filename);
    }

    # Read entire file into scalar $import_file
    if ($verbose) {
        $self->_say('Reading file...');
    }
    $self->{'filename'} = $filename;
    return $file;
}

sub _import_phylip {
    my ( $self, $args ) = @_;

    my $filename = $self->{'filename'};

    $args->{'fileformat'} ||= '_dist_square';
    my $ff = $args->{'fileformat'};
    $ff = lc $ff;
    my $verbose       = $args->{'verbose'} || 0;
    my $line_number   = 0;
    my $taxon_started = 0;
    my $taxon_id      = -1;
    my ( $number_taxa, $number_chars, @taxdata, @taxlabels );
LINE:

    for my $line ( @{ $args->{'filecontent'} } ) {
        $line_number++;

        #remove newline, leading and trailing whitespaces
        chomp $line;
        $line =~ s{\s+ \z}{}xms;

        next LINE if $line eq q{};

        if ( $line_number == 1 ) {

            if ( $ff =~ m{dist}xms ) {
                ($number_taxa) = $line =~ m{\A \s* (\d+) \s* \z}xms;
            }
            else {

                # sequence data has the number of characters in the first line
                ( $number_taxa, $number_chars )
                    = $line =~ m{\A \s* (\d+)\s+(\d+) \s* \z}xms;
                if ( !defined $number_chars ) {
                    croak(
                        "ERROR: First line must contain number of characters.\n"
                    );
                }
            }
            if ( !defined $number_taxa ) {
                croak("ERROR: First line must contain number of taxa.\n");
            }
            next LINE;
        }
        if ( !$taxon_started ) {
            $taxon_id++;

            my ( $label, $data );

            if ( $ff =~ m{blank\z}xms ) {
                ( $label, $data ) = $line =~ m{ \A (.*?)\s+(.*) \z }xms;
            }
            else {

                # first 10 chars are the labels
                ( $label, $data ) = $line =~ m{ \A (.{10})(.*) \z }xms;
            }

            # undefined? then we have only one label, no data
            # for example in the first row of a lower distmatrix
            if ( !defined $label ) {
                $label = $line;
                $data  = q{};
            }

            #remove leading and trailing whitespaces
            $label =~ s{\A \s+}{}xms;
            $label =~ s{\s+ \z}{}xms;

            $label =~ s{-|\s}{_}xms;

            $data =~ s{\A \s+}{}xms;
            my @taxondata = split /\s+/xms, $data;

            $taxdata[$taxon_id] = [@taxondata];
            push @taxlabels, $label;
        }
        else {
            my @taxondata = @{ $taxdata[$taxon_id] };
            $line =~ s{\A \s+}{}xms;
            push @taxondata, ( split /\s+/xms, $line );
            $taxdata[$taxon_id] = [@taxondata];
        }

        if ( $ff =~ m{dist}xms ) {

            # how many tab/space seperated items do we expect?
            my $number_items_in_row;
            if ( $ff =~ m{_dist_square}xms ) {
                $number_items_in_row = $number_taxa;
            }
            elsif ( $ff =~ m{_dist_lower}xms ) {
                $number_items_in_row = $taxon_id;
            }
            elsif ( $ff =~ m{_dist_upper}xms ) {
                $number_items_in_row = $number_taxa - ( $taxon_id + 1 );
            }

            if ( scalar( @{ $taxdata[$taxon_id] } ) < $number_items_in_row ) {
                $taxon_started = 1;
            }
            else {
                $taxon_started = 0;
            }
        }
        else {
            my $seq = join q{}, @{ $taxdata[$taxon_id] };
            if ( $ff =~ m{_seq_seq}xms ) {
                if ( length $seq < $number_chars ) {
                    $taxon_started = 1;
                }
                else {
                    $taxon_started = 0;
                }
            }

            next LINE if $ff =~ m{_seq_seq}xms;

            # interleaved
            if ( scalar(@taxlabels) == $number_taxa ) {
                if ( $taxon_id >= ( $number_taxa - 1 ) ) {
                    $taxon_id = 0;
                }
                else {
                    $taxon_id++;
                }
                $taxon_started = 1;
            }
        }
    }
    croak "ERROR: Could not parse $filename. Number taxa not correct.\n"
        if scalar(@taxlabels) != $number_taxa;

    $self->_create_nexus_obj( $ff, \@taxlabels, \@taxdata, $number_taxa );

    if ($verbose) {
        $self->say('File import complete.');
    }
    return $self;
}

sub _create_nexus_obj {
    my ( $self, $ff, $taxlabels_ref, $taxdata_ref, $number_taxa ) = @_;

    my $taxa_block = Bio::NEXUS::TaxaBlock->new('taxa');
    $taxa_block->set_taxlabels($taxlabels_ref);
    $self->add_block($taxa_block);

    if ( $ff =~ m{dist}xms ) {
        my $distances_block = Bio::NEXUS::DistancesBlock->new('distances');
        $distances_block->set_ntax( scalar @{$taxlabels_ref} );
        $distances_block->set_taxlabels($taxlabels_ref);
        $distances_block->set_format(
            { triangle => 'lower', diagonal => 1, labels => 1 } );
        my $matrix;
        for my $i ( 0 .. $distances_block->get_ntax - 1 ) {
            for my $j ( 0 .. $distances_block->get_ntax - 1 ) {
                my $dist;
                if ( defined $taxdata_ref->[$i]->[$j] ) {
                    $dist = $taxdata_ref->[$i]->[$j];
                }
                else {
                    $dist = $taxdata_ref->[$j]->[$i];

                    # diag. entries:
                    if ( !defined $dist ) {
                        $dist = 0;
                    }
                }
                $matrix->{ $taxlabels_ref->[$i] }{ $taxlabels_ref->[$j] }
                    = $dist;
            }
        }
        $distances_block->{matrix} = $matrix;

        #        $distances_block->_write_matrix();

        $self->add_block($distances_block);
    }
    else {
        my $chars_block = Bio::NEXUS::CharactersBlock->new('characters');
        my %taxa;
        for my $i ( 0 .. $number_taxa - 1 ) {
            $taxa{ $taxlabels_ref->[$i] } = join q{}, @{ $taxdata_ref->[$i] };
        }

        my (@otus);

        for my $name ( @{$taxlabels_ref} ) {
            my $seq = $taxa{$name};
            push @otus,
                Bio::NEXUS::TaxUnit->new( $name, [ split //xms, $seq ] );
        }

        my $otuset = $chars_block->get_otuset();
        $otuset->set_otus( \@otus );
        $chars_block->set_taxlabels( $otuset->get_otu_names() );

        $self->add_block($chars_block);
    }
    return;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::NEXUS::Import - Extends Bio::NEXUS with parsers for file formats of
popular phylogeny programs


=head1 VERSION

This document describes Bio::NEXUS::Import version 0.1.0


=head1 SYNOPSIS

    use Bio::NEXUS::Import;

    # a PHYLIP-TO-NEXUS converter:
    #
    # load a PHYLIP file
    my $nexus = Bio::NEXUS::Import->new('example.phy');
    
    # and write it as NEXUS formatted file
    $nexus->write('example.nex');

=head1 DESCRIPTION

A module that extends L<Bio::NEXUS> with parsers for file formats of popular 
phylogeny programs. 

=head1 INTERFACE 

=head2 new

 Title   : new
 Usage   : Bio::NEXUS::Import->new($filename, $fileformat, $verbose);
 Function: If $filename is defined, then this function calls import_file 
 Returns : an Bio::NEXUS object
 Args    : $filename, $fileformat, $verbose, or none
 See also: import_file for a list of supported fileformats, for examples see
           APPENDIX: SUPPORTED FILE FORMATS.


=head2 import_file

 Title   : import_file
 Usage   : Bio::NEXUS::Import->import_file($filename, $fileformat, $verbose);
 Function: Reads the contents of the specified file and populate the data 
           in the Bio::NEXUS object.
           Supported fileformats are NEXUS, PHYLIP_DIST_SQUARE, 
           PHYLIP_DIST_SQUARE_BLANK, PHYLIP_DIST_LOWER,
           PHYLIP_DIST_LOWER_BLANK, PHYLIP_SEQ_INTERLEAVED,
           PHYLIP_SEQ_INTERLEAVED_BLANK, PHYLIP_SEQ_SEQUENTIAL, 
           PHYLIP_SEQ_SEQUENTIAL_BLANK.
           If $fileformat is not defined, then this function tries to
           detect the correct format. NEXUS files are parsed with
           Bio::NEXUS->read_file();
 Returns : None
 Args    : $filename,  optional: $fileformat, $verbose. 


=head1 DIAGNOSTICS


=over

=item C<< ERROR: $filename is not a valid filename. >>

The file you have specified in L</"new"> or L</"import_file"> does not exist.

=item C<< ERROR: $fileformat is not supported. >>

The fileformat you have specified in L</"new"> or L</"import_file"> is not supported.
See L<"APPENDIX: SUPPORTED FILE FORMATS"> for a list of supported formats.

=item C<< ERROR: First line must contain number of taxa. >>

You tried to import a file with the PHYLIP parser but the file does not look like a 
PHYLIP file. See L<"APPENDIX: SUPPORTED FILE FORMATS"> for valid PHYLIP files.

=item C<< ERROR: First line must contain number of characters. >>

You tried to import a file with the PHYLIP parser for sequence data but the file does
not look like a PHYLIP file. See L<"APPENDIX: SUPPORTED FILE FORMATS"> for valid PHYLIP files.

=item C<< ERROR: Could not parse $filename. Number taxa not correct. >> 

There is a different number of taxa in the PHYLIP file than specified in the
header. Check your input file.


=item C<< ERROR: Could not detect file format. >>

You haven't specified a file format and Bio::NEXUS::Import could not detect
the format of your file.


=back


=head1 CONFIGURATION AND ENVIRONMENT

Bio::NEXUS::Import requires no configuration files or environment variables.


=head1 DEPENDENCIES


L<Bio::NEXUS> 


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bio-nexus-import@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Bio::NEXUS>, L<Bio::Phylo>.

The PHYLIP program C<seqboot> can also convert a PHYLIP molecular
sequences or discrete characters morphology data file into the NEXUS format.


=head1 APPENDIX: SUPPORTED FILE FORMATS

This appendix lists examples of all supported file formats. The PHYLIP_*_BLANK
formats are modifications of the PHYLIP formats to support longer labels than
the 10 characters. The end of a label is marked with a white space
character such as a blank.

=over

=item C<PHYLIP_DIST_SQUARE>


        5
    Alpha      0.000 1.000 2.000 3.000 3.000
    Beta       1.000 0.000 2.000 3.000 3.000
    Gamma      2.000 2.000 0.000 3.000 3.000
    Delta      3.000 3.000 0.000 0.000 1.000
    Epsilon    3.000 3.000 3.000 1.000 0.000


=item C<PHYLIP_DIST_SQUARE_BLANK>

        5
    Alpha_Long_Taxon 0.000 1.000 2.000 3.000 3.000
    Beta 1.000 0.000 2.000 3.000 3.000
    Gamma 2.000 2.000 0.000 3.000 3.000
    Delta 3.000 3.000 0.000 0.000 1.000
    Epsilon 3.000 3.000 3.000 1.000 0.000


=item C<PHYLIP_DIST_LOWER>


        5
    Alpha      
    Beta       1.00
    Gamma      3.00 3.00
    Delta      3.00 3.00 2.00
    Epsilon    3.00 3.00 2.00 1.00

=item C<PHYLIP_DIST_LOWER_BLANK>


        5
    Alpha_Long_Taxon      
    Beta       1.00
    Gamma      3.00 3.00
    Delta      3.00 3.00 2.00
    Epsilon    3.00 3.00 2.00 1.00


=item C<PHYLIP_SEQ_INTERLEAVED>


        5    42
    Turkey    AAGCTNGGGC ATTTCAGGGT
    Salmo gairAAGCCTTGGC AGTGCAGGGT
    H. SapiensACCGGTTGGC CGTTCAGGGT
    Chimp     AAACCCTTGC CGTTACGCTT
    Gorilla   AAACCCTTGC CGGTACGCTT

    GAGCCCGGGC AATACAGGGT AT
    GAGCCGTGGC CGGGCACGGT AT
    ACAGGTTGGC CGTTCAGGGT AA
    AAACCGAGGC CGGGACACTC AT
    AAACCATTGC CGGTACGCTT AA

=item C<PHYLIP_SEQ_SEQUENTIAL>


        5    42
    Turkey    AAGCTNGGGC ATTTCAGGGT
    GAGCCCGGGC AATACAGGGT AT
    Salmo gairAAGCCTTGGC AGTGCAGGGT
    GAGCCGTGGC CGGGCACGGT AT
    H. SapiensACCGGTTGGC CGTTCAGGGT
    ACAGGTTGGC CGTTCAGGGT AA
    Chimp     AAACCCTTGC CGTTACGCTT
    AAACCGAGGC CGGGACACTC AT
    Gorilla   AAACCCTTGC CGGTACGCTT
    AAACCATTGC CGGTACGCTT AA

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2011, C<< <limaone@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
