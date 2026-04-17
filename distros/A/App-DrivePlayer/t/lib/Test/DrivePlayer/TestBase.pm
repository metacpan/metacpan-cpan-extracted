package Test::DrivePlayer::TestBase;

# Base class for all DrivePlayer unit tests.
# Provides: temp directory, temp DB, Mock::MonkeyPatch helpers.

use strict;
use warnings;

use File::Temp  qw( tempdir tempfile );
use File::Path  qw( remove_tree );
use Log::Log4perl qw( :easy );
use Mock::MonkeyPatch;
use Module::Load qw( load );
use Test::Most;
use YAML::XS qw( DumpFile );

use parent 'Test::Class';

Log::Log4perl->easy_init($ERROR);   # suppress noise; set to $DEBUG to investigate

# ---- Lifecycle ----

sub setup : Tests(setup) {
    my ($self) = @_;
    $self->{_tempdir} = tempdir(CLEANUP => 1);
    $self->{_fakes}   = {};
    return;
}

sub teardown : Tests(teardown) {
    my ($self) = @_;
    $self->_unmock();
    return;
}

# ---- Temp helpers ----

sub _tempdir   { $_[0]->{_tempdir} }

sub _temp_path {
    my ($self, $name) = @_;
    return File::Spec->catfile($self->_tempdir, $name);
}

sub _temp_db_path {
    my ($self) = @_;
    return $self->_temp_path('test_music.db');
}

sub _write_yaml {
    my ($self, $filename, $data) = @_;
    my $path = $self->_temp_path($filename);
    DumpFile($path, $data);
    return $path;
}

# ---- Mocking helpers (same pattern as Test::Unit::TestBase) ----

sub _mock {
    my ($self, $group, $module, $method, $code) = @_;
    eval { load($module) };   # ignore errors for inline/already-loaded packages
    my $existing = $self->{_fakes}{$group}{$module}{$method};
    $existing->restore() if $existing;
    $self->{_fakes}{$group}{$module}{$method} =
        Mock::MonkeyPatch->patch("${module}::${method}" => $code);
    return;
}

sub _unmock {
    my ($self, $group) = @_;
    if ($group) {
        delete $self->{_fakes}{$group};
    } else {
        delete $self->{_fakes};
    }
    return;
}

1;
