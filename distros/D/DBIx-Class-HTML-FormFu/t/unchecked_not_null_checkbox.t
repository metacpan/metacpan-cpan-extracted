use strict;
use warnings;
use Test::More;

BEGIN {
    if ( !-f 't/test.db' ) {
        plan skip_all => 'To run these tests, '
        . 'run `sqlite3 t/test.db < t/create.sql` to create the test db.';
    }
}

plan tests => 2;

use HTML::FormFu;
use lib 't/lib';
use MySchema;

my $form = HTML::FormFu->new->load_config_file('t/form.yml');

ok( my $schema = MySchema->connect('dbi:SQLite:dbname=t/test.db') );

my $rs = $schema->resultset('Test');

# make sure db is empty to start
map { $_->delete } grep { defined } $rs->find({});

{
    my $row = $rs->new_result({
        checkbox_col   => 'xyzfoo',
        });
    
    $row->insert;
}

# an unchecked Checkbox causes no key/value to be submitted at all
# this is a problem for NOT NULL columns
# ensure the column's default value gets inserted

$form->process({
    hidden_col => 1,
    });

{
    my $row = $rs->find({ hidden_col => $form->params->{hidden_col} });
    
    $row->populate_from_formfu( $form );
}

{
    my $row = $rs->find({ hidden_col => 1 });
    
    is( $row->checkbox_col, '0' );
}

# empty db again
map { $_->delete } $rs->find({});
