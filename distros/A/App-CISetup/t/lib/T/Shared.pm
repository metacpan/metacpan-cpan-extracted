package T::Shared;

use strict;
use warnings;

use Test::Class::Moose bare => 1;
use Test2::Bundle::Extended '!meta';
use Test2::Plugin::NoWarnings 0.06;

use App::CISetup::Travis::ConfigFile;
use App::CISetup::Travis::ConfigUpdater;
use Path::Tiny qw( tempdir );
use YAML qw( DumpFile Load LoadFile );

with 'R::Tester';

sub test_stored_params {
    my $self = shift;

    my $dir  = tempdir();
    my $file = $dir->child('.travis.yml');

    my %p = (
        github_user          => 'autarch',
        email_address        => 'drolsky@cpan.org',
        force_threaded_perls => 0,
    );

    ## no critic (Variables::ProtectPrivateVars, Subroutines::ProtectPrivateSubs)
    no warnings 'redefine';
    local *App::CISetup::Travis::ConfigFile::_run3 = sub { };
    App::CISetup::Travis::ConfigFile->new(
        file => $file,
        %p,
    )->create_file;

    is(
        {
            App::CISetup::Travis::ConfigUpdater->_stored_params_from_file(
                $file)
        },
        \%p,
        '_stored_params_from_file'
    );

    my $updater = App::CISetup::Travis::ConfigUpdater->new(
        dir                  => $dir,
        force_threaded_perls => 1,
        email_address        => 'autarch@urth.org',
        github_user          => 'bob',
    );
    is(
        { $updater->_cf_params($file) },
        {
            file                 => $file,
            force_threaded_perls => 1,
            email_address        => 'autarch@urth.org',
            github_user          => 'bob',
        },
        'CLI params win over params stored in the file'
    );
}

__PACKAGE__->meta->make_immutable;

1;
