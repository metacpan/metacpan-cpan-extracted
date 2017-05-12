use Test::More tests => 4;
use strict;
use vars qw( $tests $o );
use Class::CompoundMethods 'prepend_method';

$o = Object->new;

{
    sub FQSymref { $tests .= "ByFQSymref"; }
    prepend_method( 'Object::method', __PACKAGE__ . '::FQSymref' );
    $tests = '';
    $o->method;
    is( $tests, "ByFQSymrefOriginal", 'By fully qualified sub name' );
}

{

    package Object;
    sub RelativeSymref { $main::tests .= "ByRelativeSymref"; }
    main::prepend_method( 'method', __PACKAGE__ . '::RelativeSymref' );
    $main::tests = '';
    $main::o->method;
    main::is(
        $main::tests,
        "ByRelativeSymrefByFQSymrefOriginal",
        'By relative symref'
    );
}

{
    sub HardRef { $tests .= "ByHardref"; }
    prepend_method( 'Object::method', \&HardRef );
    $tests = '';
    $o->method;
    is( $tests,
        "ByHardrefByRelativeSymrefByFQSymrefOriginal",
        'By hard reference'
    );
}

{
    sub RelativeSource { $tests .= "ByRelativeSource" }
    prepend_method( 'Object::method', 'RelativeSource' );
    $tests = '';
    $o->method;
    is( $tests,
        "ByRelativeSourceByHardrefByRelativeSymrefByFQSymrefOriginal",
        "By relative source"
    );
}

# {
#
#     package Object;
#     *prepend_method = \&main::prepend_method;
#     prepend_method( 'method', sub { $main::tests .= "3" } );
#     $main::tests = '';
#     $main::o->method;
#     use Data::Dumper;
#     print STDERR Dumper( \%Class::CompoundMethods::METHODS );
#     Test::More::is( $main::tests, "123", "By reference" );
# }

package Object;

sub method { $main::tests .= "Original" }

sub new {
    return bless [], __PACKAGE__;
}
