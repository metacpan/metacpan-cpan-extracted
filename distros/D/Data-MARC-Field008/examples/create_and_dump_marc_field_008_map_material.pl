#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::Map;

# cnb000001006
my $obj = Data::MARC::Field008::Map->new(
        'form_of_item' => ' ',
        'government_publication' => ' ',
        'index' => '1',
        'projection' => '  ',
        #         89012345678901234
        'raw' => 'z      e     1   ',
        'relief' => 'z   ',
        'special_format_characteristics' => '  ',
        'type_of_cartographic_material' => 'e',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::Map  {
#     parents: Mo::Object
#     public methods (11):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_government_publication, check_index, check_item_form, check_map_cartographic_material_type, check_map_projection, check_map_relief, check_map_special_format
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix
#     private methods (0)
#     internals: {
#         form_of_item                     " ",
#         government_publication           " ",
#         index                            1,
#         projection                       "  ",
#         raw                              "z      e     1   ",
#         relief                           "z   ",
#         special_format_characteristics   "  ",
#         type_of_cartographic_material    "e"
#     }
# }