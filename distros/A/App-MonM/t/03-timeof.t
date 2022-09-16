#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More tests => 5;

use App::MonM::Util qw/getTimeOffset/;

is(getTimeOffset("1h12m24s"), 4344, "1h12m24s");
is(getTimeOffset("-1h12m24s"), -4344, "-1h12m24s");
is(getTimeOffset("24m"), 60*24, "24m");
is(getTimeOffset("-24m"), -60*24, "-24m");
is(getTimeOffset("1h 12m 24s"), 4344, "1h 12m 24s");

1;

__END__