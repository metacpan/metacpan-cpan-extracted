#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{ANYEVENT_OWNET_TEST_DEBUG}
};

$|=1;

BEGIN {
  require Test::More;
  eval { require AnyEvent; import AnyEvent;
         require AnyEvent::Socket; import AnyEvent::Socket };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::Socket module installed: $@';
  }
  eval { require AnyEvent::MockTCPServer; import AnyEvent::MockTCPServer };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::MockTCPServer module: '.$@;
  }
  import Test::More;
}

my @connections =
  (
   [
    [ packrecv => '00 00 00 00 00 00 00 02  00 00 00 0A 00 00 01 0E
                   00 00 80 E8 00 00 00 00  2F 00', q{getslash('/')} ],
    [ packsend => '00 00 00 00 00 00 00 70  00 00 00 00 00 00 01 0a
                   00 00 00 70 00 00 c0 02
                   2f31302e4130463742313030303830302f2c
                   2f31302e3643413845343030303830302f2c
                   2f6275732e302f2c
                   2f73657474696e67732f2c
                   2f73797374656d2f2c
                   2f737461746973746963732f2c
                   2f7374727563747572652f2c
                   2f73696d756c74616e656f75732f2c
                   2f616c61726d2f
                   00', q{getslash('/') response} ],

    [ packrecv => '00 00 00 00 00 00 00 12  00 00 00 0A 00 00 01 0E
                   00 00 80 E8 00 00 00 00  2F 31 30 2E 41 30 46 37
                   42 31 30 30 30 38 30 30  2F 00',
      q{getslash('/10.A0F7B1000800/')} ],
    [ packsend => '00 00 00 00 00 00 00 30  00 00 00 00 00 00 01 0a
                   00 00 00 30 00 00 c0 02  2f 31 30 2e 41 30 46 37
                   42 31 30 30 30 38 30 30  2f 61 64 64 72 65 73 73
                   2c 2f 31 30 2e 41 30 46  37 42 31 30 30 30 38 30
                   30 2f 6d 61 69 6e 2f 00',
      q{getslash('/10.A0F7B1000800/') response} ],

    [ packrecv => '00 00 00 00 00 00 00 12  00 00 00 0A 00 00 01 0E
                   00 00 80 E8 00 00 00 00  2F 31 30 2E 36 43 41 38
                   45 34 30 30 30 38 30 30  2F 00',
      q{getslash('/10.6CA8E4000800/')} ],
    [ packsend => '00 00 00 00 00 00 00 2f  00 00 00 00 00 00 01 0a
                   00 00 00 2f 00 00 c0 02  2f 31 30 2e 41 30 46 37
                   42 31 30 30 30 38 30 30  2f 61 64 64 72 65 73 73
                   2c 2f 31 30 2e 41 30 46  37 42 31 30 30 30 38 30
                   30 2f 74 79 70 65 00',
      q{getslash('/10.6CA8E4000800/') response} ],

    [ packrecv => '00 00 00 00 00 00 00 17  00 00 00 0A 00 00 01 0E
                   00 00 80 E8 00 00 00 00  2F 31 30 2E 41 30 46 37
                   42 31 30 30 30 38 30 30  2F 6D 61 69 6E 2F 00',
      q{getslash('/10.A0F7B1000800/main/')} ],

    [ packsend => '00 00 00 00 00 00 00 1b  00 00 00 00 00 00 01 0a
                   00 00 00 1b 00 00 c0 02  2f 31 30 2e 41 30 46 37
                   42 31 30 30 30 38 30 30  2f 6d 61 69 6e 2f 74 65
                   73 74 00',
      q{getslash('/10.A0F7B1000800/main/') response} ],

   ],
  );

my $server;
eval { $server = AnyEvent::MockTCPServer->new(connections => \@connections); };
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
my $addr = join ':', $host, $port;

plan tests => 7;

use_ok('AnyEvent::OWNet');

my $ow = AnyEvent::OWNet->new(host => $host, port => $port);

ok($ow, 'instantiate AnyEvent::OWNet object');

my @d;
my $cv = $ow->devices(sub { push @d, $_[0]; });

my $res = $cv->recv;

is_deeply(\@d, ['/10.A0F7B1000800/', '/10.6CA8E4000800/'],
          'found correct devices');
