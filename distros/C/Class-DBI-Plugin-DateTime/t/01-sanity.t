# $Id$
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 2);
BEGIN
{
    use_ok("Class::DBI::Plugin::DateTime::Pg");
    use_ok("Class::DBI::Plugin::DateTime::MySQL");
}

1;