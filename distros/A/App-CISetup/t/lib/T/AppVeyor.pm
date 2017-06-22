package T::AppVeyor;

use strict;
use warnings;

use Test::Class::Moose bare => 1;
use Test2::Bundle::Extended '!meta';
use Test2::Plugin::NoWarnings;

use App::CISetup::AppVeyor::ConfigFile;
use Path::Tiny qw( tempdir );
use YAML qw( DumpFile Load LoadFile );

with 'R::Tester';

sub test_create {
    my $self = shift;

    my $dir  = tempdir();
    my $file = $dir->child('appveyor.yml');

    App::CISetup::AppVeyor::ConfigFile->new(
        file                => $file,
        encrypted_slack_key => 'encrypted',
        slack_channel       => 'my-channel',
        email_address       => 'drolsky@cpan.org',
    )->create_file;

    my $appveyor = LoadFile($file);
    is(
        $appveyor,
        {
            cache   => ['C:\strawberry'],
            install => [
                'if not exist "C:\strawberry" cinst strawberryperl -y',
                'set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%',
                'cd %APPVEYOR_BUILD_FOLDER%',
                'cpanm --installdeps . -n',
            ],
            build_script  => ['perl -e 1'],
            test_script   => ['prove -lrv t/'],
            skip_tags     => 'true',
            notifications => [
                {
                    provider                => 'Slack',
                    auth_token              => { secure => 'encrypted' },
                    channel                 => 'my-channel',
                    on_build_failure        => 'true',
                    on_build_status_changed => 'true',
                    on_build_success        => 'true',
                },
                {
                    provider                => 'Email',
                    subject                 => 'AppVeyor build {{status}}',
                    to                      => ['drolsky@cpan.org'],
                    on_build_failure        => 'true',
                    on_build_status_changed => 'true',
                    on_build_success        => 'false',
                },
            ],
        },
        'created file contains expected content',
    );

    $self->_test_cisetup_flags_comment(
        $file,
        {
            email_address => 'drolsky@cpan.org',
            slack_channel => 'my-channel',
        }
    );

    App::CISetup::AppVeyor::ConfigFile->new(
        file                => $file,
        encrypted_slack_key => 'encrypted',
        slack_channel       => 'my-channel',
        email_address       => 'drolsky@cpan.org',
    )->update_file;

    my $updated = LoadFile($file);
    is( $appveyor, $updated, 'file was not changed by second update' );
}

sub test_update {
    my $self = shift;

    my $dir  = tempdir();
    my $file = $dir->child('appveyor.yml');

    $file->spew(<<'EOF');
cache:
  - C:\strawberry

install:
  - if not exist "C:\strawberry" cinst strawberryperl -y
  - set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%
  - cd %APPVEYOR_BUILD_FOLDER%
  - cpanm --installdeps . -n

build_script:
  - perl -e 1

test_script:
  - prove -lrv t/

skip_tags: true
EOF

    App::CISetup::AppVeyor::ConfigFile->new(
        file                => $file,
        encrypted_slack_key => 'encrypted',
        slack_channel       => 'my-channel',
        email_address       => 'drolsky@cpan.org',
    )->update_file;

    my $appveyor = LoadFile($file);
    is(
        $appveyor,
        {
            cache   => ['C:\strawberry'],
            install => [
                'if not exist "C:\strawberry" cinst strawberryperl -y',
                'set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%',
                'cd %APPVEYOR_BUILD_FOLDER%',
                'cpanm --installdeps . -n',
            ],
            build_script  => ['perl -e 1'],
            test_script   => ['prove -lrv t/'],
            skip_tags     => 'true',
            notifications => [
                {
                    provider                => 'Slack',
                    auth_token              => { secure => 'encrypted' },
                    channel                 => 'my-channel',
                    on_build_failure        => 'true',
                    on_build_status_changed => 'true',
                    on_build_success        => 'true',
                },
                {
                    provider                => 'Email',
                    subject                 => 'AppVeyor build {{status}}',
                    to                      => ['drolsky@cpan.org'],
                    on_build_failure        => 'true',
                    on_build_status_changed => 'true',
                    on_build_success        => 'false',
                },
            ],
        },
        'update added notifications',
    );

    $self->_test_cisetup_flags_comment(
        $file,
        {
            email_address => 'drolsky@cpan.org',
            slack_channel => 'my-channel',
        }
    );

    App::CISetup::AppVeyor::ConfigFile->new(
        file                => $file,
        encrypted_slack_key => 'encrypted',
        slack_channel       => 'my-channel',
        email_address       => 'drolsky@cpan.org',
    )->update_file;

    my $updated = LoadFile($file);
    is( $appveyor, $updated, 'file was not changed by second update' );
}

__PACKAGE__->meta->make_immutable;

1;
