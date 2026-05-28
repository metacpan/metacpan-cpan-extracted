#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';
use experimental 'signatures';

BEGIN {
    eval { require Exporter::Tiny; 1 }
      or skip_all 'Exporter::Tiny required for ui helper tests';
}

use constant HELPERS => qw( ui_list_constants ui_coerce_constant ui_assert_coerce_constant );

package My::Regression::SingleConstant {
    use CXC::Exporter::Util 'install_CONSTANTS', 'install_EXPORTS', ':ui_helpers';
    use parent 'Exporter::Tiny';

    install_CONSTANTS( { SINGLE => [ ONLY_ONE => 'only_one' ] } );
    install_EXPORTS;
}

++$INC{'My/Regression/SingleConstant.pm'};

use constant CLASS => 'My::Regression::SingleConstant';

sub imported_sub ( $pkg, $name ) {
    no strict 'refs';    ## no critic (NoStrict)
    return *{"${pkg}::${name}"}{CODE};
}

my $pkg;
ok( lives { $pkg = export_from( CLASS, HELPERS ) }, 'imported' );

my %s;
ok( $s{$_} = imported_sub( $pkg, $_ ), "$_ imported" ) for HELPERS;

my @names;
ok(
    lives { @names = $s{ui_list_constants}->( 'single' ) },
    'single-constant tag names are copied before alias transformations'
);

is(
    \@names,
    bag {
        item 'only_one';
        item 'only-one';
        end;
    },
    'single-constant tag aliases are listed'
);

is( $s{ui_coerce_constant}->( 'only-one', 'single' ),
    'only_one', 'single-constant tag aliases can be coerced' );

done_testing;
