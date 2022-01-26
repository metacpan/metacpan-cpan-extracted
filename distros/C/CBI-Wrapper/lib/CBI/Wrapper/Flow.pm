##############################################################################
#       
#    Copyright (C) 2012 Agile Business Group sagl (<http://www.agilebg.com>)
#    Copyright (C) 2012 Domsense srl (<http://www.domsense.com>)
#    Copyright (C) 2012 Associazione OpenERP Italia
#    (<http://www.openerp-italia.org>).
#    Copyright (C) 2022 Res Binaria Di Paolo Capaldo (<https://www.resbinaria.com/>)
#    All Rights Reserved
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published
#    by the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

package CBI::Wrapper::Flow;

use warnings;
use strict;

# ABSTRACT: Flow of a CBI file.
# Fixed length file with 120 chars in every row.
# The first and the last rows are the header and the footer;
# among these are the disposals.
# Es.
# IBT123405428040122DEMORIBA                                                                             1$05428  E         <-Header - 1 Record
# 140000001      000000040122300000000000010000-0542811101000000123456                      T1234                 4     E   |
# 200000001A.b.c. S.p.A             Via Biancoverde, 60     Milano                                   01234567897            |
# 300000001Rossi Carlo                                                 A111114111111111                                     |
# 400000001Via Col Vento, 7              90111Milano MI                                                                     | <- Disposizione 1 - 7 Record
# 500000001                  30000                                                                                          |
# 5100000010000000001A.b.c. S.p.A                                                                                           |
# 700000001                                                                                                                 |
# 140000002      000000040122300000000000020000-0542811101000000123456                      T1234                 4     E   *
# 200000002A.b.c. S.p.A             Via Biancoverde, 60     Milano                                   01234567897            *
# 300000002Verdi Mario                                                 B111114111111111                                     *
# 400000002Via Garibaldi, 8              90112Firenze Fi                                                                    * <- Disposizione 2 - 7 Record
# 500000002                  30000                                                                                          *
# 5100000020000000002A.b.c. S.p.A                                                                                           *
# 700000002                                                                                                                 *
# 140000003      000000040122300000000000030000-0542811101000000123456                      T1234                 4     E   +
# 200000003A.b.c. S.p.A             Via Biancoverde, 60     Milano                                   01234567897            +
# 300000003Bianchi Alberto                                             C111114111111111                                     +
# 400000003Via Frosinone, 11             90113Torino To                                                                     + <- Disposizione 3 - 7 Record
# 500000003                  30000                                                                                          +
# 5100000030000000003A.b.c. S.p.A                                                                                           +
# 700000003                                                                                                                 +
# EFT123405428040122DEMORIBA                  00000030000000000000000000000000600000000023                        E000000   <- Footer - 1 Record

use CBI::Wrapper::Field;
use CBI::Wrapper::Record;
use CBI::Wrapper::RecordMapping;
use CBI::Wrapper::Disposal;

use Scalar::Util;
use Carp;

use Encode;
use Text::Unidecode;

sub new {
	my $class = shift;
	my $self = {
        _disposals   => shift, 
	_header     => shift,  
        _footer     => shift,  
	};

	bless $self, $class;
	
    $self->set_disposals([]) unless defined $self->get_disposals(); 

	return $self;
}

# Getters and Setters.
sub set_header {
    my( $self, $header) = @_;

    $self->{_header} = $header;
}

sub get_header {
    my( $self) = @_;

    return $self->{_header};
}

sub set_footer {
    my( $self, $footer) = @_;

    $self->{_footer} = $footer;
}

sub get_footer {
    my( $self) = @_;

    return $self->{_footer};
}

sub set_disposals {
    my( $self, $disposals) = @_;

    $self->{_disposals} = $disposals;
}

sub get_disposals {
    my( $self) = @_;

    return $self->{_disposals};
}

# Read and load a cbi file the current flow.
sub read_file {
    my( $self, $file_path, $first_record_identifier, $flow_type) = @_; 

    open my $fh, '<', $file_path or croak('[SystemError] Cannot open file');
    my $file_str = do { local $/; <$fh>};
    close ($fh);

    # Default Values.
    $first_record_identifier = '14' unless defined $first_record_identifier; 
    $flow_type = $CBI::Wrapper::RecordMapping::FLOW_TYPE unless defined $flow_type;
   
    # Manage end of line chars in DOS and UNIX.
    $file_str =~ s/\r/\n/g;
    $file_str =~ s/\n\n/\n/g;
    my @rows = split("\n", $file_str);
    if (scalar(@rows) < 3) {
        croak('[TypeError] Insufficient number of rows');
    }
    $self->set_header(new CBI::Wrapper::Record($rows[0], $flow_type));                 
    $self->set_footer(new CBI::Wrapper::Record($rows[scalar(@rows) - 1], $flow_type)); 
    $self->set_disposals([]);
    
    my $current_disposal = new CBI::Wrapper::Disposal();
    # Add records to the current disposal until a new start record is found; 
    # then create a new disposal and start reading the records again.
    for my $row (@rows[1..(scalar(@rows)-2)]) {
        my $record = new CBI::Wrapper::Record($row, $flow_type);
        if ($record->get_field_content('tipo_record') eq $first_record_identifier
            and scalar(@{$current_disposal->get_records()}) > 0) {
                my $disposals = $self->get_disposals();
                push(@$disposals, $current_disposal);
                $self->set_disposals($disposals);
                $current_disposal = new CBI::Wrapper::Disposal();
            }
        $current_disposal->append_record($record);
    }
    if (scalar(@{$current_disposal->get_records()}) > 0) {
        my $disposals = $self->get_disposals();
        push(@$disposals, $current_disposal);
        $self->set_disposals($disposals);
    }

    # Check if every disposal has the start record.
    my $last_record_found = 0;
    for my $disposal (@{$self->get_disposals()}) {
        for my $r (@{$disposal->get_records()}) {
            if ($first_record_identifier eq $r->get_field_content('tipo_record')) {
                $last_record_found = 1;        
            }
        }
    }
    unless ($last_record_found) {
        $self->set_disposals([]);
        croak('[IndexError] First record identifier ' . $first_record_identifier . ' for disposals not found');
    }
}

# Write current flow on file.
sub write_file {
    my( $self, $file_path) = @_;     

    open my $fh, '>', $file_path or croak('[SystemError] Cannot open file');

    my $header = $self->get_header();
    $header = $header->to_string();
    $header = Encode::decode_utf8($header);
    $header = Text::Unidecode::unidecode($header);
    print $fh ($header . "\r\n");
    for my $disposal (@{$self->get_disposals()}) {
        for my $record (@{$disposal->get_records()}) {
            my $row = $record->to_string();
            $row = Encode::decode_utf8($row);
            $row = Text::Unidecode::unidecode($row);
            print $fh ($row . "\r\n");
        }
    }
    my $footer = $self->get_footer(); 
    $footer = $footer->to_string();
    $footer = Encode::decode_utf8($footer);
    $footer = Text::Unidecode::unidecode($footer);
    print $fh ($footer . "\r\n");
    
    close $fh;
}


# Add a disposal in the flow.
sub append_disposal {
    my( $self, $disposal) = @_;

    my $disposals = $self->get_disposals();
    push(@$disposals, $disposal);
    $self->set_disposals($disposals);
}


1;
