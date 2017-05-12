#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use FindBin;
use File::Spec::Functions qw/catfile/;
use App::pmdeps;

use Test::More;
use Test::MockObject::Extends;

BEGIN {
    $ENV{ANSI_COLORS_DISABLED} = 1;
}

subtest 'remote' => sub {
    my $app = App::pmdeps->new;
    my $app_mock = Test::MockObject::Extends->new($app);
    $app_mock->mock(
        '_fetch_deps_from_metacpan',
        sub {
            my ($self) = @_;
            return [ {module => 'Module::Build'}, {module => 'base'} ];
        }
    );

    subtest 'use perl 5.008001' => sub {
        my ($got) = capture {
            $app->run('-p', '5.008001', 'Foo::Bar');
        };
        is $got, <<EOS;
Target: perl-5.008001
Depends on 1 core module:
\tbase
Depends on 1 non-core module:
\tModule::Build
EOS
        };

    subtest 'use perl 5.010001' => sub {
        my ($got) = capture {
            $app->run('--perl-version', '5.010001', 'Foo::Bar');
        };
        is $got, <<EOS;
Target: perl-5.010001
Depends on 2 core modules:
\tModule::Build
\tbase
Depends on no non-core module.
EOS
    };
};

subtest 'local' => sub {
    subtest 'use meta_json' => sub {
        subtest 'all' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-l', catfile($FindBin::Bin, 'resource'), '-p', '5.008001');
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 2 core modules:
\tCarp
\tGetopt::Long
Depends on 8 non-core modules:
\tAcme
\tAcme::Anything
\tAcme::Buffy
\tFurl
\tJSON
\tModule::Build
\tModule::CoreList
\tTest::Perl::Critic
EOS
        };

        subtest 'without some phases' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-l', catfile($FindBin::Bin, 'resource'), '-p', '5.008001', '--without-phase', 'configure,develop');
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 2 core modules:
\tCarp
\tGetopt::Long
Depends on 5 non-core modules:
\tAcme
\tAcme::Anything
\tFurl
\tJSON
\tModule::CoreList
EOS
        };

        subtest 'without some types' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-l', catfile($FindBin::Bin, 'resource'), '-p', '5.008001', '--without-type', 'recommends,suggests');
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 2 core modules:
\tCarp
\tGetopt::Long
Depends on 5 non-core modules:
\tFurl
\tJSON
\tModule::Build
\tModule::CoreList
\tTest::Perl::Critic
EOS
        };
    };

    subtest 'use mymeta_json' => sub {
        subtest 'all' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-p', '5.008001', '--local', catfile($FindBin::Bin, 'resource', 'mymeta_only'));
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 1 core module:
\tCarp
Depends on 7 non-core modules:
\tAcme
\tAcme::Anything
\tAcme::Buffy
\tFurl
\tJSON
\tModule::Build
\tTest::Perl::Critic
EOS
        };

        subtest 'without some phases' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-p', '5.008001', '--local', catfile($FindBin::Bin, 'resource', 'mymeta_only'), '--without-phase', 'configure,develop');
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 1 core module:
\tCarp
Depends on 4 non-core modules:
\tAcme
\tAcme::Anything
\tFurl
\tJSON
EOS
        };

        subtest 'without some types' => sub {
            my ($got) = capture {
                App::pmdeps->new->run('-p', '5.008001', '--local', catfile($FindBin::Bin, 'resource', 'mymeta_only'), '--without-type', 'recommends,suggests');
            };
            is $got, <<EOS;
Target: perl-5.008001
Depends on 1 core module:
\tCarp
Depends on 4 non-core modules:
\tFurl
\tJSON
\tModule::Build
\tTest::Perl::Critic
EOS
        };
    };

    subtest 'not exists META.json or MYMETA.json' => sub {
        eval { App::pmdeps->new->run( '-l', catfile($FindBin::Bin) ) };
        ok $@, 'dies ok';
    };
};
done_testing;
