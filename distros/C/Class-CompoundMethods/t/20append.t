use Test::More tests => 4;
use strict;
use vars qw( $tests $o );
use Class::CompoundMethods 'append_method';

$o = Object->new;

{
    sub FQSymref { $tests .= "ByFQSymref"; }
    append_method( 'Object::method', __PACKAGE__ . '::FQSymref' );
    $tests = '';
    $o->method;
    is( $tests, "OriginalByFQSymref", 'By fully qualified sub name' );
}

{

    package Object;
    sub RelativeSymref { $main::tests .= "ByRelativeSymref"; }
    main::append_method( 'method', __PACKAGE__ . '::RelativeSymref' );
    $main::tests = '';
    $main::o->method;
    main::is(
        $main::tests,
        "OriginalByFQSymrefByRelativeSymref",
        'By relative symref'
    );
}

{
    sub HardRef { $tests .= "ByHardref"; }
    append_method( 'Object::method', \&HardRef );
    $tests = '';
    $o->method;
    is( $tests,
        "OriginalByFQSymrefByRelativeSymrefByHardref",
        'By hard reference'
    );
}

{
    sub RelativeSource { $tests .= "ByRelativeSource" }
    append_method( 'Object::method', 'RelativeSource' );
    $tests = '';
    $o->method;
    is( $tests,
        "OriginalByFQSymrefByRelativeSymrefByHardrefByRelativeSource",
        "By relative source"
    );
}

# {
#
#     package Object;
#     *append_method = \&main::append_method;
#     append_method( 'method', sub { $main::tests .= "3" } );
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
