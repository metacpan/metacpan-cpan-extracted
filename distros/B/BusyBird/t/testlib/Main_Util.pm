package testlib::Main_Util;
use strict;
use warnings;
use Exporter qw(import);
use BusyBird::Main;
use BusyBird::StatusStorage::SQLite;

our @EXPORT_OK = qw(create_main);

sub create_main {
    my $main = BusyBird::Main->new;
    $main->set_config(default_status_storage => BusyBird::StatusStorage::SQLite->new(path => ':memory:'));
    return $main;
}

1;
