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
    ok ( my $item = $item_rs->create({
            name  => 'Diego Maradona',
            string => 'futbol futbol futbol',
            text => 'santa maradona... la la la',
            language => 'es',
        }), 'Create an item' 
    );

    ok ( my $item_id = $item->id, 'Item has ID' );

    ok ( $item->language('en'), 'Switch to english' );
    ok ( ! $item->string, 'string not set, yet!');
    ok ( $item->string( 'test in english' ), "Set string in english" );
    ok ( $item->text( 'text in english' ), "Set text in english" );
    ok ( $item->update, "Call update" );

    is ( $item->string, 'test in english', 'English string is set ok');
    is ( $item->string(['es']), 'futbol futbol futbol', 'Spanish string is ok forcing lang');
}

{
    ok ( my $item = $item_rs->search({ language => 'en' })->single, 'Single item retrieved with language' );
    is ( $item->string, 'test in english', 'English string is set ok');
    is ( $item->string(['es']), 'futbol futbol futbol', 'Spanish string is ok forcing lang');

    ok ( my @i18n_rows = $item->i18n_rows->all, 'Auto-created relation to auto-created RS exists' );
    is ( scalar(@i18n_rows), 2, 'Relation to i18n rows returned two rows' );

    ok ( $item->language('en_us'), 'Switch to american english' );
    ok ( $item->string( "ain't problem here!" ), "Set string in american english" );
    ok ( $item->text( "ain't problem here neither you!" ), "Set text in american english" );
    ok ( $item->update, "Call update" );

    is_deeply ( [ sort $item->languages ], [ qw( en en_us es ) ], "Languages reported for the row are fine" );

    ok ( $item->discard_changes, 'Call discard_changes()');
    is ( $item->language, 'en_us', 'Fresh object has language' );

    ok ( my $i18n_row = $item->i18n_rows({ language => 'en_us' })->single, 'Retrieve american english i18n row' );
    is ( $i18n_row->string, "ain't problem here!", 'Row string is ok!' );
}

{
    ok ( my $item = $item_rs->find(1), 'Item retrieved with find()' );
    ok ( $item->language( 'en' ), 'Set language on finded item' );
    is ( $item->string(''), '', 'Set a empty string');
    is ( $item->text(undef), undef, 'Set a undef text');
    is ( $item->string, '', 'String is empty');
    is ( $item->text, undef, 'Text is undef');
    ok ( $item->update, "Call update" );

    $item = undef;

    ok ( $item = $item_rs->search({ language => 'en' })->single, 'Single item retrieved' );
    is ( $item->string, '', 'String is empty');
    is ( $item->text, undef, 'Text is undef');
}

