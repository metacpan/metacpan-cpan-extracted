
=head1 NAME

Rexfile - Rex task configuration for CPANTesters backend scripts

=head1 SYNOPSIS

    # Deploy the latest backend scripts
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
group backend => 'cpantesters3.dh.bytemark.co.uk';

#######################################################################
# Settings

user 'cpantesters';
private_key '~/.ssh/cpantesters-rex';

# Used to find local, dev copies of the dist
set 'dist_name' => 'CPAN-Testers-Backend';

#######################################################################
# Environments
# The Vagrant VM for development purposes
environment vm => sub {
    group backend => '192.168.127.127'; # the Vagrant VM IP
    set 'no_sudo_password' => 1;
};

#######################################################################

=head1 TASKS

=head2 deploy

    rex deploy
    rex -E vm deploy

Deploy the CPAN Testers backend from CPAN. Do this task after releasing
a version of CPAN::Testers::Backend to CPAN.

=cut

desc "Deploy the CPAN Testers backend from CPAN";
task deploy =>
    group => 'backend',
    sub {
        run 'source ~/.profile; cpanm CPAN::Testers::Backend DBD::mysql';
        file '~/etc/container',
            ensure => 'directory';
        sync_up 'etc/container' => '~/etc/container';
        for my $file ( qw( .profile .bash_profile ) ) {
            append_if_no_such_line '/home/cpantesters/' . $file,
                'export BEAM_PATH=$HOME/etc/container';
        }
    };

=head2 deploy_dev

    rex -E vm deploy_dev

Deploy a pre-release, development version of the backend. Use this to
install to your dev VM to test things. Will run `dzil build` locally to
build the tarball, then sync that tarball to the remote and install
using `cpanm`.

=cut

task deploy_dev =>
    group => 'backend',
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
        run 'source ~/.profile; cpanm -v ~/dist/' . $dist;
        if ( $? ) {
            say last_command_output;
        }
        file '~/etc/container',
            ensure => 'directory';
        sync_up 'etc/container' => '~/etc/container';
        for my $file ( qw( .profile .bash_profile ) ) {
            append_if_no_such_line '/home/cpantesters/' . $file,
                'export BEAM_PATH=$HOME/etc/container';
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

