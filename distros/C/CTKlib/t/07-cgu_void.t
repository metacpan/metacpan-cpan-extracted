#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 07-cgu_void.t 192 2017-04-28 20:40:38Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('CTK::ConfGenUtil') };


# value
is(value(undef),undef, 'Function value(undef)');
is(value(0),0, 'Function value(0)');
is(value(""),"", 'Function value("")');
is(value({foo=>0}),undef, 'Function value({})');
is(value(["foo"]),"foo", 'Function value(["foo"])');
is(value([]),undef, 'Function value([])');

# array
is(ref(array(undef)),"ARRAY", 'Function array(undef)');
is(array(0)->[0],0, 'Function array(0)');
is(array("")->[0],"", 'Function array("")');

1;
