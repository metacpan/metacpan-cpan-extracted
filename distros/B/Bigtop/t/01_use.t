use Test::More tests => 12;

BEGIN { use_ok('Bigtop') };
BEGIN { use_ok('Bigtop::Parser') };
BEGIN { use_ok('Bigtop::Keywords') };
BEGIN { use_ok('Bigtop::ScriptHelp') };
BEGIN { use_ok('Bigtop::Backend::Init::Std') };
BEGIN { use_ok('Bigtop::Backend::CGI::Gantry') };
BEGIN { use_ok('Bigtop::Backend::SQL::Postgres') };
BEGIN { use_ok('Bigtop::Backend::HttpdConf::Gantry') };
BEGIN { use_ok('Bigtop::Backend::Control::Gantry') };
BEGIN { use_ok('Bigtop::Backend::Model::GantryCDBI') };
BEGIN { use_ok('Bigtop::Backend::SiteLook::GantryDefault') };
BEGIN { use_ok('Bigtop::Backend::Conf::General') };
