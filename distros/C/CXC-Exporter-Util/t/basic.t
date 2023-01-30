#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';

our %export_tags;
BEGIN {
    %export_tags = (
        'bar'   => ['foo'],
        default => ['bar'],
    );
}

package My::Exporter::Implicit::Overwrite {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    # this should get overwritten, so mess things up
    our %EXPORT_TAGS = ( snack => { foo => bar } );
    install_EXPORTS( {%::export_tags}, { overwrite => 1 } );
}

package My::Exporter::Implicit::Merge {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    our %EXPORT_TAGS = ( bar => $::export_tags{bar} );
    install_EXPORTS( { default => $::export_tags{default} }, );
}

package My::Exporter::Explicit {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    our %EXPORT_TAGS = %::export_tags;
    install_EXPORTS;
}

++$INC{'My/Exporter/Implicit/Overwrite.pm'};
++$INC{'My/Exporter/Implicit/Merge.pm'};
++$INC{'My/Exporter/Explicit.pm'};

for my $class (
    'My::Exporter::Implicit::Overwrite',
    'My::Exporter::Implicit::Merge',
    'My::Exporter::Explicit'
  )
{

    subtest "$class" => sub {
        is( export_from( $class, 'foo' )->foo,        'bar', "symbol" );
        is( export_from( $class, ':bar' )->foo(),     'bar', "tag" );
        is( export_from( $class )->bar(),             'foo', "default" );
        is( export_from( $class, ':default' )->bar(), 'foo', "default tag" );

        like(
            dies { export_from( $class, 'foo' )->bar },
            qr/object method "bar"/,
            "symbol foo doesn't import symbol bar"
        );

        like(
            dies { export_from( $class, ':bar' )->bar },
            qr/object method "bar"/,
            "tag bar doesn't import symbol bar"
        );

        like(
            dies { export_from( $class )->foo },
            qr/object method "foo"/,
            "default doesn$class, 't import symbol foo"
        );

        like(
            dies { export_from( $class, ':default' )->foo },
            qr/object method "foo"/,
            "default tag doesn't import symbol foo"
        );
    };

}

done_testing;
