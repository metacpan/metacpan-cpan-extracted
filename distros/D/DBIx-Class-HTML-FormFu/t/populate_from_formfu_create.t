use strict;
use warnings;
use Test::More;

BEGIN {
    if ( !-f 't/test.db' ) {
        plan skip_all => 'To run these tests, '
        . 'run `sqlite3 t/test.db < t/create.sql` to create the test db.';
    }
}

plan tests => 7;

use HTML::FormFu;
use lib 't/lib';
use MySchema;

my $form = HTML::FormFu->new->load_config_file('t/form.yml');

ok( my $schema = MySchema->connect('dbi:SQLite:dbname=t/test.db') );

my $rs = $schema->resultset('Test');

# make sure db is empty to start
map { $_->delete } grep { defined } $rs->find({});

# Fake submitted form
$form->process({
    hidden_col     => 1,
    text_col       => 'a',
    password_col   => 'b',
    checkbox_col   => 'foo',
    select_col     => '2',
    radio_col      => 'yes',
    radiogroup_col => '3',
    });

{
    my $row = $rs->new({});
    
    $row->populate_from_formfu( $form );
}

{
    my $row = $rs->find({ hidden_col => 1 });
    
    is( $row->text_col,       'a' );
    is( $row->password_col,   'b');
    is( $row->checkbox_col,   'foo' );
    is( $row->select_col,     '2' );
    is( $row->radio_col,      'yes' );
    is( $row->radiogroup_col, '3' )
}

# empty db again
map { $_->delete } $rs->find({});
