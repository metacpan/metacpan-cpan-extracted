#! /bin/false

# Copyright (C) 2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Make Dist::Zilla happy.
# ABSTRACT: Perl library for accessing chess opening data

package Chess::Opening;
$Chess::Opening::VERSION = '0.5';
use Chess::Opening::Book::Polyglot;
use Chess::Opening::Book::ECO;

1;
