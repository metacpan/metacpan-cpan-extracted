#! perl

use Test2::V0;

use Config::XrmDatabase;

my $key = 'xmh.toc*Command.activeForeground';

my $db1 = Config::XrmDatabase->new();
$db1->insert( $key, 'red' );

my $db2 = Config::XrmDatabase->new();
$db2->insert( $key, 'blue' );

$db1->merge( $db2 );

is(
    $db1->query(
        'Xmh.Paned.Box.Command.Foreground',
        'xmh.toc.messagefunctions.incorporate.activeForeground',
    ),
    'blue',
);

done_testing;
