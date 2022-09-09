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
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('CTK::ConfGenUtil') };

my $arr = [qw/foo bar baz/];

# First value
is(value($arr), 'foo', 'First value');

# Last value
is(lvalue($arr), 'baz', 'Last value');

1;

__END__
