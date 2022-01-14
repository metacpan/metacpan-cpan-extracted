#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

# This class is trashed during tests

return [
    [
        name    => "MasterModel::ToTrash",
        element => [
            [qw/my_hash my_hash2 my_hash3/] => {
                type       => 'hash',
                index_type => 'string',
                cargo_type => 'leaf',
                cargo_args => { value_type => 'string' },
            },

        ]
    ]
];
