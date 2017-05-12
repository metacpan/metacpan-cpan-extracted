use strict;
use warnings;
use Test::More 'no_plan';
use utf8;

use lib 't/lib';
BEGIN { use_ok 'I18NTest' }

ok ( my $schema = I18NTest->new('I18NTest::SchemaAuto'), 'Create a schema object' );
isa_ok ( $schema, 'I18NTest::SchemaAuto');

ok ( my $item_rs = $schema->resultset('Item'), 'Get Item resultset' );

{ 
    ok ( my $item = $item_rs->new({}), 'Create a new() item' );
    ok ( $item->language('es'), 'Set language' );
    ok ( $item->name('Diego Maradona'), 'Set name' );
    ok ( $item->string('futbol futbol futbol'), 'Set string' );
    ok ( $item->text('santa maradona... la la la'), 'Set text' );
    ok ( $item->insert, "Insert created row" );

    ok ( my $item_id = $item->id, 'Item has ID' );

    $item = undef;
    ok ( $item = $item_rs->find( $item_id ), 'Retrieve the created item by ID');
    ok ( $item->language('es'), 'Set language' );
    is ( $item->string, 'futbol futbol futbol', 'string is ok' );
    is ( $item->text, 'santa maradona... la la la', 'text is ok' );
}

{ 
    ok ( my $item = $item_rs->new({ language => 'en' }), 'Create a new() item with language' );
    ok ( $item->name('Diego Maradona'), 'Set name' );
    ok ( $item->string('The great hand of god'), 'Set string' );
    ok ( $item->text('the best football player ever!'), 'Set text' );
    ok ( $item->insert, "Insert created row" );

    ok ( my $item_id = $item->id, 'Item has ID' );
    is ( $item->language, 'en', 'Item has language defined' );
    is ( $item->string, 'The great hand of god', 'string is ok' );

    $item = undef;
    ok ( $item = $item_rs->find( $item_id ), 'Retrieve the created item by ID');
    ok ( $item->language('en'), 'Set language' );
    is ( $item->string, 'The great hand of god', 'string is ok' );
    is ( $item->text, 'the best football player ever!', 'text is ok' );
}

