#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant { DEBUG => $ENV{ANYEVENT_OWNET_TEST_DEBUG} };
use Test::More tests => 3;
BEGIN {
  use_ok('AnyEvent::OWNet');
}

test_msg({ data => '/'.chr(0) },
         '0000000000000002000000020000010e000080e8000000002f00',
         'simple read');

test_msg({ version => 2, type => 0x1, sg => AnyEvent::OWNet::OWNET_NET,
           size => 0xf, offset => 0xa },
         '000000020000000000000001000001000000000f0000000a',
         'non-defaults with nop');

sub test_msg {
  my ($req, $hex, $desc) = @_;
  is((unpack 'H*', AnyEvent::OWNet->_msg($req)), $hex, $desc);
}
