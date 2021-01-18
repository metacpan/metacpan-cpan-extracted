#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return {
    conf_file_name => "popularity-contest.conf" ,
    conf_dir => "etc" ,
    model_to_test => "PopCon" ,
    tests => [
        { # t0
            check => { }
        },
    ],
};
