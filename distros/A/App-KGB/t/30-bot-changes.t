use strict;
use warnings;

use Test::More;

use App::KGB::Change;

sub is_common_dir {
    my ( $cs, $wanted ) = @_;

    is( App::KGB::Change->detect_common_dir(
            [ map ( App::KGB::Change->new($_), @$cs ) ]
        ),
        $wanted
    );
}

is_common_dir( [ '(A)foo/bar', '(A)foo/dar', '(A)foo/bar/dar' ], 'foo' );
is_common_dir( [ '(A)debian/patches/series', '(A)debian/patches/moo.patch' ], 'debian/patches' );
is_common_dir( [ 'trunk/packages/po/sublevel4/vi.po', 'trunk/packages/po/sublevel3/vi.po' ], 'trunk/packages/po' );

done_testing();
