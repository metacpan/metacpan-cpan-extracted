#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use Test::Exception;
use Test::More;
use Path::Class;
use File::Temp qw/tempdir/;
use File::Copy::Recursive qw/ dircopy /;

# This can be set to a true value to leave the temp files from the tests around for later
# examination.  They'll be in the t/run directory.
use constant LEAVE_TEMPFILES => 0;

BEGIN { require_ok "$FindBin::RealBin/../script/install-activemq"; }

{
    package TestInstall;
    use Moose;
    use MooseX::Types::Path::Class;
    use strict;
    use warnings;
    use base qw/Alien::ActiveMQ::Install/;
    use File::Temp qw/tempdir/;
    use Path::Class;
    use FindBin ();

    has _leave_tempfiles => (
        isa => 'Bool',
        is => 'ro',
        default => main::LEAVE_TEMPFILES(),
    );

    has _temp_dir => (
        isa => 'Path::Class::Dir',
        coerce => 1,
        is => 'ro',
        lazy_build => 1,
    );

    sub _build__temp_dir {
        my $self = shift;
        my $parent = dir($FindBin::RealBin, 'run');
        $parent->mkpath;
        return tempdir( "testinstall-XXXXXX", DIR => $parent,
            CLEANUP => !$self->_leave_tempfiles);
    }

    has _output_data => (
        isa => 'ArrayRef[Str]',
        is => 'rw',
        default => sub { [] },
    );

    sub _get {}
    sub _getstore {}
    sub _dircopy {}

    sub _build_install_dir {
        my $self = shift;
        return dir( $self->_temp_dir, $self->version_number );
    }

    sub output {
        my $self = shift;
        push @{$self->_output_data}, @_, "\n";
        return 1;
    }
}

our $_data_dir = dir($FindBin::RealBin, 'data');

# Test version number handling
{
    my $i = TestInstall->new;
    ok $i;
    ok !$i->has_version_number, 'No version number set';
    is $i->version_number, '5.10.0', 'Defaults to new version';
}
{
    my $i = new_ok('TestInstall', [ version_number => '9.2.1' ]);
    ok $i->has_version_number, 'Version number set';
    is $i->version_number, '9.2.1', 'Gets correct version';
}
throws_ok { TestInstall->new( version_number => {} ) } qr/version_number/,
    'throws when version not string';

# Test script name
{
    my $i = new_ok('TestInstall');
    is($i->script_name, 'script.t', 'Found script name');
}
# Test URI building
{
    my $i = new_ok('TestInstall');
    my $version = $i->version_number;
    is($i->download_uri, "http://www.apache.org/dyn/closer.cgi?path=/activemq/$version/apache-activemq-$version-bin.tar.gz", 'Download URI is good');
    is($i->archive_uri, "http://archive.apache.org/dist/activemq/apache-activemq/$version/apache-activemq-$version-bin.tar.gz", 'Archive URI is good');
}

# Test fetching URLs
{
    my $i = new_ok('TestInstall');
    my $version = $i->version_number;
    local *TestInstall::download_current = sub { my $self = shift; $self->{_got_curr} = 1; return $self->tarball };
    local *TestInstall::download_archive = sub { my $self = shift; $self->{_got_arch} = 1; die "Can't download archive" };
    my $tarball = $i->download_tarball;
    is($tarball, $i->tarball, 'Got correct current tarball path');
    is($i->{_got_curr}, 1, 'Called download_current');
    ok(!$i->{_got_arch}, 'No call to download_archive');
}

{
    my $i = new_ok('TestInstall');
    my $version = $i->version_number;
    local *TestInstall::download_current = sub { my $self = shift; $self->{_got_curr} = 1; die "Can't download current" };
    local *TestInstall::download_archive = sub { my $self = shift; $self->{_got_arch} = 1; return $self->tarball };
    my $tarball = $i->download_tarball;
    is($tarball, $i->tarball, 'Got correct archive tarball path');
    is($i->{_got_curr}, 1, 'Called download_current');
    is($i->{_got_arch}, 1, 'Called download_archive');
}

# Test downloading via mirror
{
    my $i = new_ok('TestInstall');
    no warnings 'redefine';
    local *TestInstall::_get = sub { return ''; };
    local *TestInstall::download_uri = sub { return 'nowhere'; };
    throws_ok { $i->download_current }
            qr /Failed to download mirror location nowhere/,
            'Fetch mirror failure noticed';
}
{
    my $i = new_ok('TestInstall');
    no warnings 'redefine';
    local *TestInstall::_get = sub { return '<HTML>Not a real web page.</HTML>'; };
    local *TestInstall::download_uri = sub { return 'nowhere'; };
    throws_ok { $i->download_current }
            qr /Failed to extract mirror from nowhere/,
            'Parse mirror path failure noticed';
}
{
    my $i = new_ok('TestInstall');
    no warnings 'redefine';
    local *TestInstall::download_uri = sub { return 'nowhere'; };
    local *TestInstall::_get = sub { return '<HTML>"http://apache/archive/stuff/amq-5.20-bin.tar.gz"</HTML>'; };
    local *TestInstall::_getstore = sub { return 500; };
    local *TestInstall::tarball = sub { return 'tarball' };
    throws_ok { $i->download_current }
            qr{Failed to download mirrored file http://apache/archive/stuff/amq-5.20-bin.tar.gz},
            'Parse mirror download failure noticed';
}
{
    my $i = new_ok('TestInstall');
    no warnings 'redefine';
    local *TestInstall::download_uri = sub { return 'nowhere'; };
    local *TestInstall::_get = sub { return '<HTML>"http://apache/archive/stuff/amq-5.20-bin.tar.gz"</HTML>'; };
    local *TestInstall::_getstore = sub { return 200; };
    local *TestInstall::tarball = sub { return 'tarball' };
    is($i->download_current, 'tarball', 'Current download works' );
}

# Test installing tarballs.
{
    no warnings 'redefine';
    local *TestInstall::_dircopy =  sub {
        my ($self, $from, $to) = @_;
        return dircopy($from, $to)
    };

    my $installdir = tempdir( "install-XXXXXX", DIR => dir ($FindBin::RealBin, 'run'),
        CLEANUP => !LEAVE_TEMPFILES());

    throws_ok { _install_test_version($installdir, '5.9.8'); }
        qr/^Can't read tarball/,
        'Noticed missing tarball';

    my $i = _install_test_version($installdir, '5.9.9');
    $i =  _install_test_version($installdir, '5.1.9');
}


sub _install_test_version {
    my $installdir = shift;
    my $version = shift;

    my $i = new_ok('TestInstall',
        [
            version_number => $version,
            tarball => file($_data_dir, "notamq-$version-bin.tar.gz"),
            install_dir => dir($installdir, $version),
        ]);
    ok($i->run, "Install version $version okay");
    ok(grep(/ActiveMQ installed in $installdir/, @{$i->_output_data}),
        'Found install text');
    ok(-r file($installdir, $version, 'bin', 'activemq'), 'Activemq binary installed');
    return $i;
}


done_testing;
