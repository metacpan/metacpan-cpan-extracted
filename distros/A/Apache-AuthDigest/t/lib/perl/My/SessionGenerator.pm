package My::SessionGenerator;

use Digest::MD5;
use Apache::AuthDigest::API::Session;

use Apache::Constants qw(OK);
use Apache::ModuleConfig;

use strict;

sub handler {

  my $r = Apache::AuthDigest::API::Session->new(shift);

  # generate a new session session identifier
  my $md5 = Digest::MD5->new;

  $md5->add($r->args);

#  my ($key, $session) = $r->get_session;
#  $r->notes($key => $md5->hexdigest);

  $r->set_session($md5->hexdigest);

  return OK;
}
1;
