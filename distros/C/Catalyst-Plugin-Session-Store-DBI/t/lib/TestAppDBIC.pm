package TestAppDBIC;

use strict;
use Catalyst;
use FindBin;

our $VERSION = '0.01';

__PACKAGE__->config(
    name    => __PACKAGE__,
    'Plugin::Session' => {
        expires => 3600,
        dbi_dbh => 'DBIC',
    }
);

__PACKAGE__->setup(qw/Session Session::Store::DBI Session::State::Cookie/);

1;
