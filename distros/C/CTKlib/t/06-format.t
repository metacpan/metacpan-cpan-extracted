#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 06-format.t 192 2017-04-28 20:40:38Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('CTK::Util') };

# to_base64
is(to_base64("foo"),"=?UTF-8?B?Zm9v?=", 'Function to_base64("foo")');
is(to_base64(),"=?UTF-8?B??=", 'Function to_base64()');
is(to_base64(0),"=?UTF-8?B?MA==?=", 'Function to_base64(0)');

# slash, tag, cdata
is(slash(0),0, 'Function slash(0)');
is(slash(),"", 'Function slash()');
is(slash('\''),'\\\'', 'Function slash("\'")');
is(tag(0),0, 'Function tag(0)');
is(tag(),"", 'Function tag()');
is(tag("<>"),"&lt;&gt;", 'Function tag("<>")');
is(cdata(0),'<![CDATA[0]]>', 'Function cdata(0)');
is(cdata(),'', 'Function cdata()');

1;
