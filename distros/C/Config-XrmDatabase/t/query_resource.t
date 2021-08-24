#! perl

use Test2::V0;

use Config::XrmDatabase;

my $VALUE = '!!VALUE';

my $db = Config::XrmDatabase->new;

$db->insert( 'xmh*Paned*activeForeground',       'red' );
$db->insert( '*incorporate.Foreground',          'blue' );
$db->insert( 'xmh.toc*Command*activeForeground', 'green' );
$db->insert( 'xmh.toc*?.Foreground',             'white' );
$db->insert( 'xmh.toc*Command.activeForeground', 'black' );

my $got = $db->query( 'Xmh.Paned.Box.Command.Foreground',
    'xmh.toc.messagefunctions.incorporate.activeForeground' );

is( $got->{value}, 'black' );

done_testing;
