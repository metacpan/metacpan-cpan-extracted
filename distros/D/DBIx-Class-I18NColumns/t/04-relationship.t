use strict;
use warnings;
use Test::More 'no_plan';
use utf8;

use lib 't/lib';
BEGIN { use_ok 'I18NTest' }

ok ( my $schema = I18NTest->new('I18NTest::SchemaAuto'), 'Create a schema object' );
isa_ok ( $schema, 'I18NTest::SchemaAuto');

ok ( my $item_rs = $schema->resultset('Item'), 'Get Item resultset' );
ok ( my $foo_rs = $schema->resultset('Foo'), 'Get Foo resultset' );

# has_many()
{
    diag('Testing has_many()');
    ok ( my $item = $item_rs->create({
            name  => 'Diego Maradona',
            string => 'futbol futbol futbol',
            text => 'santa maradona... la la la',
            language => 'es',
        }), 'Create an item' 
    );

    ok ( my $foo = $item->add_to_foos({
            string => 'mandanga!',
            text   => 'le gusta la mandanga...'
        }), 'Add to related has_many() using add_to_relation' 
    );

    is ( $foo->language, 'es', 'Related item has language propagated' );
    is ( $foo->string, 'mandanga!', 'text on related is ok' );
}
{
    ok ( my $item = $item_rs->search({ language => 'es' })->first(), 'Retrieve the item with language' );
    ok ( my $foo = $item->foos->first(), 'Retrieve the related item from the first one' );
    is ( $foo->language, 'es', 'Related item has language propagated' );
    is ( $foo->string, 'mandanga!', 'text on related is ok' );
}
{
    diag('Testing belongs_to()');

    ok ( my $foo = $foo_rs->search({ language => 'es' })->first(), 'Retrieve the first related item with language' );
    ok ( my $item = $foo->item, 'getting the belongs_to() item from related' );
    is ( $item->language, 'es', 'Language is propagated' )
}

# many_to_many
{
    diag('Testing many_to_many()');

    ok ( my $item = $item_rs->search({ language => 'es' })->first(), 'Retrieve the item with language' );

    ok ( my $bar = $item->add_to_bars({
            string   => 'pelota!',
            text     => 'le gusta la pelota...',
        }), 'Create new related using add_to_related'
    );
    is ( $bar->language, 'es', 'Related item has language propagated' );
    is ( $bar->string, 'pelota!', 'text on related is ok' );
    
    ok ( $bar->language('en'), "Set language to 'en'" ); 
    ok ( $bar->string('ball!'), 'set string' );
    ok ( $bar->update, 'Call update' );

    ok ( $bar = $schema->resultset('Bar')->create({
            string   => 'futbol!',
            text     => 'le gusta el futbol...',
            language => 'es'
        }), 'Create related to add to many_to_many later'
    );
    ok ( $item->add_to_bars($bar), 'Add the row using add_to_relation(obj)' );
}
{
    ok ( my $item = $item_rs->search({ language => 'es' })->first(), 'Retrieve the item with language' );
    ok ( my $bar = $item->bars->first(), 'Retrieve the related item from the first one' );
    is ( $bar->language, 'es', 'Related item has language propagated' );
    is ( $bar->string, 'pelota!', 'text on related is ok' );
}
{
    ok ( my $item = $item_rs->search({ language => 'es' })->first(), 'Retrieve the item with language' );
    my $count = 0;
    for my $bar ( $item->bars->all ) {
        $count++;
        is ( $bar->language, 'es', "Related item($count) has language propagated" );
    }
}

{
    ok ( my $item = $item_rs->find(1), 'Retrieve the item with find()' );
    is ( $item->id, 1, 'Item is ok' );
}
