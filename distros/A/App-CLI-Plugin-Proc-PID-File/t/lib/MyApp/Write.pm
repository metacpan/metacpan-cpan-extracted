package MyApp::Write;

use strict;
use base qw(App::CLI::Command);
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

sub run {

    my($self, @args) = @_;
    $self->pf->touch;
    $main::PID_FILE     = $self->pf->path;
    $main::TEST_PIDFILE = File::Spec->catfile(File::Spec->tmpdir, "prove.pid.test");
    open my $fh, ">", $main::TEST_PIDFILE or die "can not open $main::TEST_PIDFILE";
    flock $fh, LOCK_EX;
    print $fh $self->pf->read . "\n";
    close $fh;
}

1;

