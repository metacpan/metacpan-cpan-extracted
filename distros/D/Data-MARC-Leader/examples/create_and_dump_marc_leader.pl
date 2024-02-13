#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Leader;

my $obj = Data::MARC::Leader->new(
        'bibliographic_level' => 'm',
        'char_coding_scheme' => 'a',
        'data_base_addr' => 541,
        'descriptive_cataloging_form' => 'i',
        'encoding_level' => ' ',
        'impl_def_portion_len' => '0',
        'indicator_count' => '2',
        'length' => 2200,
        'length_of_field_portion_len' => '4',
        'multipart_resource_record_level' => ' ',
        'raw' => '02200cem a2200541 i 4500',
        'starting_char_pos_portion_len' => '5',
        'status' => 'c',
        'subfield_code_count' => '2',
        'type' => 'e',
        'type_of_control' => ' ',
        'undefined' => '0',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Leader  {
#     parents: Mo::Object
#     public methods (3):
#         BUILD
#         Mo::utils:
#             check_strings
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         bibliographic_level               "m",
#         char_coding_scheme                "a",
#         data_base_addr                    541,
#         descriptive_cataloging_form       "i",
#         encoding_level                    " ",
#         impl_def_portion_len              0,
#         indicator_count                   2,
#         length                            2200,
#         length_of_field_portion_len       4,
#         multipart_resource_record_level   " ",
#         raw                               "02200cem a2200541 i 4500",
#         starting_char_pos_portion_len     5,
#         status                            "c",
#         subfield_code_count               2,
#         type                              "e",
#         type_of_control                   " ",
#         undefined                         0
#     }
# }