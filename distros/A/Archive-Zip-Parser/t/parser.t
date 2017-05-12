#!perl -T

use Test::More;
use Test::Exception;
use strict;
use warnings;

use_ok('Archive::Zip::Parser');

dies_ok( sub { my $parser = Archive::Zip::Parser->new() },
    'Requires "file_name"' );
my $parser = Archive::Zip::Parser->new( { file_name => 't/files/a.zip' } );
isa_ok( $parser, 'Archive::Zip::Parser' );

is( $parser->verify_signature(), 1, 'Verified signature' );
ok( $parser->parse(), 'Parsed successfully' );

isa_ok( $parser->get_entry(1), 'Archive::Zip::Parser::Entry' );
for ( $parser->get_entry() ) {
    isa_ok( $_, 'Archive::Zip::Parser::Entry' );
}
is( $parser->get_entry(), 5, 'number of entries' );
my $entry = $parser->get_entry(2);

is( $entry->get_file_data(), "File: b.txt\n", 'file data' );

subtest 'local file header' => sub {
    isa_ok(
        my $local_file_header = $entry->get_local_file_header(),
        'Archive::Zip::Parser::Entry::LocalFileHeader'
    );
    is( $local_file_header->get_signature(), '04034b50', 'signature' );
    is( $local_file_header->get_version_needed(), '1.0', 'version needed' );
    is(
        $local_file_header->get_version_needed( { describe => 1 } ),
        'Default value',
        'version needed description'
    );

    subtest 'gp bit' => sub {
        my $bit_count = 0;
        my @bits      = $local_file_header->get_gp_bit();
        is( scalar @bits, 16, '16 bit flags' );
        for (@bits) {
            is( $_, 0, 'bit ' . $bit_count++ );
        }

        my @gp_bit_descriptions
          = $local_file_header->get_gp_bit( { describe => 1 } );
        is( scalar @gp_bit_descriptions,
            0, 'general purpose bit flag description' );

        done_testing();
    };

    is( $local_file_header->get_compression_method(), 0, 'compression method' );
    is(
        $local_file_header->get_compression_method( { describe => 1 } ),
        'The file is stored (no compression)',
        'compression method description'
    );

    subtest 'last mod time' => sub {
        my %last_mod_time = $local_file_header->get_last_mod_time();
        is( $last_mod_time{'hour'},   13, 'hour' );
        is( $last_mod_time{'minute'}, 32, 'minute' );
        is( $last_mod_time{'second'}, 7,  'second' );

        done_testing();
    };

    subtest 'last mod date' => sub {
        my %last_mod_date = $local_file_header->get_last_mod_date();
        is( $last_mod_date{'year'},  2010, 'year' );
        is( $last_mod_date{'month'}, 1,    'month' );
        is( $last_mod_date{'day'},   14,   'day' );

        done_testing();
    };

    is( $local_file_header->get_crc_32(), 'a7794e05', 'CRC-32' );
    is( $local_file_header->get_compressed_size(), '12', 'compressed size' );
    is( $local_file_header->get_uncompressed_size(), 12, 'uncompressed size' );
    is( $local_file_header->get_file_name_length(),  9,  'file name length' );
    is( $local_file_header->get_extra_field_length(),
        '28', 'extra field length' );
    is( $local_file_header->get_file_name(), 'a/b/b.txt', 'file name' );

    subtest 'extra field' => sub {
        my %extra_fields = $local_file_header->get_extra_field();
        is( $extra_fields{'7875'}, '0104e803000004e8030000', 'extra field' );
        is( $extra_fields{'5455'}, '0386cf4e4b83cf4e4b',     'extra field' );
        %extra_fields
          = $local_file_header->get_extra_field( { describe => 1 } );
        is( $extra_fields{'7875'}, '0104e803000004e8030000', 'extra field' );
        is( $extra_fields{'extended timestamp'},
            '0386cf4e4b83cf4e4b', 'extra field' );

        done_testing();
    };

    done_testing();
};

my $data_descriptor = $entry->get_data_descriptor();
if ($data_descriptor) {
    isa_ok( $data_descriptor, 'Archive::Zip::Parser::Entry::DataDescriptor' );

    done_testing();
}

subtest 'central directory' => sub {
    isa_ok(
        my $central_directory = $entry->get_central_directory(),
        'Archive::Zip::Parser::Entry::CentralDirectory'
    );
    is( $central_directory->get_signature(), '02014b50', 'signature' );
    is( $central_directory->get_version_needed(), '1.0', 'version needed' );
    is(
        $central_directory->get_version_needed( { describe => 1 } ),
        'Default value',
        'version needed description'
    );

    subtest 'gp bit' => sub {
        my $bit_count = 0;
        my @bits      = $central_directory->get_gp_bit();
        is( scalar @bits, 16, '16 bit flags' );
        for (@bits) {
            is( $_, 0, 'bit ' . $bit_count++ );
        }

        my @gp_bit_descriptions
          = $central_directory->get_gp_bit( { describe => 1 } );
        is( scalar @gp_bit_descriptions,
            0, 'general purpose bit flag description' );

        done_testing();
    };

    is( $central_directory->get_compression_method(), 0, 'compression method' );
    is(
        $central_directory->get_compression_method( { describe => 1 } ),
        'The file is stored (no compression)',
        'compression method description'
    );

    subtest 'last mod time' => sub {
        my %last_mod_time = $central_directory->get_last_mod_time();
        is( $last_mod_time{'hour'},   13, 'hour' );
        is( $last_mod_time{'minute'}, 32, 'minute' );
        is( $last_mod_time{'second'}, 7,  'second' );

        done_testing();
    };

    subtest 'last mod date' => sub {
        my %last_mod_date = $central_directory->get_last_mod_date();
        is( $last_mod_date{'year'},  2010, 'year' );
        is( $last_mod_date{'month'}, 1,    'month' );
        is( $last_mod_date{'day'},   14,   'day' );

        done_testing();
    };

    is( $central_directory->get_crc_32(), 'a7794e05', 'CRC-32' );
    is( $central_directory->get_compressed_size(), '12', 'compressed size' );
    is( $central_directory->get_uncompressed_size(), 12, 'uncompressed size' );
    is( $central_directory->get_file_name_length(),  9,  'file name length' );
    is( $central_directory->get_extra_field_length(),
        '24', 'extra field length' );
    is( $central_directory->get_file_name(), 'a/b/b.txt', 'file name' );

    subtest 'extra field' => sub {
        my %extra_fields = $central_directory->get_extra_field();
        is( $extra_fields{'7875'}, '0104e803000004e8030000', 'extra field' );
        is( $extra_fields{'5455'}, '0386cf4e4b',             'extra field' );
        %extra_fields
          = $central_directory->get_extra_field( { describe => 1 } );
        is( $extra_fields{'7875'}, '0104e803000004e8030000', 'extra field' );
        is( $extra_fields{'extended timestamp'}, '0386cf4e4b', 'extra field' );

        done_testing();
    };

    subtest 'version made by' => sub {
        my %version_made_by
          = $central_directory->get_version_made_by( { describe => 1 } );
        is( $version_made_by{'attribute_information'},
            'UNIX', 'attribute information' );
        is( $version_made_by{'specification_version'},
            '3.0', 'specification version' );
        %version_made_by = $central_directory->get_version_made_by();
        is( $version_made_by{'attribute_information'},
            '3', 'attribute information' );
        is( $version_made_by{'specification_version'},
            '3.0', 'specification version' );

        done_testing();
    };

    is( $central_directory->get_file_comment_length(),
        0, 'file comment length' );
    is( $central_directory->get_start_disk_number(), 0, 'start disk number' );
    is( $central_directory->get_internal_file_attr(),
        '00000000', 'internal file attributes' );
    is( $central_directory->get_external_file_attr(),
        '81a40000', 'external file attributes' );
    is( $central_directory->get_rel_offset_local_header(),
        '0000007a', 'relative offset of local header' );
    is( $central_directory->get_file_comment(), '', 'file comment' );

    done_testing();
};

subtest 'central directory end' => sub {
    my $central_directory_end = $parser->get_central_directory_end();
    is( $central_directory_end->get_signature(),   '06054b50', 'signature' );
    is( $central_directory_end->get_disk_number(), 0,          'disk number' );
    is( $central_directory_end->get_start_disk_number(),
        0, 'start disk number' );
    is( $central_directory_end->get_total_disk_entries(),
        5, 'total disk entries' );
    is( $central_directory_end->get_total_entries(), 5,   'total entries' );
    is( $central_directory_end->get_size(),          378, 'size' );
    is( $central_directory_end->get_start_offset(),  342, 'start offset' );
    is( $central_directory_end->get_zip_comment_length(),
        0, 'zip comment length' );
    is( $central_directory_end->get_zip_comment(), '', 'zip comment' );

    done_testing();
};

done_testing();
