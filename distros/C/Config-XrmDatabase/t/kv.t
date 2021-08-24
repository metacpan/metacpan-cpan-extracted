#! perl

use Test2::V0;

use Config::XrmDatabase;

my $db = Config::XrmDatabase->new;

$db->insert( 'xmh*Paned*activeForeground',       'red' );
$db->insert( '*incorporate.Foreground',          'blue' );
$db->insert( 'xmh.toc*Command*activeForeground', 'green' );
$db->insert( 'xmh.toc*?.Foreground',             'white' );
$db->insert( 'xmh.toc*Command.activeForeground', 'black' );

$db->query( 'Xmh.Paned.Box.Command.Foreground',
    'xmh.toc.messagefunctions.incorporate.activeForeground' );


$db->query( 'Xmh.Paned.Box.Command.Foreground',
    'xmh.Paned.messagefunctions.incorporate.activeForeground' );

{
    my $kv = $db->to_kv( 'value' );

    is(
        $kv,
        hash {
            field 'xmh*Paned*activeForeground'       => 'red';
            field '*incorporate.Foreground'          => 'blue';
            field 'xmh.toc*Command*activeForeground' => 'green';
            field 'xmh.toc*?.Foreground'             => 'white';
            field 'xmh.toc*Command.activeForeground' => 'black';
            end;
        },
        'value only'
    );
}

{
    my $kv = $db->to_kv( 'match_count' );
    is(
        $kv,
        hash {
            field 'xmh*Paned*activeForeground'       => 1;
            field '*incorporate.Foreground'          => 0;
            field 'xmh.toc*Command*activeForeground' => 0;
            field 'xmh.toc*?.Foreground'             => 0;
            field 'xmh.toc*Command.activeForeground' => 1;
            end;
        },
        'match_count only'
    );
}

{
    my $kv = $db->to_kv( 'all' );
    is(
        $kv,
        hash {
            field 'xmh*Paned*activeForeground' => hash {
                field value     => 'red';
                field match_count => 1;
                end;
            };
            field '*incorporate.Foreground' => hash {
                field value     => 'blue';
                field match_count => 0;
            };
            field 'xmh.toc*Command*activeForeground' => hash {
                field value     => 'green';
                field match_count => 0;
            };
            field 'xmh.toc*?.Foreground' => hash {
                field value     => 'white';
                field match_count => 0;
            };
            field 'xmh.toc*Command.activeForeground' => hash {
                field value     => 'black';
                field match_count => 1;
            };
            end;
        },
        'all'
    );
}

done_testing;
