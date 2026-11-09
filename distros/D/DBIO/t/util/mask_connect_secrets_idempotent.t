use strict;
use warnings;
use Test::More;

use DBIO::Util qw(mask_connect_secrets);

# karr k305: a transport that masks its own error at the source, and the pool
# that masks it again (PoolBase::_spawn_connection). Masking is idempotent: a
# value that already is the mask stays, with whatever stands behind it -- the
# quote that closes it included.

my $secret = 'hunter2';

my %text = (
  'measured: libpq error quoting a URI and keywords, closed by a quote' =>
    qq{connection failed, URI: "postgresql://app:***\@[::1/appdb user='app' password=***"\n},
  'libpq keyword text after a first run' =>
    mask_connect_secrets(qq{could not connect: dbname=x user='app' password='$secret' host=h}),
  'URI' =>
    qq{failed for "postgresql://app:$secret\@db.example/appdb?sslmode=require"},
  'DSN part' =>
    qq{DBI connect('dbi:Pg:dbname=x;host=h;password=$secret','app') failed},
  'ODBC PWD' =>
    qq{[unixODBC] DRIVER={X};UID=app;PWD=$secret;DATABASE=x},
  'masked value closed by quote, then more' =>
    q{opts: "password=***" and 'pwd=***' (see log)},
  'masked value in a DSN part, closed by quote' =>
    q{dsn: "dbi:Pg:dbname=x;password=***;host=h"},
);

for my $name (sort keys %text) {
  my $first  = mask_connect_secrets($text{$name});
  my $second = mask_connect_secrets($first);

  is $second, $first, "idempotent: $name";
  unlike $first, qr/\Q$secret\E/, "no secret left: $name";
}

# what a source already masked is not touched by the pool's pass
is mask_connect_secrets($text{'measured: libpq error quoting a URI and keywords, closed by a quote'}),
  $text{'measured: libpq error quoting a URI and keywords, closed by a quote'},
  'the measured text, masked at the source, comes through unchanged';

# the closing quote stays, literally
is mask_connect_secrets(q{x password=***" y}), q{x password=***" y},
  'a masked value keeps the quote behind it';
is mask_connect_secrets(q{x ;password=***"}), q{x ;password=***"},
  'same behind a DSN part separator';
is mask_connect_secrets(q{x PWD=***} . "'"), q{x PWD=***'},
  'same for a single quote and PWD';

# a value that only starts like the mask is not the mask
is mask_connect_secrets(q{password=***abc}), q{password=***},
  'a password that merely starts with *** is still masked';
is mask_connect_secrets(q{password=hunter2"}), q{password=***},
  'an unmasked value is masked as before, quote going with it';

done_testing;
