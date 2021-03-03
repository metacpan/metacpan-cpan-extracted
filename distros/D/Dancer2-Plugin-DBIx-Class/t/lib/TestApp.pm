package TestApp;

use Dancer2;

BEGIN {
    set serializer => 'JSON';

    set plugins => {
        'DBIx::Class' => {
            schema_class => 'TestSchema',
            dsn          => 'dbi:SQLite:t/db/test_database.sqlite3',
        }
    };
}

use Dancer2::Plugin::DBIx::Class;

get '/test_rs'        => sub { [ rs('Human')->result_source->columns ] };
get '/test_rset'      => sub { [ rset('Human')->result_source->columns ] };
get '/test_resultset' =>
    sub { [ resultset('Human')->result_source->columns ] };
get '/test_schema' =>
    sub { [ schema->resultset('Human')->result_source->columns ] };

get '/test_humans' => sub { [ humans->result_source->columns ] };
get '/test_human'  => sub {
    my %human = human(1)->get_columns();
    return \%human;
};

1;
