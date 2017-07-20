use Test2::V0;
sub require_ok ($);

require_ok 'Alien::Build::Git';
require_ok 'Alien::Build::Plugin::Download::Git';
require_ok 'Alien::Build::Plugin::Fetch::Git';
require_ok 'Alien::git';

done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
