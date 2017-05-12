use strict;
use warnings;
use Test::More;
eval {
  require DBI;
};
if ($@) {
  plan skip_all => 'DBI transport requires DBI module';
} else {
  plan tests => 3;
}
use_ok("Bio::Das::ProServer::SourceAdaptor::Transport::dbi");
my $t = Bio::Das::ProServer::SourceAdaptor::Transport::dbi->new();
isa_ok($t, 'Bio::Das::ProServer::SourceAdaptor::Transport::dbi');
can_ok($t, qw(dbh query prepare disconnect last_modified DESTROY));
