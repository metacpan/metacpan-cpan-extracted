use Test::More;

use strict;
use warnings;

use Data::Dumper;

use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catdir catfile/;

my $td = tempdir( CLEANUP => 1 );

mkdir catdir($td, 'App')                                   || die "Cannot create $td/App: $!";
mkdir catdir($td, 'App', 'TeleGramma')                     || die "Cannot create $td/App/TeleGramma: $!";
mkdir catdir($td, 'App', 'TeleGramma', 'Plugin')           || die "Cannot create $td/App/TeleGramma/Plugin: $!";
mkdir catdir($td, 'App', 'TeleGramma', 'Plugin', 'Test')   || die "Cannot create $td/App/TeleGramma/Plugin/Test: $!";

my $dir = catdir($td, qw/App TeleGramma Plugin Test/);

open my $fh, ">", catfile($dir, "TestPrereq.pm") || die "Cannot create TestPrereq.pm: $!";

print $fh "package App::TeleGramma::Plugin::Test::TestPrereq;\n";
print $fh "use Mojo::Base 'App::TeleGramma::Plugin::Base';\n";
print $fh "sub register { () }\n";
print $fh "1;\n";
close $fh;

use App::TeleGramma::PluginManager;
use App::TeleGramma::Config;

my $cfg = App::TeleGramma::Config->new(path_base => $td);
$cfg->create_if_necessary;

my $pm = App::TeleGramma::PluginManager->new(config => $cfg, search_dirs => $td);
$pm->load_plugins;

is (@{ $pm->list }, 0, 'no plugins loaded');
$cfg->config->{'plugin-Test-TestPrereq'}->{enable} = 'yes';
$cfg->write();

$pm->load_plugins;
is (@{ $pm->list }, 1, '1 plugin loaded');

done_testing();
