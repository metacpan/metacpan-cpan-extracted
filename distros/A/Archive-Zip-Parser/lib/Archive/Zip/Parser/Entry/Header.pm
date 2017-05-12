package Archive::Zip::Parser::Entry::Header;

use warnings;
use strict;
use Data::ParseBinary;

sub get_signature {
    my $self = shift;
    return unpack( 'H*', pack( 'N', $self->{'_signature'} ) );
}

sub get_version_needed {
    my ( $self, $argref ) = @_;

    my $version_needed =
      int( $self->{'_version_needed'} / 10 ) . '.'
      . $self->{'_version_needed'} % 10;
    if ( $argref->{'describe'} ) {
        my %version_description_mapping = (
            '1.0' => 'Default value',
            '1.1' => 'File is a volume label',
            '2.0' => join( ', ',
                'File is a folder (directory)',
                'File is compressed using Deflate compression',
                'File is encrypted using traditional PKWARE encryption',
            ),
            '2.1' => 'File is compressed using Deflate64(tm)',
            '2.5' => 'File is compressed using PKWARE DCL Implode ',
            '2.7' => 'File is a patch data set ',
            '4.5' => 'File uses ZIP64 format extensions',
            '4.6' => 'File is compressed using BZIP2 compression*',
            '5.0' => join( ', ',
                'File is encrypted using DES',
                'File is encrypted using 3DES',
                'File is encrypted using original RC2 encryption',
                'File is encrypted using RC4 encryption',
            ),
            '5.1' => join( ', ',
                'File is encrypted using AES encryption',
                'File is encrypted using corrected RC2 encryption',
            ),
            '5.2' => 'File is encrypted using corrected RC2-64 encryption',
            '6.1' => 'File is encrypted using non-OAEP key wrapping',
            '6.2' => 'Central directory encryption',
            '6.3' => join( ', ',
                'File is compressed using LZMA',
                'File is compressed using PPMd',
                'File is encrypted using Blowfish',
                'File is encrypted using Twofish',
            ),
        );
        return $version_description_mapping{$version_needed};
    }

    return $version_needed;
}

sub get_gp_bit {
    my ( $self, $argref ) = @_;

    my @bits;
    for ( 0 .. 15 ) {
        push @bits, $self->{'_gp_bit'}->{"_bit_$_"};
    }

    if ( $argref->{'describe'} ) {
        my @gp_bit_descriptions;

        if ( $bits[0] ) {
            push @gp_bit_descriptions, 'File is encrypted';
        }

        if ( $self->{'_compression_method'} == 6 ) {
            if ( $bits[1] ) {
                push @gp_bit_descriptions, '8K sliding dictionary';
            }
            else {
                push @gp_bit_descriptions, '4K sliding dictionary';
            }
            if ( $bits[2] ) {
                push @gp_bit_descriptions,
                  '3 Shannon-Fano trees were used to encode the sliding dictionary output';
            }
            else {
                push @gp_bit_descriptions,
                  '2 Shannon-Fano trees were used to encode the sliding dictionary output';
            }
        }
        elsif ( $self->{'_compression_method'} == 8 ) {
            if ( $self->{'_compression_method'} == 9 ) {
                if ( !$bits[2] && !$bits[1] ) {
                    push @gp_bit_descriptions,
                      'Normal (-en) compression option was used';
                }
                elsif ( !$bits[2] && $bits[1] ) {
                    push @gp_bit_descriptions,
                      'Maximum (-exx/-ex) compression option was used';
                }
                elsif ( $bits[2] && !$bits[1] ) {
                    push @gp_bit_descriptions,
                      'Fast (-ef) compression option was used';
                }
                elsif ( $bits[2] && $bits[1] ) {
                    push @gp_bit_descriptions,
                      'Super Fast (-es) compression option was used';
                }
            }

            if ( $bits[4] ) {
                push @gp_bit_descriptions, 'Enhanced deflating';
            }
        }
        elsif ( $self->{'_compression_method'} == 14 ) {
            if ( $bits[1] ) {
                push @gp_bit_descriptions,
                  'End-of-stream (EOS) marker is used to mark the end of the compressed data stream';
            }
            else {
                push @gp_bit_descriptions,
                  'End-of-stream (EOS) marker is not present and the compressed data size must be known to extract';
            }
        }

        if ( $bits[3] ) {
            push @gp_bit_descriptions,
              'Data descriptor contains CRC-32, compressed size and uncompressed size';
        }

        if ( $bits[5] && $self->{'_version_needed'} >= 27 ) {
            push @gp_bit_descriptions, 'Compressed patched data';
        }

        if ( $bits[6] && $self->{'_version_needed'} >= 50 && $bits[0] ) {
            push @gp_bit_descriptions, 'Strong encryption';
        }

        if ( $bits[11] ) {
            push @gp_bit_descriptions,
              'Filename and comment fields are encoded using UTF-8';
        }
        if ( $bits[12] ) {
            push @gp_bit_descriptions, 'Enhanced compression';
        }

        if ( $bits[13] ) {
            push @gp_bit_descriptions,
              'Selected data values in the Local Header are masked';
        }

        return @gp_bit_descriptions;
    }

    return @bits;
}

sub get_compression_method {
    my ( $self, $argref ) = @_;

    if ( $argref->{'describe'} ) {
        my %compression_method_description_mapping = (
            '0'  => 'The file is stored (no compression)',
            '1'  => 'The file is Shrunk',
            '2'  => 'The file is Reduced with compression factor 1',
            '3'  => 'The file is Reduced with compression factor 2',
            '4'  => 'The file is Reduced with compression factor 3',
            '5'  => 'The file is Reduced with compression factor 4',
            '6'  => 'The file is Imploded',
            '7'  => 'Reserved for Tokenizing compression algorithm',
            '8'  => 'The file is Deflated',
            '9'  => 'Enhanced Deflating using Deflate64(tm)',
            '10' => 'PKWARE Data Compression Library Imploding (old IBM TERSE)',
            '11' => 'Reserved by PKWARE',
            '12' => 'File is compressed using BZIP2 algorithm',
            '13' => 'Reserved by PKWARE',
            '14' => 'LZMA (EFS)',
            '15' => 'Reserved by PKWARE',
            '16' => 'Reserved by PKWARE',
            '17' => 'Reserved by PKWARE',
            '18' => 'File is compressed using IBM TERSE (new)',
            '19' => 'IBM LZ77 z Architecture (PFS)',
            '97' => 'WavPack compressed data',
            '98' => 'PPMd version I, Rev 1',
        );

        return $compression_method_description_mapping{ $self->{'_compression_method'} };
    }

    return $self->{'_compression_method'};
}

sub get_last_mod_time {
    my $self = shift;
    my $last_mod_time = pack 'n', $self->{'_last_mod_time'};

    my $last_mod_time_struct = BitStruct(
        'last_mod_time',
        BitField( 'hour',   5 ),
        BitField( 'minute', 6 ),
        BitField( 'second', 5 ),
    );
    my $parsed_last_mod_time_struct
      = $last_mod_time_struct->parse($last_mod_time);

    return %{$parsed_last_mod_time_struct};
}

sub get_last_mod_date {
    my $self = shift;
    my $last_mod_date = pack 'n', $self->{'_last_mod_date'};

    my $last_mod_date_struct = BitStruct(
        'last_mod_date',
        BitField( 'year',  7 ),
        BitField( 'month', 4 ),
        BitField( 'day',   5 ),
    );
    my $parsed_last_mod_date_struct
      = $last_mod_date_struct->parse($last_mod_date);
    $parsed_last_mod_date_struct->{'year'} += 1980;

    return %{$parsed_last_mod_date_struct};
}

sub get_crc_32 {
    my $self = shift;
    return unpack( 'H*', pack( 'N', $self->{'_crc_32'} ) );
}

sub get_compressed_size {
    my $self = shift;
    return $self->{'_compressed_size'};
}

sub get_uncompressed_size {
    my $self = shift;
    return $self->{'_uncompressed_size'};
}

sub get_file_name_length {
    my $self = shift;
    return $self->{'_file_name_length'};
}

sub get_extra_field_length {
    my $self = shift;
    return $self->{'_extra_field_length'};
}

sub get_file_name {
    my $self = shift;
    return $self->{'_file_name'};
}

sub get_extra_field {
    my ( $self, $argref ) = @_;

    my $extra_field
        = Struct(
            '_extra_field',
            RepeatUntil(
                sub {
                    $_->obj->{'_position'} == $self->{'_extra_field_length'};
                },
                Struct(
                    '_header',
                    ULInt16('_id'),
                    ULInt16('_size'),
                    Field(
                        '_data',
                        sub {
                            $_->ctx->{'_size'}
                        }
                    ),
                    Anchor('_position'),
                ),
            ),
        );
    my $parsed_extra_field = $extra_field->parse( $self->{'_extra_field'} );

    if ( $argref->{'describe'} ) {
        my %extra_field_description_mapping = (
            '0001' => 'Zip64 extended information extra field',
            '0007' => 'AV Info',
            '0008' => 'Reserved for extended language encoding data (PFS)',
            '0009' => 'OS/2',
            '000a' => 'NTFS ',
            '000c' => 'OpenVMS',
            '000d' => 'UNIX',
            '000e' => 'Reserved for file stream and fork descriptors',
            '000f' => 'Patch Descriptor',
            '0014' => 'PKCS#7 Store for X.509 Certificates',
            '0015' => 'X.509 Certificate ID and Signature for individual file',
            '0016' => 'X.509 Certificate ID for Central Directory',
            '0017' => 'Strong Encryption Header',
            '0018' => 'Record Management Controls',
            '0019' => 'PKCS#7 Encryption Recipient Certificate List',
            '0065' =>
              'IBM S/390 (Z390), AS/400 (I400) attributes - uncompressed',
            '0066' =>
              'Reserved for IBM S/390 (Z390), AS/400 (I400) attributes - compressed',
            '4690' => 'POSZIP 4690 (reserved) ',
            '07c8' => 'Macintosh',
            '2605' => 'ZipIt Macintosh',
            '2705' => 'ZipIt Macintosh 1.3.5+',
            '2805' => 'ZipIt Macintosh 1.3.5+',
            '334d' => 'Info-ZIP Macintosh',
            '4341' => 'Acorn/SparkFS ',
            '4453' => 'Windows NT security descriptor (binary ACL)',
            '4704' => 'VM/CMS',
            '470f' => 'MVS',
            '4b46' => 'FWKCS MD5',
            '4c41' => 'OS/2 access control list (text ACL)',
            '4d49' => 'Info-ZIP OpenVMS',
            '4f4c' => 'Xceed original location extra field',
            '5356' => 'AOS/VS (ACL)',
            '5455' => 'extended timestamp',
            '554e' => 'Xceed unicode extra field',
            '5855' => 'Info-ZIP UNIX (original, also OS/2, NT, etc)',
            '6375' => 'Info-ZIP Unicode Comment Extra Field',
            '6542' => 'BeOS/BeBox',
            '7075' => 'Info-ZIP Unicode Path Extra Field',
            '756e' => 'ASi UNIX',
            '7855' => 'Info-ZIP UNIX (new)',
            'a220' => 'Microsoft Open Packaging Growth Hint',
            'fd4a' => 'SMS/QDOS',
        );

        my %extra_field_descriptions;
        my @descriptions_to_be_serialised;
        for ( @{ $parsed_extra_field->{'_header'} } ) {
            my $id   = unpack( 'H*', pack( 'n', $_->{'_id'} ) );
            my $data = unpack( 'H*', $_->{'_data'} );
            my @serialised_extra_field_description;

            if ( exists $extra_field_description_mapping{$id} ) {
                my $description = $extra_field_description_mapping{$id};
                $extra_field_descriptions{$description} = $data;
                push @descriptions_to_be_serialised, $description;
            }
            else {
                $extra_field_descriptions{$id} = $data;
            }
        }

        return %extra_field_descriptions;
    }

    my %extra_field;
    for ( @{ $parsed_extra_field->{'_header'} } ) {
        my $id   = unpack( 'H*', pack( 'n', $_->{'_id'} ) );
        my $data = unpack( 'H*', $_->{'_data'} );
        $extra_field{$id} = $data;
    }
    return %extra_field;
}

1;
