
=head1 NAME

Rexfile - Rex task configuration for CPANTesters API application

=head1 SYNOPSIS

    # Deploy the latest API
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
group api => qw( cpantesters3.dh.bytemark.co.uk cpantesters1.barnyard.co.uk );

#######################################################################
# Settings

user 'cpantesters';
private_key '~/.ssh/cpantesters-rex';

# Used to find local, dev copies of the dist
set 'dist_name' => 'CPAN-Testers-API';

#######################################################################
# Environments
# The Vagrant VM for development purposes
environment vm => sub {
    group api => '192.168.127.127'; # the Vagrant VM IP
    set 'no_sudo_password' => 1;
};

#######################################################################

=head1 TASKS

=head2 deploy

    rex deploy
    rex -E vm deploy

Deploy the CPAN Testers API from CPAN. Do this task after releasing
a version of CPAN::Testers::API to CPAN.

=cut

desc "Deploy the CPAN Testers API from CPAN";
task deploy =>
    group => 'api',
    sub {
        run 'source ~/.profile; cpanm --with-recommends CPAN::Testers::API DBD::mysql';
        run_task 'deploy_service', on => connection->server;
        run_task 'restart', on => connection->server;
    };

=head2 deploy_dev

    rex -E vm deploy_dev

Deploy a pre-release, development version of the API. Use this to
install to your dev VM to test things. Will run `dzil build` locally
to build the tarball, then sync that tarball to the remote and install
using `cpanm`.

=cut

task deploy_dev =>
    group => 'api',
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
        run 'source ~/.profile; cpanm -v --notest --with-recommends ~/dist/' . $dist;
        if ( $? ) {
            say last_command_output;
        }
        run_task 'deploy_service', on => connection->server;
        run_task 'restart', on => connection->server;
    };

=head2 deploy_service

    rex deploy_service

Deploy the service files that run the daemons.

=cut

desc "Deploy service files";
task deploy_service =>
    group => 'api',
    sub {
        Rex::Logger::info( 'Deploying service files' );
        file '~/service/api/log',
            ensure => 'directory';
        file '~/service/api/run',
            source => 'etc/runit/api/run';
        file '~/service/api/api.conf',
            source => 'etc/runit/api/api.conf';
        file '~/service/api/log/run',
            source => 'etc/runit/api/log/run';
        file '~/service/broker/log',
            ensure => 'directory';
        file '~/service/broker/run',
            source => 'etc/runit/broker/run';
        file '~/service/broker/log/run',
            source => 'etc/runit/broker/log/run';

        file '~/service/legacy-metabase/log',
            ensure => 'directory';
        file '~/service/legacy-metabase/run',
            source => 'etc/runit/legacy-metabase/run';
        file '~/service/legacy-metabase/etc',
            ensure => 'directory';
        file '~/service/legacy-metabase/etc/metabase.conf',
            source => 'etc/runit/legacy-metabase/etc/metabase.conf';
        file '~/service/legacy-metabase/log/run',
            source => 'etc/runit/legacy-metabase/log/run';

        Rex::Logger::info( 'Deploying crontab entries' );
        file '~/var/log/metabase',
            ensure => 'directory';

        cron_entry 'tail-log',
            user => 'cpantesters',
            minute => '*/5',
            hour => '*',
            day_of_month => '*',
            month => '*',
            day_of_week => '*',
            ensure => 'present',
            command => 'MOJO_HOME=$HOME/service/legacy-metabase cpantesters-legacy-metabase eval "app->refresh_tail_log" >>$HOME/var/log/metabase/tail.log 2>&1',
            ;

    };

=head2 restart

    rex restart

Restart all the services.

=cut

desc "Restart services";
task restart =>
    group => 'api',
    sub {
        Rex::Logger::info( 'Restarting services' );
        run 'sv restart ~/service/api';
        run 'sv restart ~/service/broker';
        run 'sv restart ~/service/legacy-metabase';
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

