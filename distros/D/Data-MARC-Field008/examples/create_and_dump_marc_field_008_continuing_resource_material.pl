#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::ContinuingResource;

# cnb000002514
my $obj = Data::MARC::Field008::ContinuingResource->new(
        'conference_publication' => '0',
        'entry_convention' => '|',
        'form_of_item' => ' ',
        'form_of_original_item' => ' ',
        'frequency' => 'z',
        'government_publication' => 'u',
        'nature_of_content' => '   ',
        'nature_of_entire_work' => ' ',
        'original_alphabet_or_script_of_title' => ' ',
        #         89012345678901234
        'raw' => 'zr        u0    |',
        'regularity' => 'r',
        'type_of_continuing_resource' => ' ',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::ContinuingResource  {
#     parents: Mo::Object
#     public methods (16):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_conference_publication, check_continuing_resource_entry_convention, check_continuing_resource_form_of_original_item, check_continuing_resource_frequency, check_continuing_resource_nature_of_content, check_continuing_resource_nature_of_entire_work, check_continuing_resource_original_alphabet_or_script, check_continuing_resource_regularity, check_continuing_resource_type, check_government_publication, check_item_form
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required
#     private methods (0)
#     internals: {
#         conference_publication                 0,
#         entry_convention                       "|",
#         form_of_item                           " ",
#         form_of_original_item                  " ",
#         frequency                              "z",
#         government_publication                 "u",
#         nature_of_content                      "   ",
#         nature_of_entire_work                  " ",
#         original_alphabet_or_script_of_title   " ",
#         raw                                    "zr        u0    |",
#         regularity                             "r",
#         type_of_continuing_resource            " "
#     }
# }