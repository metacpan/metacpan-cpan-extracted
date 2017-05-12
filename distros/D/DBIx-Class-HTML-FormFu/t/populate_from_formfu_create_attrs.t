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

my $form = HTML::FormFu->new->load_config_file('t/form_attrs.yml');

ok( my $schema = MySchema->connect('dbi:SQLite:dbname=t/test.db') );

my $rs = $schema->resultset('Test');

# make sure db is empty to start
map { $_->delete } grep { defined } $rs->find({});

# Fake submitted form
$form->process({
    attrs_hidden_col     => 1,
    attrs_text_col       => 'a',
    attrs_password_col   => 'b',
    attrs_checkbox_col   => 'foo',
    attrs_select_col     => '2',
    attrs_radio_col      => 'yes',
    attrs_radiogroup_col => '3',
    });

{
    my $row = $rs->new({});
    
    $row->populate_from_formfu( $form, { prefix_col => 'attrs_' } );
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
