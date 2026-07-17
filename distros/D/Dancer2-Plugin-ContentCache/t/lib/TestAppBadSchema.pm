package TestAppBadSchema;
use Dancer2;

BEGIN {
    set logger  => 'null';
    set plugins => {
        'DBIx::Class' => {
            default => {
                schema_class => 'TestSchema',
                dsn          => 'dbi:SQLite:dbname=:memory:',
            },
        },
        ContentCache => {
            cache_result_set => 'NoAgingCache',
        },
    };
}

use Dancer2::Plugin::DBIx::Class;
use Dancer2::Plugin::ContentCache;

1;
