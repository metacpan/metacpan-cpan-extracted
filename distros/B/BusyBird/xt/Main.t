use strict;
use warnings;
use Test::More;
use File::HomeDir::Test;
use File::HomeDir;
use File::Spec;

use BusyBird::Main;

my $HOME = File::HomeDir->my_home;
my $CONFIG_DIR = File::Spec->catdir($HOME, ".busybird");
mkdir $CONFIG_DIR or die "Cannot create directory $CONFIG_DIR: $!";

my $EXP_STATUS_STORAGE = File::Spec->catdir($CONFIG_DIR, "statuses.sqlite3");

{
    my $main = BusyBird::Main->new();
    my $tl = $main->timeline('dummy');
    my $storage = $main->get_config('default_status_storage');
    isa_ok($storage, 'BusyBird::StatusStorage::SQLite', 'default default_status_storage is a BB::SS::SQLite');
    ok(-f $EXP_STATUS_STORAGE, "storage file $EXP_STATUS_STORAGE created");
}


done_testing();


