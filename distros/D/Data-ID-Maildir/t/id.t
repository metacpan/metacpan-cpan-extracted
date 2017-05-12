use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Data::ID::Maildir", qw(maildir_id); }

my $id = maildir_id;
isnt(maildir_id, $id);
like($id, qr/\A[0-9]+\.M[0-9]+P[0-9]+\./);

$id = maildir_id("foo");
isnt(maildir_id("foo"), $id);
like($id, qr/\A[0-9]+\.M[0-9]+P[0-9]+\.foo\z/);

1;
