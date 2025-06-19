#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008;
use Data::MARC::Field008::Book;

# cnb000000096
my $obj = Data::MARC::Field008->new(
        'cataloging_source' => ' ',
        'date_entered_on_file' => '830304',
        'date1' => '1982',
        'date2' => '    ',
        'language' => 'cze',
        'material' => Data::MARC::Field008::Book->new(
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
        ),
        'material_type' => 'book',
        'modified_record' => ' ',
        'place_of_publication' => 'xr ',
        #         0123456789012345678901234567890123456789
        'raw' => '830304s1982    xr a         u0|0 | cze  ',
        'type_of_date' => 's',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008  {
#     parents: Mo::Object
#     public methods (14):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_cataloging_source, check_date, check_modified_record, check_type_of_date
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_isa, check_length_fix, check_number, check_regexp, check_required, check_strings
#         Readonly:
#             Readonly
#     private methods (0)
#     internals: {
#         cataloging_source      " ",
#         date_entered_on_file   830304,
#         date1                  1982,
#         date2                  "    ",
#         language               "cze",
#         material               Data::MARC::Field008::Book,
#         material_type          "book",
#         modified_record        " ",
#         place_of_publication   "xr ",
#         raw                    "830304s1982    xr a         u0|0 | cze  " (dualvar: 830304),
#         type_of_date           "s"
#     }
# }