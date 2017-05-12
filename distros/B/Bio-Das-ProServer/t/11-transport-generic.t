use strict;
use warnings;
use Test::More tests => 8;
use_ok("Bio::Das::ProServer::SourceAdaptor::Transport::generic");

my $t;

$t = Bio::Das::ProServer::SourceAdaptor::Transport::generic->new();
isa_ok($t, "Bio::Das::ProServer::SourceAdaptor::Transport::generic");
$t = Bio::Das::ProServer::SourceAdaptor::Transport::generic->new({});
isa_ok($t, "Bio::Das::ProServer::SourceAdaptor::Transport::generic");
is($t->{'dsn'}, 'unknown');
is(ref($t->{'config'}), 'HASH');
 
my $cfg = {};
$t = Bio::Das::ProServer::SourceAdaptor::Transport::generic->new({
								  'dsn'    => 'test',
								  'config' => $cfg,
								 });
isa_ok($t, "Bio::Das::ProServer::SourceAdaptor::Transport::generic");
is($t->{'config'}, $cfg);
is($t->{'dsn'}, 'test');
