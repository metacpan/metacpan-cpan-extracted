#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::MARC::Field008::VisualMaterial;

# cnb000027064
my $obj = Data::MARC::Field008::VisualMaterial->new(
        'form_of_item' => ' ',
        'government_publication' => ' ',
        #         89012345678901234
        'raw' => 'nnn g          kn',
        'running_time_for_motion_pictures_and_videorecordings' => 'nnn',
        'target_audience' => 'g',
        'technique' => 'n',
        'type_of_visual_material' => 'k',
);

# Print out.
p $obj;

# Output:
# Data::MARC::Field008::VisualMaterial  {
#     parents: Mo::Object
#     public methods (10):
#         BUILD
#         Data::MARC::Field008::Utils:
#             check_government_publication, check_item_form, check_target_audience, check_visual_material_running_time, check_visual_material_technique
#         Error::Pure:
#             err
#         Error::Pure::Utils:
#             err_get
#         Mo::utils:
#             check_length_fix, check_required
#     private methods (0)
#     internals: {
#         form_of_item                                           " ",
#         government_publication                                 " ",
#         raw                                                    "nnn g          kn",
#         running_time_for_motion_pictures_and_videorecordings   "nnn",
#         target_audience                                        "g",
#         technique                                              "n",
#         type_of_visual_material                                "k"
#     }
# }