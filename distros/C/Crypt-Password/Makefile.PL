#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use inc::Module::Install;

name            ("Crypt-Password");
abstract        ("Utilities functions for Unix-style Hashed Passwords");
author          ("Catalyst SRS Team <team-srs\@catalyst.net.nz>");
version_from    ("lib/Crypt/Password.pm");
license         ('artistic');

requires        ("perl" => 5.008005);

repository 'http://github.com/st3vil/Crypt-Password';
&WriteAll;

