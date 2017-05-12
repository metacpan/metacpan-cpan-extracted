use strict;
use warnings;

use FindBin qw/$Bin/;
use lib qw|$Bin/lib t/lib|;

use Test::More;
use Fixture;

# f as in fixture
my ($f);

BEGIN {
  $f = Fixture->new();

  my $reason = $f->setup();
  plan skip_all => $reason if $reason;
}

use_ok('Catalyst::Plugin::Session::Store::MongoDB');

# store & retrieve
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $expires = 'expires:'.$id;
  my $data = $f->new_data();

  $f->store->store_session_data($session, $data);
  is ($f->store->get_session_data($session), $data, "store::session");
}

# set expire
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $expires = 'expires:'.$id;
  my $data = $f->new_data();
  my $at = time() + 24 * 3600;

  $f->store->store_session_data($session, $data);
  $f->store->store_session_data($expires, $at);
  is ($f->store->get_session_data($expires), $at, "set expire");
}

# delete
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $data = $f->new_data();

  $f->store->store_session_data($session, $data);
  $f->store->delete_session_data($session);
  is ($f->store->get_session_data($session), undef, "delete");
}

# auto expire
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $expires = 'expires:'.$id;
  my $data = $f->new_data();
  my $at = time() -10;

  $f->store->store_session_data($session, $data);
  $f->store->store_session_data($expires, $at);
  is ($f->store->get_session_data($session), undef, "auto expire");
}

# explicit expire
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $expires = 'expires:'.$id;
  my $data = $f->new_data();
  my $at = time() -10;

  $f->store->store_session_data($session, $data);
  $f->store->store_session_data($expires, $at);
  $f->store->delete_expired_sessions();

  my $found = $f->collection->find_one({ _id => $id });
  is ($found, undef, "explicit expire");
}

# overwrite
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $expires = 'expires:'.$id;
  my $old = $f->new_data();
  my $new = $f->new_data();

  $f->store->store_session_data($session, $old);
  is ($f->store->get_session_data($session), $old, "overwrite::old");
  $f->store->store_session_data($session, $new);
  is ($f->store->get_session_data($session), $new, "overwrite::new");
}

# mass create
{
  my %created;

  foreach my $i (1..100) {
    my $session = 'session:'.$f->new_id();
    $f->store->store_session_data($session, $i);
    $created{$session} = $i;
  }

  foreach my $session (keys(%created)) {
    my $data = $f->store->get_session_data($session);
    is ( $data, $created{$session}, "mass create");
  }
};

# don't delete by id only
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $data = $f->new_data();

  $f->store->store_session_data($session, $data);
  $f->store->delete_session_data($id);
  my $found = $f->store->get_session_data($session);
  isnt ($found, undef, "don't delete by id only::undef");
  is ($found, $data, "don't delete by id only::data");
}

# delete document if empty
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $flash = 'flash:'.$id;
  my $data_session = $f->new_data();
  my $data_flash = $f->new_data();

  $f->store->store_session_data($session, $data_session);
  $f->store->store_session_data($flash, $data_flash);
  $f->store->delete_session_data($session);
  my $found = $f->store->get_session_data($flash);
  is ($found, $data_flash, "delete document if empty::flash");

  $f->store->delete_session_data($flash);
  $found = $f->store->get_session_data($flash);
  is ($found, undef, "delete document if empty::empty");

  $found = $f->collection->find_one({ _id => $id });
  is ($found, undef, "delete document if empty::gone");
}

done_testing();

END {
  $f->teardown();
}

