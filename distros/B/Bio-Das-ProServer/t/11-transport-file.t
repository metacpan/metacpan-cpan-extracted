use strict;
use warnings;
use Test::More tests => 3;
use_ok("Bio::Das::ProServer::SourceAdaptor::Transport::file");
my $t = Bio::Das::ProServer::SourceAdaptor::Transport::file->new();
isa_ok($t, 'Bio::Das::ProServer::SourceAdaptor::Transport::file');
can_ok($t, qw(query last_modified DESTROY));
