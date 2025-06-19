#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::MixedMaterial;

my $obj = Data::MARC::Field008::MixedMaterial->new(
        'form_of_item' => 'o',
        #         89012345678901234
        'raw' => '     o           ',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::MixedMaterial  {
#     parents: Mo::Object
#     public methods (7):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_item_form
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required, check_strings
#     private methods (0)
#     internals: {
#         form_of_item   "o",
#         raw            "     o           "
#     }
# }