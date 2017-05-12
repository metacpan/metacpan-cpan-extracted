# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: 01_load.t,v 1.1.1.1 2004/10/17 00:44:32 jhoblitt Exp $

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok( 'DateTime::Format::Human' ); }

my $object = DateTime::Format::Human->new ();
isa_ok ($object, 'DateTime::Format::Human');
