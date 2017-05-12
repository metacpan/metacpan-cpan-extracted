#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 9;

use_ok('App::Addex');

my $addex = App::Addex->new({
  classes => {
    addressbook => 'App::Addex::AddressBook::Test',
    output      => [ 'App::Addex::Output::Mutt' ],
  },
  'App::Addex::Output::Mutt' => {
     filename => \(my $buffer),
  },
});

isa_ok($addex, 'App::Addex');

$addex->run;

like(
  $buffer,
  qr/^alias rjbs "Ricardo SIGNES" <rjbs\@example.com>/sm,
  "default nick-based alias created",
);

like(
  $buffer,
  qr/^alias ricardosignes "Ricardo SIGNES" <rjbs\@example.com>/sm,
  "default name-based alias created",
);

like(
  $buffer,
  qr/^alias rjbs-work "Ricardo SIGNES" <rjbs\@example.com>/sm,
  "default nick-based alias with label created",
);

like(
  $buffer,
  qr/^alias ricardosignes-work "Ricardo SIGNES" <rjbs\@example.com>/sm,
  "default name-based alias with label created",
);

like(
  $buffer,
  qr/^alias rjbs-work-1 "Ricardo SIGNES" <rjbs\@example.biz>/sm,
  "secondary nick-based alias with label created",
);

# Why had I ever wanted to assert this? -- rjbs, 2008-02-17
# unlike(
#   $buffer,
#   qr/^alias ricardosignes-work-1 rjbs\@example.biz/sm,
#   "we don't created secondary name-based aliases, if nick exists",
# );

like(
  $buffer,
  qr/^save-hook ~fjcap\@example\.com =co-workers\.jcap/sm,
  "created save hook for entry with folder",
);

like(
  $buffer,
  qr/^mailboxes =co-workers\.jcap/sm,
  "created mailboxes line for entry with folder",
);

