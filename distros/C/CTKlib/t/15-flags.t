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

use Test::More tests => 8;
BEGIN { use_ok('CTK::Util', qw/ :UTIL /) };

ok(!isFalseFlag("yes"), 'yes is true');
ok(isTrueFlag("Y"), 'Y too');
ok(isTrueFlag("YEP"), 'And YEP too');
ok(isTrueFlag(1), 'And 1 too');
ok(isFalseFlag("Nope"), 'Nope is false');
ok(isFalseFlag(0), 'And 0 too');
ok(isFalseFlag("disabled"), 'And disabled too');

1;

__END__
