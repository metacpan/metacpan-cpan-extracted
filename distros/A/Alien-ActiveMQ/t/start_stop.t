#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin ();
use Path::Class qw/file dir/;
use File::Temp qw/tempdir/;
use Test::MockModule;

BEGIN {
    use_ok('Alien::ActiveMQ');
    require_ok "$FindBin::RealBin/../script/install-activemq";
}

# This can be set to a true value to leave the temp files from the tests around for later
# examination.  They'll be in the t/run directory.
use constant LEAVE_TEMPFILES => 0;

dir($FindBin::RealBin, 'run')->mkpath;
our $_dist_dir =  dir ( tempdir( "testamq-XXXXXX",
    DIR => dir($FindBin::RealBin, 'run'),
    CLEANUP => !LEAVE_TEMPFILES) );

our $_data_dir = dir($FindBin::RealBin, 'data');

package Alien::ActiveMQ::Mock;

    use Moose;
    use base qw/Alien::ActiveMQ/;
    use strict;
    use warnings;
    use File::Temp qw/tempdir/;
    use Path::Class;
    use FindBin ();

    sub _dist_dir {
        return $main::_dist_dir;
    }

    has _output_data => (
        isa => 'ArrayRef[Str]',
        is => 'rw',
        default => sub { [] },
    );

    sub _output {
        my $self = shift;
        push @{$self->_output_data}, join('', @_);
        return 1;
    }

    sub startup_timeout {
        return 3;
    }

package main;

ok (!Alien::ActiveMQ::Mock->is_version_installed(), 'No versions found');
is(Alien::ActiveMQ::Mock->get_version_dir(), undef, 'No version guessed');

ok (_install_test_version('5.1.9'), 'Installed 5.1.9');

ok (Alien::ActiveMQ::Mock->is_version_installed(), 'Found an installation');
is(Alien::ActiveMQ::Mock->get_version_dir(), $_dist_dir->subdir('5.1.9'),
    'Found latest installed version');
is(Alien::ActiveMQ::Mock->get_license_filename(),
    $_dist_dir->file('5.1.9', 'LICENSE'),
    'Found latest license file');
is(Alien::ActiveMQ::Mock->get_licence_filename(),
    $_dist_dir->file('5.1.9', 'LICENSE'),
    'Old licence_filename works');
is(Alien::ActiveMQ::Mock->get_version_dir('1.1.1'), $_dist_dir->subdir('1.1.1'),
    'Any version dir found');
is(Alien::ActiveMQ::Mock->get_license_filename('1.1.1'),
    $_dist_dir->file('1.1.1', 'LICENSE'),
    'Any version LICENSE file found');
ok(Alien::ActiveMQ::Mock->is_version_installed('5.1.9'), 'Found 5.1.9');
ok(!Alien::ActiveMQ::Mock->is_version_installed('1.1.1'), 'No 1.1.1 installed');
is_deeply( [ Alien::ActiveMQ::Mock->get_installed_versions() ], [ qw/5.1.9/ ],
    'Found version 5.1.9 installed'
);

ok (_install_test_version('5.9.9'), 'Installed 5.9.9');
ok (Alien::ActiveMQ::Mock->is_version_installed(), 'Found an installation');
is(Alien::ActiveMQ::Mock->get_version_dir(), $_dist_dir->subdir('5.9.9'),
    'Found latest installed version');
is(Alien::ActiveMQ::Mock->get_license_filename(),
    $_dist_dir->file('5.9.9', 'LICENSE'),
    'Found latest license file');
is(Alien::ActiveMQ::Mock->get_license_filename('5.9.9'),
    $_dist_dir->file('5.9.9', 'LICENSE'),
    'Found 5.9.9 license file');
is(Alien::ActiveMQ::Mock->get_license_filename('5.1.9'),
    $_dist_dir->file('5.1.9', 'LICENSE'),
    'Found 5.1.9 license file');
ok(Alien::ActiveMQ::Mock->is_version_installed('5.1.9'), 'Found 5.1.9');
ok(Alien::ActiveMQ::Mock->is_version_installed('5.9.9'), 'Found 5.9.9');
ok(!Alien::ActiveMQ::Mock->is_version_installed('1.1.1'), 'No 1.1.1 installed');
is_deeply( [ Alien::ActiveMQ::Mock->get_installed_versions() ],
    [ qw/ 5.9.9 5.1.9/ ],
    'Found two installed'
);

# Test that we ignore junk in the install location
mkdir $_dist_dir->subdir("random_stuff");
is_deeply( [ Alien::ActiveMQ::Mock->get_installed_versions() ],
    [ qw/ 5.9.9 5.1.9/ ],
    'Ignored extra subdir'
);

# Start a "version" which requires 'console' to stay in the foreground
{
    my $stomp = Test::MockModule->new( 'Net::Stomp' );
    my $try = 0;
    # This simulates a couple of retries while the server starts.
    # It also lets the process actually run.
    $stomp->mock(new => sub {
        $try++;
        if($try < 2) {
            die "Not ready.";
        }
        return 1;
    });

    my $amq = Alien::ActiveMQ::Mock->new;
    is($amq->get_version_dir(), $_dist_dir->subdir('5.9.9'),
        'Found latest version');
    {
        my $server = $amq->run_server;
        ok($server, 'Got a working amq')
    }
    is($amq->_output_data->[0],
        "Running " . $_dist_dir->file('5.9.9', 'bin', 'activemq') . ' console',
        'Found console start');
    is($amq->_output_data->[-1],
        'Killing ApacheMQ...',
        'Found amq shutdown');
}

# Start a "version" which needs no parameters to stay in the foreground
{
    my $stomp = Test::MockModule->new( 'Net::Stomp' );
    my $try = 0;
    # This simulates a couple of retries while the server starts.
    # It also lets the process actually run.
    $stomp->mock(new => sub {
        $try++;
        if($try < 2) {
            die "Not ready.";
        }
        return 1;
    });

    my $amq = Alien::ActiveMQ::Mock->new;
    is($amq->get_version_dir('5.1.9'), $_dist_dir->subdir('5.1.9'),
        'Found older version');
    {
        my $server = $amq->run_server('5.1.9');
        ok($server, 'Got a working amq')
    }
    is($amq->_output_data->[0],
        "Running " . $_dist_dir->file('5.1.9', 'bin', 'activemq'),
        'Found console start');
    is($amq->_output_data->[-1],
        'Killing ApacheMQ...',
        'Found amq shutdown');
}

# Verify we still start as a class method, too.
{
    my $stomp = Test::MockModule->new( 'Net::Stomp' );
    my $try = 0;
    # This simulates a couple of retries while the server starts.
    # It also lets the process actually run.
    $stomp->mock(new => sub {
        $try++;
        if($try < 2) {
            die "Not ready.";
        }
        return 1;
    });

    no warnings qw/ redefine /;
    local *Alien::ActiveMQ::_dist_dir = sub {
        return $main::_dist_dir;
    };
    my $_output_data = [];
    local *Alien::ActiveMQ::_output = sub {
        my $class = shift;
        push @{$_output_data}, @_;
    };

    my $amq = Alien::ActiveMQ->new;
    is(Alien::ActiveMQ->get_version_dir('5.1.9'), $_dist_dir->subdir('5.1.9'),
        'Class found older version');
    {
        my $server = Alien::ActiveMQ->run_server('5.1.9');
        ok($server, 'Got a working amq')
    }
    is($_output_data->[0],
        "Running " . $_dist_dir->file('5.1.9', 'bin', 'activemq'),
        'Found console start');
    is($_output_data->[-1],
        'Killing ApacheMQ...',
        'Found amq shutdown');
}


# Deal with a version that won't start - bad Java or otherwise
{
    my $stomp = Test::MockModule->new( 'Net::Stomp' );
    my $try = 0;
    # This simulates retries forever.
    $stomp->mock(new => sub {
        $try++;
        die "No connection";
    });

    my $amq = Alien::ActiveMQ::Mock->new;
    is($amq->get_version_dir('5.9.9'), $_dist_dir->subdir('5.9.9'),
        'Found newer version');
    {
        throws_ok { my $server = $amq->run_server('5.9.9'); }
            qr /Can't connect to ActiveMQ after trying 3 seconds./,
            'Server would not start';
    }
    use Data::Dumper;
    is($try, 4, 'Found retries');
}


# Install one of our test versions.
sub _install_test_version {
    my $version = shift;

    my $i = new_ok('Alien::ActiveMQ::Install',
        [
            version_number => $version,
            tarball => file($_data_dir, "notamq-$version-bin.tar.gz"),
            install_dir => dir($_dist_dir, $version),
        ]);
    ok($i->run, "Install version $version okay");
    ok(-r file($_dist_dir, $version, 'bin', 'activemq'), 'Activemq binary installed');
    return $i;
}

done_testing();
