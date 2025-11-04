#! /usr/bin/env perl

# Copyright (C) 2021-2025 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;

# Do not "use" the module because we do not want to acti
require Chess::Plisco::Macro;

my ($code);

$code = 'cp_move_to($move)';
is Chess::Plisco::Macro::preprocess($code), '(($move) & 0x3f)', $code;

$code = 'cp_move_to $move';
is Chess::Plisco::Macro::preprocess($code), '(($move) & 0x3f)', $code;

$code = 'cp_move_to($move); return;';
is Chess::Plisco::Macro::preprocess($code),
	'(($move) & 0x3f); return;', $code;

$code = 'cp_move_to $move; return;';
is Chess::Plisco::Macro::preprocess($code),
	'(($move) & 0x3f); return;', $code;

$code = 'cp_move_set_to($move, 32);';
is Chess::Plisco::Macro::preprocess($code),
	'(($move) = (($move) & ~0x3f) | ((32) & 0x3f));', $code;

done_testing;
