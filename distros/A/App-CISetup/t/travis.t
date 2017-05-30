use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;

use App::CISetup::Travis::ConfigFile;
use Path::Tiny qw( tempdir );
use YAML qw( DumpFile Load LoadFile );

subtest(
    'create and update',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->create_file;

        my $yaml = $file->slurp;

        for my $v (qw( 5.14 5.16 5.18 5.20 5.22 5.24 )) {
            like(
                $yaml,
                qr/^ +- \Q'$v'\E$/ms,
                "created file includes Perl $v"
            );
        }

        for my $v (qw( 5.8 5.10 5.12 )) {
            unlike(
                $yaml,
                qr/^ +- \Q'$v'\E$/ms,
                "created file does not include Perl $v"
            );
        }

        like(
            $yaml,
            qr/
              ^__app_cisetup__:.+\n
              ^sudo:.+\n
              ^addons:.+\n
              ^language:.+\n
              ^perl:.+\n
              ^matrix:.+\n
              ^env:.+\n
          before_install:.+\n
         /msx,
            'yaml blocks are in the right oder'
        );

        my $travis = Load($yaml);
        is(
            $travis,
            {
                __app_cisetup__ => { force_threaded_perls => 0 },
                sudo            => 'false',
                addons          => {
                    apt => {
                        packages => [ 'aspell', 'aspell-en' ],
                    },
                },
                language => 'perl',
                perl     => [
                    qw(
                        blead
                        dev
                        5.24
                        5.22
                        5.20
                        5.18
                        5.16
                        5.14
                        )
                ],
                matrix => {
                    allow_failures => [ { perl => 'blead' } ],
                    include        => [
                        {
                            env  => 'COVERAGE=1',
                            perl => '5.24'
                        }
                    ],
                },
                env =>
                    { global => [ 'AUTHOR_TESTING=1', 'RELEASE_TESTING=1' ] },
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
            },
            'travis config contains expected content'
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->update_file;

        my $updated = LoadFile($file);
        is( $travis, $updated, 'file was not changed by update' );
    }
);

subtest(
    'force threaded perls',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 1,
        )->create_file;

        my $yaml = $file->slurp;

        for my $v (qw( 5.14.4 5.16.3 5.18.3 5.20.3 5.22.3 5.24.1 )) {
            for my $t ( $v, "$v-thr" ) {
                like(
                    $yaml,
                    qr/^ +- \Q$t\E$/ms,
                    "created file includes Perl $t"
                );
            }
        }
    }
);

subtest(
    'distro has xs',
    sub {
        my $dir = tempdir();
        $dir->child('Foo.xs')->touch;
        my $file = $dir->child('.travis.yml');

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->create_file;

        my $yaml = $file->slurp;

        for my $v (qw( 5.14.4 5.16.3 5.18.3 5.20.3 5.22.3 5.24.1 )) {
            for my $t ( $v, "$v-thr" ) {
                like(
                    $yaml,
                    qr/^ +- \Q$t\E$/ms,
                    "created file includes Perl $t"
                );
            }
        }
    }
);

subtest(
    'update helpers usage',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        DumpFile(
            $file, {
                language       => 'perl',
                before_install => [
                    '$(curl git://github.com/haarg/perl-travis-helper) --auto'
                ],
                perl => ['5.24'],
            }
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->update_file;

        my $travis = LoadFile($file);
        is(
            $travis->{before_install},
            ['eval $(curl https://travis-perl.github.io/init) --auto'],
            'old travis-perl URL is replaced'
        );
    }
);

subtest(
    'maybe disable sudo',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        DumpFile(
            $file, {
                sudo           => 'true',
                language       => 'perl',
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
                perl => ['5.24'],
            }
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->update_file;

        is(
            LoadFile($file)->{sudo},
            'false',
            'sudo is disabled when it is not being used',
        );
        DumpFile(
            $file, {
                sudo           => 'true',
                language       => 'perl',
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
                install => ['sudo foo'],
                perl    => ['5.24'],
            }
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
        )->update_file;

        is(
            LoadFile($file)->{sudo},
            'true',
            'sudo is not disabled when it is being used',
        );
    }
);

subtest(
    'coverity email',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        DumpFile(
            $file, {
                sudo     => 'true',
                language => 'perl',
                addons   => {
                    coverity_scan =>
                        { notification_email => 'foo@example.com' }
                },
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
                perl => ['5.24'],
            }
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
            email_address        => 'bar@example.com',
        )->update_file;

        is(
            LoadFile($file)->{addons}{coverity_scan},
            { notification_email => 'bar@example.com' },
            'email address for coverity_scan is updated',
        );
    }
);

subtest(
    'email notifications',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        DumpFile(
            $file, {
                sudo           => 'true',
                language       => 'perl',
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
                perl => ['5.24'],
            }
        );

        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
            email_address        => 'bar@example.com',
        )->update_file;

        is(
            LoadFile($file)->{notifications},
            {
                email => {
                    recipients => ['bar@example.com'],
                    on_success => 'change',
                    on_failure => 'always',
                },
            },
            'email address for notifications is added when email is provided',
        );
    }
);

subtest(
    'slack notifications',
    sub {
        my $dir  = tempdir();
        my $file = $dir->child('.travis.yml');

        DumpFile(
            $file, {
                sudo           => 'true',
                language       => 'perl',
                before_install => [
                    'eval $(curl https://travis-perl.github.io/init) --auto'],
                perl => ['5.24'],
            }
        );

        my @run3;
        no warnings 'redefine';
        ## no critic (Variables::ProtectPrivateVars)
        local *App::CISetup::Travis::ConfigFile::_run3 = sub {
            shift;
            push @run3, @_;
            ${ $_[2] } = q{"encrypted"};
        };

        my $slack_key = 'slack key';
        App::CISetup::Travis::ConfigFile->new(
            file                 => $file,
            force_threaded_perls => 0,
            slack_key            => $slack_key,
            github_user          => 'autarch',
        )->update_file;

        is(
            LoadFile($file)->{notifications},
            {
                slack => { rooms => { secure => 'encrypted' } },
            },
            'slack notification is added when slack key and github user is provided',
        );
        is(
            $run3[0],
            [
                qw( travis encrypt --no-interactive -R ),
                'autarch/' . $dir->basename, $slack_key
            ],
            'travis CLI command is run to encrypt slack key'
        );
    }
);

done_testing();
