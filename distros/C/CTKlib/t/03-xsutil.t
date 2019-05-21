#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-xsutil.t 229 2019-05-02 22:20:44Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 7;

use constant FILENAME => 'xstest.tmp';

BEGIN {
	use_ok('CTK::UtilXS', qw/shred wipe/);
	use_ok('CTK::Util', qw/fsave randchars/);
};

my @pool;
for (1..5) { push @pool, randchars( 80 ) };
ok(fsave(FILENAME, join("\n", @pool)), "Save random file");

is(CTK::UtilXS::xsver(), $CTK::UtilXS::VERSION, 'XS Util testing');

ok(wipe(FILENAME), "Wiped!");
ok(shred(FILENAME), "Shred!");
ok(!-e FILENAME, "File not exists");

1;

__END__
