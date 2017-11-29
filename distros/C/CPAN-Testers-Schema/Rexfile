
=head1 NAME

Rexfile - Rex task configuration for CPANTesters Schema

=head1 SYNOPSIS

    # Deploy the latest schema
    rex deploy

=head1 DESCRIPTION

This file defines all the L<Rex|http://rexify.org> tasks used to deploy
this application.

You must have already configured a user using the
L<cpantesters-deploy|http://github.com/cpan-testers/cpantesters-deploy>
repository, or been given an SSH key to use this Rexfile.

=head1 SEE ALSO

L<Rex|http://rexify.org>

=cut

use Rex -feature => [ 1.4 ];
use Rex::Commands::Sync;

#######################################################################
# Groups

group all => qw(
    cpantesters3.dh.bytemark.co.uk
    cpantesters4.dh.bytemark.co.uk
    cpantesters1.barnyard.co.uk
);

#######################################################################
# Settings

user 'cpantesters';
private_key '~/.ssh/cpantesters-rex';

# Used to find local, dev copies of the dist
set 'dist_name' => 'CPAN-Testers-Schema';

#######################################################################
# Environments
# The Vagrant VM for development purposes
environment vm => sub {
    group all => '192.168.127.127'; # the Vagrant VM IP
    set 'no_sudo_password' => 1;
};

#######################################################################

=head1 TASKS

=head2 deploy

    rex deploy
    rex -E vm deploy

Deploy the CPAN Testers schema from CPAN and upgrade the database schema
if necessary. Do this task after releasing a version of
CPAN::Testers::Schema to CPAN.

=cut

desc "Deploy the CPAN Testers Schema from CPAN";
task deploy =>
    group => 'all',
    sub {
        run 'source ~/.profile; cpanm CPAN::Testers::Schema DBD::mysql';
        run_task 'upgrade_database', on => connection->server;
    };

=head2 deploy_dev

    rex -E vm deploy_dev

Deploy a pre-release, development version of the schema. Use this to
install to your dev VM to test things. Will run `dzil build` locally
to build the tarball, then sync that tarball to the remote and install
using `cpanm`.

=cut

task deploy_dev =>
    group => 'all',
    sub {
        my $dist_name = get 'dist_name';
        my $dist;
        LOCAL {
            Rex::Logger::info( 'Building dist' );
            run 'dzil build';
            my @dists = sort glob "${dist_name}-*.tar.gz";
            $dist = $dists[-1];
        };

        Rex::Logger::info( 'Syncing ' . $dist );
        file '~/dist/' . $dist,
            source => $dist;

        Rex::Logger::info( 'Installing ' . $dist );
        run 'source ~/.profile; cpanm --notest ~/dist/' . $dist . ' DBD::mysql';

        run_task 'upgrade_database', on => connection->server;
    };

=head2 upgrade_database

Upgrade the database running on the given server. This task is called
automatically by C<deploy> and C<deploy_dev>.

This task also restarts all running services, since the code version and
the database version must match.

=cut

task upgrade_database =>
    group => 'all',
    sub {
        Rex::Logger::info( 'Upgrading database' );
        run 'source ~/.profile; cpantesters-schema upgrade';
        if ( $? ) {
            say last_command_output;
        }
        run_task 'restart', on => connection->server;
    };

=head2 install_database

Install the database on the server. This task should be called once to
initialize the database. It can be safely run on an already-existing
database.

=cut

task install_database =>
    group => 'all',
    sub {
        Rex::Logger::info( 'Installing database' );
        run 'mysql --defaults-file=~/.cpanstats.cnf --database "" -e"create database cpanstats"';
        run 'source ~/.profile; cpantesters-schema install';
        if ( $? ) {
            say last_command_output;
        }
    };

=head2 restart

Restart all the services on the machine. This is run automatically by
the deploy processes after upgrading the database.

The code version and the database version must be in-sync, and any
running processes must get the new code by restarting.

=cut

task restart =>
    group => 'all',
    sub {
        Rex::Logger::info( 'Restating all services' );
        run 'sv restart ~/service/*';
        if ( $? ) {
            say last_command_output;
        }
    };

#######################################################################

=head1 SUBROUTINES

=head2 ensure_sudo_password

Ensure a C<sudo> password is set. Use this at the start of any task
that requires C<sudo>.

=cut

sub ensure_sudo_password {
    return if sudo_password();
    return if get 'no_sudo_password';
    print 'Password to use for sudo: ';
    ReadMode('noecho');
    sudo_password ReadLine(0);
    ReadMode('restore');
    print "\n";
}

