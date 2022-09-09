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
BEGIN {
	use_ok('CTK');
	use_ok('CTKx');
};

my $ctk = CTK->new(
	name => "Test",
);
my $ctkx = CTKx->instance(ctk => $ctk);
isa_ok(MyApp::get_ctk(), "CTK", 'MyApp::get_ctk()');

1;

package MyApp;

use CTKx;

sub get_ctk { CTKx->instance->ctk }

1;
