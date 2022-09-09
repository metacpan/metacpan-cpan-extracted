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

use Test::More tests => 12;
BEGIN { use_ok('CTK::Util', qw/ :FORMAT /) };

# to_base64
is(to_base64("foo"),"=?UTF-8?B?Zm9v?=", 'Function to_base64("foo")');
is(to_base64(),"=?UTF-8?B??=", 'Function to_base64()');
is(to_base64(0),"=?UTF-8?B?MA==?=", 'Function to_base64(0)');

# slash
is(slash(0),0, 'Function slash(0)');
is(slash(),"", 'Function slash()');
is(slash('\''),'\\\'', 'Function slash("\'")');

# tag
is(tag(0),0, 'Function tag(0)');
is(tag(),"", 'Function tag()');
is(tag("<>"),"&lt;&gt;", 'Function tag("<>")');

# cdata
is(cdata(0),'<![CDATA[0]]>', 'Function cdata(0)');
is(cdata(),'', 'Function cdata()');

1;

__END__
