#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04-ctkx.t 192 2017-04-28 20:40:38Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('CTKx') };

my $ctkx = CTKx->instance(c => 'foo');
is(MyApp::get_c(), 'foo', 'MyApp::c is foo');

1;

package MyApp;

use CTKx;

sub get_c { CTKx->instance->c }

1;
