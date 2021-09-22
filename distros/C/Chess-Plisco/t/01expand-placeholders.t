#! /usr/bin/env perl

# Copyright (C) 2021 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

use strict;

use Test::More;
use PPI::Document;

# Do not "use" the module because we do not want to acti
require Chess::Plisco::Macro;

my %placeholders = (
	'$m' => [PPI::Token::Symbol->new('$move')],
	'$v' => [PPI::Token::Number->new(32)],
);
my $code = '(($m) = (($m) & ~0x3f) | (($v) & 0x3f))';
my $cdoc = PPI::Document->new(\$code);
Chess::Plisco::Macro::_expand_placeholders($cdoc, %placeholders);

is $cdoc->content, '(($move) = (($move) & ~0x3f) | ((32) & 0x3f))';

done_testing;
