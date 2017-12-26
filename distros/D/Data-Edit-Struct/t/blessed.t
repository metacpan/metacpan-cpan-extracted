#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];


subtest 'src' => sub {

    my $dest;
    my $src;

    my $edit = sub {
        edit(
            insert => {
                dest  => $dest,
                dpath => '/',
                src   => $src,
                stype => 'auto'
            },
        );
        return $dest;
    };

    subtest 'hash' => sub {
        $dest = [];
        $src = { a => 1 };

        is( $edit->(), [%$src], "unblessed" );

        $dest = [];
        bless $src;

        is( $edit->()->[0], $src, "blessed" );
    };

    subtest "array" => sub {

        $dest = [];
        $src = [ a => 1 ];

        is( $edit->(), [@$src], "unblessed" );

        $dest = [];
        bless $src;

        is( $edit->()->[0], $src, "blessed" );
    };

};

subtest 'dest' => sub {

    my $dest;
    my $src = [ b => 2 ];

    my $edit = sub {
        edit(
            insert => {
                dest  => $dest,
		dtype => 'auto',
	        dpath => '/*[0]',
                src   => $src,
                stype => 'container'
            },
        );

        return $dest;
    };

    subtest 'hash' => sub {
        $dest = [ { a => 1 } ];

        is( $edit->(), [ { a => 1, b => 2 } ], "unblessed" );

	my $obj = bless { a => 1 };
        $dest = [ $obj  ];

        is( $edit->(), [ 'b', '2', $obj ], "blessed" );
    };

    subtest "array" => sub {

        $dest = [ [ a => 1 ] ];

        is( $edit->(), [ [ b => 2, a => 1 ] ], "unblessed" );

	my $obj = bless [ a => 1 ];
        $dest = [ $obj  ];

        is( $edit->(), [ @$src, $obj ], "blessed" );
    };

};


done_testing;
