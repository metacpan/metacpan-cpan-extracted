package t::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Data::Dumper;
use Test::Requires qw( Capture::Tiny File::pushd );

sub cli {
    my $etcd = shift;
    my $cli = Dancer2::Plugin::Etcd::CLI::Tested->new();
    $cli->dir( Path::Tiny->tempdir(CLEANUP => !$ENV{NO_CLEANUP}) );
    warn "Temp directory: ", $cli->dir, "\n" if $ENV{NO_CLEANUP};
    $cli;
}

package  Dancer2::Plugin::Etcd::CLI::Tested;
use Dancer2::Plugin::Etcd::CLI;
use Capture::Tiny qw(capture);
use File::pushd ();
use Path::Tiny;
use Moo;
use Data::Dumper;

$Dancer2::Plugin::Etcd::CLI::UseSystem = 1;

has dir => (is => 'rw');
has stdout => (is => 'rw');
has stderr => (is => 'rw');
has exit_code => (is => 'rw');

sub write_file {
    my($self, $file, @args) = @_;
    $self->dir->child($file)->spew(@args);
}

sub run_in_dir {
    my($self, $dir, @args) = @_;
    local $self->{dir} = $self->dir->child($dir);
    $self->run(@args);
}

sub run {
    my($self, @args) = @_;
    # print STDERR Dumper(@args);
    my $pushd = File::pushd::pushd $self->dir;
    my $code = Dancer2::Plugin::Etcd::CLI->new->run(@args);

    $self->stdout($code);
}

sub clean_local {
    my $self = shift;
    $self->dir->child("local")->remove_tree({ safe => 0 });
}

1;
