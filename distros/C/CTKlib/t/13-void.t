#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 13-void.t 226 2019-05-02 07:03:02Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 20;

BEGIN { use_ok('CTK::TFVals', qw/ :CHECK / ) };

my $t = undef;
ok(is_void($t),'undef - void value');

$t = undef;
ok(is_void(\$t),'\\undef - void value');

$t = "";
ok(isnt_void($t),'null - void value');

$t = "0";
ok(isnt_void($t),'"0" - NOT void value');

$t = "0";
ok(isnt_void(\$t),'\\"0" - NOT void value');


$t = 0;
ok(isnt_void($t),'0 - NOT void value');

$t = [];
ok(is_void($t),'[] - void value');

$t = [0];
ok(isnt_void($t),'[0] - NOT void value');

$t = [undef];
ok(is_void($t),'[undef] - void value');

$t = [undef,0];
ok(isnt_void($t),'[undef,0] - NOT void value');

$t = [{}];
ok(is_void($t),'[{}] - void value');

$t = [{foo=>undef}];
ok(isnt_void($t),'[{foo=>undef}] - NOT void value');

$t = [{foo=>undef}];
ok(isnt_void(\$t),'\\[{foo=>undef}] - NOT void value');

$t = [[[[[]]]]];
ok(is_void($t),'[[[[[]]]]] - void value');

$t = [[[[[]],0]]];
ok(isnt_void($t),'[[[[[]],0]]] - NOT void value');

$t = [[[[[{}]]]]];
ok(is_void($t),'[[[[[{}]]]]] - void value');

$t = [[[[[{bar=>undef}]]]]];
ok(isnt_void($t),'[[[[[{bar=>undef}]]]]] - NOT void value');

$t = qr/./;
ok(isnt_void($t),'qr/./ - NOT void value');

$t = sub {1};
ok(isnt_void($t),'sub{1} - NOT void value');

1;

__END__
