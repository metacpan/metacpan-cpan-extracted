#
# This file is part of Config-Model
#
# This software is Copyright (c) 2005-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package DummyNode;

use base qw/Config::Model::Node/;

sub dummy {
    $_[1]++;
}

1;
