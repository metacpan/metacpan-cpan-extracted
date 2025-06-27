#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::Music;

# cnb000012142
my $obj = Data::MARC::Field008::Music->new(
        'accompanying_matter' => '      ',
        'form_of_composition' => 'sg',
        'form_of_item' => ' ',
        'format_of_music' => 'z',
        'literary_text_for_sound_recordings' => 'nn',
        'music_parts' => ' ',
        #         89012345678901234
        'raw' => 'sgz g       nn   ',
        'target_audience' => 'g',
        'transposition_and_arrangement' => ' ',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::Music  {
#     parents: Mo::Object
#     public methods (13):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_item_form, check_music_accompanying_matter, check_music_composition_form, check_music_format, check_music_literary_text, check_music_parts, check_music_transposition_and_arrangement, check_target_audience
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required
#     private methods (0)
#     internals: {
#         accompanying_matter                  "      ",
#         format_of_music                      "z",
#         form_of_composition                  "sg",
#         form_of_item                         " ",
#         literary_text_for_sound_recordings   "nn",
#         music_parts                          " ",
#         raw                                  "sgz g       nn   ",
#         target_audience                      "g",
#         transposition_and_arrangement        " "
#     }
# }