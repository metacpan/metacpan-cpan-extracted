use strict;
use Test::More tests => 14;
use Sys::Hostname;

use_ok("Bio::Das::ProServer::Config");
my $cfg = Bio::Das::ProServer::Config->new();
isa_ok($cfg, "Bio::Das::ProServer::Config");
is($cfg->port(),        "9000",       "default port is ok");
is($cfg->maxclients(),  "10",         "default maxclients is ok");
is($cfg->maxclients(5),  5,           "maxclients get/set ok");
is($cfg->pidfile(),      undef,       "default pidfile is undef");
is($cfg->logfile(),      undef,       "default logfile is undef");
is($cfg->host(),         &hostname(), "sys::hostname is passed through ok");
ok(scalar $cfg->adaptors() == 0,     "no adaptors by default");
#knows pos test
isa_ok($cfg->adaptor(),  "Bio::Das::ProServer::SourceAdaptor", "generic adaptor creation ok");
#adaptor pos test
is($cfg->knows("foo"),   undef,       "fictitious adaptor is unknown");
is($cfg->das_version(),  "DAS/1.6E", "default version is ok");
is($cfg->hydra_adaptor(), undef,      "default hydra-based sourceadaptor is undef");
is($cfg->hydra(),         undef,      "default hydraadaptor is undef");
