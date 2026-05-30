#! perl

use v5.22;

use Test2::V0;

BEGIN {
    skip_all( 'namespace::clean is not installed' )
      unless eval q{ no namespace::clean; 1 };
}

package    #
  My::Test1 {
    use parent 'Exporter::Tiny';
    use CXC::Exporter::Util ':all';
    use namespace::clean;

    install_EXPORTS( { fruit => ['tomato'] } );

    sub tomato { }
}

package    #
  My::Test1::Caller {
    use Test2::V0;

    my $pkg = __PACKAGE__ =~ s/::Caller//r;

    subtest ':all, cleaned' => sub {

        if ( ok( lives { $pkg->import( ':all' ) }, 'import all tag succeeded' ) ) {
            ok( !__PACKAGE__->can( 'ui_list_constants' ), 'no ui helper' );
            ok( __PACKAGE__->can( 'tomato' ),             'imported user defined symbol' );
        }
    };
}

package    #
  My::Test2 {
    use parent 'Exporter::Tiny';
    use CXC::Exporter::Util;
    use namespace::clean;
    use CXC::Exporter::Util ':ui_helpers';

    install_EXPORTS( { fruit => ['tomato'] } );

    sub tomato { }
}

package    #
  My::Test2::Caller {
    use Test2::V0;

    my $pkg = __PACKAGE__ =~ s/::Caller//r;

    subtest 'ui_helper, correctly cleaned' => sub {
        if ( ok( lives { $pkg->import( ':all' ) }, 'import all tag succeeded' ) ) {
            ok( __PACKAGE__->can( 'ui_list_constants' ), 'imported ui helper' );
            ok( __PACKAGE__->can( 'tomato' ),            'imported user defined symbol' );
        }
    };
}

package My::Test3 {
    use parent 'Exporter::Tiny';
    use CXC::Exporter::Util ':default', ':ui_helpers';
    use namespace::clean;

    install_EXPORTS( { fruit => ['tomato'] }, { all => 1 } );

    sub tomato { }
}

package My::Test3::Caller {
    use Test2::V0;

    my $pkg = __PACKAGE__ =~ s/::Caller//r;

    subtest 'ui_helpers, incorrect clean' => sub {
        like( dies { $pkg->import( ':all' ) }, qr/could not find sub/i, 'import all tag failed' );
    };
}


done_testing;
