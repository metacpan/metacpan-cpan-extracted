#! perl

use Test2::V0;
use Test::Lib;
use My::Test::Utils 'export_from';

package My::Exporter {
    use CXC::Exporter::Util 'install_CONSTANTS', 'install_EXPORTS';
    use Exporter 'import';

    BEGIN {
        install_CONSTANTS( {
                DETECTORS => [
                    ACIS => 'acis',
                ],
            },
            [
                [ 'Tag', 'ValueFunc', 'NameFunc' ] => {
                    ALL  => 'all',
                    NONE => 'none',
                    ANY  => 'any',
                },
            ] );
    }

    install_EXPORTS;
}

++$INC{'My/Exporter.pm'};

use constant class => 'My::Exporter';


subtest 'misspelled constant_funcs as constants_funcs' => sub {
    is( export_from( class, ':constants_funcs' )->ValueFunc, D(), 'ValueFunc' );
};

done_testing;
