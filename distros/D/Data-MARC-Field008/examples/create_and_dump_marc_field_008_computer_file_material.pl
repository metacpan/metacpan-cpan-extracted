#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::ComputerFile;

# cnb000208289
my $obj = Data::MARC::Field008::ComputerFile->new(
        'form_of_item' => ' ',
        'government_publication' => ' ',
        #         89012345678901234
        'raw' => '        m        ',
        'target_audience' => ' ',
        'type_of_computer_file' => 'm',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::ComputerFile  {
#     parents: Mo::Object
#     public methods (9):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_computer_file_item_form, check_computer_file_type, check_government_publication, check_target_audience
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required
#     private methods (0)
#     internals: {
#         form_of_item             " ",
#         government_publication   " ",
#         raw                      "        m        ",
#         target_audience          " ",
#         type_of_computer_file    "m"
#     }
# }