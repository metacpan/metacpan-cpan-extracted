package TinyURL::Model::CDBI;

use strict;
use base 'Catalyst::Model::CDBI';
use Class::DBI::AbstractSearch;

my $root = TinyURL->config->{root};

__PACKAGE__->config(
    dsn           => "dbi:SQLite:dbname=$root/../db/tinyurl.db",
    #dsn           => 'dbi:Pg:dbname=tinyurl;host=localhost;port=5432;',
    user          => '',
    password      => '',
    options       => { AutoCommit => 1 },
    relationships => 1
);

1;
