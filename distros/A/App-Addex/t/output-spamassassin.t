#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 5;

use_ok('App::Addex');

my $addex = App::Addex->new({
  classes => {
    addressbook => 'App::Addex::AddressBook::Test',
    output      => [ 'App::Addex::Output::SpamAssassin' ],
  },
  'App::Addex::Output::SpamAssassin' => {
     filename => \(my $buffer),
  },
});

isa_ok($addex, 'App::Addex');

$addex->run;

my @addrs = qw(
  rjbs@example.com
  rjbs@example.biz
  jcap@example.com
);

for my $addr (@addrs) {
  like(
    $buffer,
    qr/^whitelist_from \Q$addr\E/sm,
    "created whitelist for $addr",
  );
}
