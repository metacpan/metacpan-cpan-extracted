#! perl

use Test2::V0;
use List::Util 1.29;
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

subtest values => sub {

    subtest 'value only' => sub {
        my $kv = $db->to_kv( value => 'value' );

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
            'return'
        );
    };

    subtest 'match_count only' => sub {
        my $kv = $db->to_kv( value => 'match_count' );
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
            'return'
        );
    };

    subtest 'all' => sub {

        my $kv = $db->to_kv( value => 'all' );
        is(
            $kv,
            hash {
                field 'xmh*Paned*activeForeground' => hash {
                    field value       => 'red';
                    field match_count => 1;
                    end;
                };
                field '*incorporate.Foreground' => hash {
                    field value       => 'blue';
                    field match_count => 0;
                };
                field 'xmh.toc*Command*activeForeground' => hash {
                    field value       => 'green';
                    field match_count => 0;
                };
                field 'xmh.toc*?.Foreground' => hash {
                    field value       => 'white';
                    field match_count => 0;
                };
                field 'xmh.toc*Command.activeForeground' => hash {
                    field value       => 'black';
                    field match_count => 1;
                };
                end;
            },
            'return'
        );
    };

};

subtest 'array keys' => sub {

    my $kv = $db->to_kv_arr( value => 'value' );
    is(
        $kv,
        bag {
            item [ [qw( xmh * Paned * activeForeground )]       => 'red' ];
            item [ [qw( * incorporate Foreground )]             => 'blue' ];
            item [ [qw( xmh toc * Command * activeForeground )] => 'green' ];
            item [ [qw( xmh toc * ? Foreground )]               => 'white' ];
            item [ [qw( xmh toc * Command activeForeground )]   => 'black' ];
            end;
        },
        'return'
    );
};

done_testing;
