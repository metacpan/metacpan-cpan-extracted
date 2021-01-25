#
# This file is part of Config-Model-Backend-Yaml
#
# This software is Copyright (c) 2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package SneakyObject;

use strict;
use warnings;
use Test::More;
use 5.10.1;

# class used with some fill.copyright.blanks.yml to check that object
# cannot be created from YAML files

sub DESTROY {
    fail "SneakyObject was loaded from YAML data\n";
}

1;

