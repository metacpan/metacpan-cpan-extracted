package My::Bar;
use strict;
use base qw( 
    Rose::DB::Object 
    Rose::DB::Object::Helpers 
    Rose::DBx::Object::MoreHelpers    
);
use Carp;
use Data::Dump qw( dump );
use My::DB;

__PACKAGE__->meta->setup(
    table   => 'bars',
    columns => [
        id   => { type => 'serial',  not_null => 1, primary_key => 1 },
        name => { type => 'varchar', length   => 16 },
    ],
    
    primary_key_columns => ['id'],

    relationships => [
        foo => {
            class      => 'My::FooBar',
            column_map => { id => 'bar_id' },
            type       => 'one to many',
        },

        foos => {
            map_class => 'My::FooBar',
            type      => 'many to many',
        }
    ],
);

sub init_db {
    return My::DB->new;
}

1;
