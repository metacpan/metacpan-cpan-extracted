use strict;
use warnings;
use Test::More 'no_plan';
use utf8;

use lib 't/lib';
BEGIN { use_ok 'I18NTest' }

ok ( my $schema = I18NTest->new(), 'Create a schema object' );
isa_ok ( $schema, 'I18NTest::Schema');

our $item_id;
{ # create item
    ok ( my $item = $schema->resultset('Item')->create({
            name  => 'Diego Maradona',
        }), 'Create an item' 
    );

    ok ( $item_id = $item->id, 'Item has ID' );
    ok ( $item->string( 'test in english', ['en'] ), "Set string in english" );
    ok ( $item->string( 'test en español', ['es'] ), "Set string in spanish" );
    is ( $item->string(['en']), 'test in english', 'English string is retrieved correctly');
    is ( $item->string(['es']), 'test en español', 'Spanish string is retrieved correctly');
    ok ( $item->update, "Call update" );
}

{ # find item
    ok ( my $item = $schema->resultset('Item')->find($item_id), 'Retrieve the item from the store' );
    is ( $item->name, 'Diego Maradona', 'Column name is ok (normal column)');
    is ( $item->string(['en']), 'test in english', 'English string is ok (i18n column)');
    is ( $item->string(['es']), 'test en español', 'Spanish string is ok (i18n column)');

    ok ( $item->language('en'), 'Set english language' );
    is ( $item->string, 'test in english', 'Retrieve string with lang set' );
    ok ( $item->string('Test in English'), 'Set string with lang set' );
    is ( $item->string, 'Test in English', 'Retrieve string with lang set' );
    ok ( $item->update, "Call update" );
}

{ # find item using lang
    ok ( my $item = $schema->resultset('Item')->find({ id => $item_id, language => 'en' }), 'Retrieve the item with language' );
    is ( $item->string, 'Test in English', 'Retrieve string with lang set' );
    ok ( $item->string('test in english'), 'Set string with lang set' );
    is ( $item->string, 'test in english', 'Retrieve string with lang set' );
    ok ( $item->update, "Call update" );
}

{ # search with lang
    ok ( my $rs = $schema->resultset('Item')->search({ language => 'en' }), 'Search items with language' );
    is ( $rs->language, 'en', 'ResultSet has language set');
    ok ( my $item = $rs->next, 'Getting next item from rs');
    is ( $item->language, 'en', 'Row has language set');
}

{ # all with lang
    ok ( my @items = $schema->resultset('Item')->search({ language => 'en' })->all, 'All items with language' );
    is ( $items[0]->language, 'en', 'Items has language set');
}

{ # create item with lang
    ok ( my $item = $schema->resultset('Item')->create({
            name   => 'Carlos Gardel',
            string => 'De chiquitin te miraba de afuera...',
            text   => '...como esas cosas que nunca se alcanzan...',
            language => 'es',
        }), 'Create an item with language' 
    );
    is ( $item->language, 'es', 'Row has language spanish');
    like ( $item->string, qr/chiquitin/, 'string is retrieved correctly');
    like ( $item->text, qr/cosas/, 'text is retrieved correctly');
}

{
    ok ( my $rs = $schema->resultset('ItemI18N')->search(), 'Search i18n rs' );
    is ( $rs->next->testme, 'yay!', 'Row object has extended method');
}

{
    ok ($schema->resultset('Item')->can('dance'), 'Resultset class has extedend method');
}

