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

use Test::More tests => 30;
BEGIN { use_ok('CTK::TFVals', qw/:ALL/) };

# Undef
is(uv2zero(undef),0, 'Function uv2zero(undef)');
is(uv2zero(0),0, 'Function uv2zero(0)');
is(uv2zero(""),"", 'Function uv2zero("")');
is(uv2zero("0"),0, 'Function uv2zero("0")');

# False
is(fv2zero(undef),0, 'Function fv2zero(undef)');
is(fv2zero(0),0, 'Function fv2zero(0)');
is(fv2zero(""),0, 'Function fv2zero("")');
is(fv2zero("0"),0, 'Function fv2zero("0")');

# True (num)
is(tv2num(undef),0, 'Function tv2num(undef)');
is(tv2num(-123),-123, 'Function tv2num(-123)');
is(tv2num(""),0, 'Function tv2num("")');
is(tv2num("foo"),0, 'Function tv2num("foo")');
is(tv2num(0),0, 'Function tv2num(0)');

# True (flt)
is(tv2flt(undef),0, 'Function tv2flt(undef)');
is(tv2flt(-123.456),-123.456, 'Function tv2flt(-123.456)');
is(tv2flt(0),0, 'Function tv2flt(0)');

# True (int)
is(tv2int(undef),0, 'Function tv2int(undef)');
is(tv2int(123),123, 'Function tv2int(123)');
is(tv2int(0),0, 'Function tv2int(0)');

# True (int8)
is(tv2int8(256),0, 'Function tv2int8(256)');
is(tv2int8(255),255, 'Function tv2int8(255)');

# True (int16)
is(tv2int16(2**16),0, 'Function tv2int16(2**16)');
is(tv2int16(2**16-1),2**16-1, 'Function tv2int16(2**16-1)');

# True (int32)
is(tv2int32(2**32),0, 'Function tv2int32(2**32)');
is(tv2int32(2**32-1),2**32-1, 'Function tv2int32(2**32-1)');

# True (intx)
is(tv2intx(2**3,3),0, 'Function tv2intx(2**3)');
is(tv2intx(2**3-1,3),2**3-1, 'Function tv2intx(2**3-1)');

# Bug: zero
ok(is_int8(0), 'Function is_int8(0)');
ok(is_intx(0,1), 'Function is_intx(0,1)');

1;

__END__
