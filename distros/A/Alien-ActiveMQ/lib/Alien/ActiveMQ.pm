package Alien::ActiveMQ;

use Moose;
use MooseX::Types::Path::Class;
use Method::Signatures::Simple;
use File::ShareDir qw/dist_dir/;
use Path::Class qw/file dir/;
use Scope::Guard;
use IPC::Run qw/start run/;
use Net::Stomp;
use Sort::Versions;
use namespace::autoclean;

our $VERSION = '0.00005';

# Note: Many of the methods in this class need to be usable as class methods.
# This means you can't use Moose attributes, because they try and store data
# on the class name, which fails.  Only normal methods here.

# To make mocking easier.
sub _dist_dir {
    return dir( dist_dir('Alien-ActiveMQ') );
}

method _output {
    my $msg = "@_\n";
    return warn($msg);
}

method startup_timeout {
    return 300;
}

method get_installed_versions {
    my @dirs     = $self->_dist_dir->children;
    my @versions = ();
    foreach my $dir (@dirs) {
        if ( $dir->basename =~ /^\d[\d.]+$/ ) {
            push @versions, $dir->basename;
        }
    }
    return ( sort { versioncmp( $b, $a ); } @versions );
}

method get_version_dir($version) {
    if ( !$version ) {
        $version = ( $self->get_installed_versions )[0];
    }
    if ($version) {
        return dir( $self->_dist_dir, $version );
    }
    return;
}

method is_version_installed($version) {
    return $self->get_version_dir($version)
      && ( -d $self->get_version_dir($version) );
}

method get_license_filename($version) {
    my $dir = $self->get_version_dir($version);
      return file( $dir, 'LICENSE' );
}

method get_licence_filename($version) {
    return $self->get_license_filename($version);
}

method run_server($version) {
    my $dir = $self->get_version_dir($version);
      my @cmd = ( file( $dir, 'bin', 'activemq' ) );

      # Check if we need to use the console verb to get the command to start.
      my $consoleflag = $self->_check_output( [ @cmd, '--help' ], qr/(stop)/ );

      if ($consoleflag) {
        push @cmd, 'console';
    }

    # Start activemq in a subprocess
    $self->_output("Running @cmd");
    my $h = start \@cmd, \undef;

    my $pid = $h->{KIDS}[0]{PID}; # FIXME!
    # Spin until we can get a connection
    my ( $stomp, $loop_count );
    while ( !$stomp ) {
        if ( $loop_count++ > $self->startup_timeout ) {
            $h->signal("KILL");
            die "Can't connect to ActiveMQ after trying "
              . $self->startup_timeout
              . " seconds.";
        }
        eval {
            $stomp = Net::Stomp->new(
                {
                    hostname => 'localhost',
                    port     => 61613
                }
            );
        };
        if ($@) {
            sleep 1;
        }
    }

    return Scope::Guard->new(
        sub {
            $self->_output("Killing ApacheMQ...");
            $h ? $h->signal ( "KILL" ) : kill $pid, 15;
        }
    );
}

method _check_output( $cmd, $output ) {
    my $text = '';
        run( $cmd, \undef, \$text );
        if ( my @matches = $text =~ $output ) {
            return @matches;
    }
    return;
}

1;

__END__

=for stopwords ActiveMQ MQ perl queueing TODO github Doran undef

=head1 NAME

Alien::ActiveMQ - Manages installs of versions of Apache ActiveMQ, and provides a standard
way to start an MQ server from perl.

=head1 SYNOPSIS

    use Alien::ActiveMQ;

    {
        my $mq = Alien::ActiveMQ->run_server

        # Apache MQ is now running on the default port, you
        # can now test your Net::Stomp based code
    }
    # And Apache MQ shuts down once $mq goes out of scope here

=head1 DESCRIPTION

This module, along with the bundled C< install-apachemq > script,
helps to manage installations of the Apache ActiveMQ message queueing software,
from L<http://activemq.apache.org>.

=head1 CLASS METHODS

=head2 run_server ([ $version ])

Runs an ActiveMQ server instance for you.

Returns a value which you must keep in scope until you want the ActiveMQ server
to shutdown.

=head2 get_installed_versions ()

Returns a list of all the installed versions.  Will return an empty list if nothing is installed.

=head2 get_version_dir ([ $version ])

Returns a L<Path::Class::Dir> object to where a particular version of ActiveMQ
is installed.  Passing an explicit version returns where that version would be installed,
even if it is not currently installed.

If a version is not provided, then the latest available version installed is returned.

If no versions are installed  and no version is passed, undef is returned.

=head2 is_version_installed ([ $version ])

Returns true if the version directory for the supplied version exists.

=head2 get_license_filename ([ $version ])

Returns a L<Path::Class::File> object representing the text file containing the
license for a particular version of Apache ActiveMQ.

=head2 get_licence_filename ([ $version ])

Original spelling for get_license_filename() method.  Retained for backward compatibility.

=head1 BUGS AND LIMITATIONS

This is the first release of this code, and as such, it is very light on
features, and probably full of bugs.

Please see comments in the code for features planned and changes needed.

Patches (or forks on github) are, as always, welcome.

=head1 LINKS

=over

=item L<http://activemq.apache.org/> - Apache ActiveMQ project homepage.

=item L<Net::STOMP> - Interface to the Streamed Text Oriented Message Protocol in perl.

=item L<Catalyst::Engine::STOMP> - Use the power of Catalyst dispatch to route job requests.

=back

=head1 AUTHORS

    Tomas Doran (t0m) <bobtfish@bobtfish.net>
    Zac Stevens (zts) <zts@cryptocracy.com>
   Louis Erickson (loki) <laufeyjarson@laufeyjarson.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2009 by Tomas Doran.

This is free software; you can redistribute it and/or modify it under the same
terms as perl itself.

Note that the Apache MQ code which is installed by this software is licensed
under the Apache 2.0 license, which is included in the installed software.

=cut
