#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('App::DistSync') };
ok(App::DistSync->VERSION,'Version');

1;

__END__
