#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 192 2017-04-28 20:40:38Z minus $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('CTK'); };
is(CTK->VERSION,'1.18','Version checking');
