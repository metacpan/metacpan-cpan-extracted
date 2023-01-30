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

package My::Exporter::Exporter::True {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    install_EXPORTS( {%::export_tags}, { all => 1 } );
}

package My::Exporter::Exporter::False {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    install_EXPORTS( {%::export_tags}, { all => 0 } );
}

package My::Exporter::Exporter::Auto {
    use CXC::Exporter::Util;
    use Exporter 'import';
    sub foo { 'bar' }
    sub bar { 'foo' }
    install_EXPORTS( {%::export_tags}, );
    1;
}

package My::Exporter::Exporter::Tiny {
    use CXC::Exporter::Util;
    use base 'Exporter::Tiny';
    sub foo { 'bar' }
    sub bar { 'foo' }
    install_EXPORTS( {%::export_tags}, );
}

++$INC{'My/Exporter/Exporter/True.pm'};
++$INC{'My/Exporter/Exporter/False.pm'};
++$INC{'My/Exporter/Exporter/Auto.pm'};
++$INC{'My/Exporter/Exporter/Tiny.pm'};


for my $class (
    'My::Exporter::Exporter::True',
    'My::Exporter::Exporter::Auto',
    'My::Exporter::Exporter::Tiny'
  )
{
    subtest "$class" => sub {
        is( export_from( $class, ':all' )->foo, 'bar', "symbol" );
    };
}

for my $class ( 'My::Exporter::Exporter::False', ) {
    subtest "$class" => sub {
        like(
            dies { export_from( $class, ':all' )->foo },
            qr/can't continue after import errors/i,
            "all tag doesn't import symbol foo"
        );
    };
}

done_testing;
