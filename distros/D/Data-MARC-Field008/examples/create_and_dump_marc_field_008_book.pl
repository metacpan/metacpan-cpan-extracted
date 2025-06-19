#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::Book;

# cnb000000096
my $obj = Data::MARC::Field008::Book->new(
        'biography' => ' ',
        'conference_publication' => '0',
        'festschrift' => '|',
        'form_of_item' => ' ',
        'government_publication' => 'u',
        'illustrations' => 'a   ',
        'index' => '0',
        'literary_form' => '|',
        'nature_of_content' => '    ',
        #         89012345678901234
        'raw' => 'a         u0|0 | ',
        'target_audience' => ' ',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::Book  {
#     parents: Mo::Object
#     public methods (15):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_book_biography, check_book_festschrift, check_book_illustration, check_book_literary_form, check_book_nature_of_content, check_conference_publication, check_government_publication, check_index, check_item_form, check_target_audience
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required
#     private methods (0)
#     internals: {
#         biography                " ",
#         conference_publication   0,
#         festschrift              "|",
#         form_of_item             " ",
#         government_publication   "u",
#         illustrations            "a   ",
#         index                    0,
#         literary_form            "|",
#         nature_of_content        "    ",
#         raw                      "a         u0|0 | ",
#         target_audience          " "
#     }
# }