use strict;
use warnings;
use Test::More;
eval {
  require DBI;
  require DBD::Oracle;
};
if ($@) {
  plan skip_all => 'Oracle transport requires DBI and DBD::Oracle modules';
} else {
  plan tests => 3;
}
use_ok("Bio::Das::ProServer::SourceAdaptor::Transport::oracle");
my $t = Bio::Das::ProServer::SourceAdaptor::Transport::oracle->new();
isa_ok($t, 'Bio::Das::ProServer::SourceAdaptor::Transport::oracle');
can_ok($t, qw(dbh query prepare disconnect DESTROY));
