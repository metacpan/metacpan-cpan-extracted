package t::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

use Test::More;
use File::Temp qw/ tempfile /;
use File::Basename qw/ dirname /;
use File::Spec::Functions qw/ catdir updir /;
use DBI;
use POSIX;

our @EXPORT = qw/run_test exit_status_is/;

my $PACKAGE_ROOT_DIR = catdir(dirname(__FILE__), updir());

# thanks to http://cpansearch.perl.org/src/TOKUHIROM/Test-Pretty-0.24/t/Util.pm
sub run_test {
    my ($options) = @_;
    my $preparer = $options->{ preparer };
    my $tests    = $options->{ tests };
    my $includes = $options->{ includes };

    my ($tmp, $filename) = tempfile();
    close $tmp;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid) {
        waitpid($pid, 0);

        open my $fh, '<', $filename or die $!;
        my $out = do { local $/; <$fh> };
        close $fh;
        note 'x' x 80;
        note $out;
        note 'x' x 80;

        return $out;
    } else {
        # child
        open(STDOUT, ">", $filename) or die "Cannot redirect";
        open(STDERR, ">", $filename) or die "Cannot redirect";

        my @args = (
            '--norc',
            '-v',
            '-l',
            "-I$PACKAGE_ROOT_DIR",
            ($includes ? "-I$includes" : ()),
            ($preparer ? "-PMySQLPool=$preparer"
             : "-PMySQLPool"),
            '-j'.(scalar @$tests),
            @$tests,
        );

        ### Should *NOT* use App::Prove (or App::ForkProve) directry
        #
        # The current process has already loaded Test::More module.
        # Test::More has many side-effects in the implementations,
        # and it makes complex problem in the child process. (and Test2 also)
        # So it should separate the perl interpriter from the current process
        # to avoid the side-effects by Test::More and any other modules.
        my $runner = $options->{ runner } || 'prove';
        exec $runner, @args;
        die "faield to exec $runner: $!";
    }
}

sub exit_status_is {
    my ($expected) = @_;

    if ($^O eq 'MSWin32') {
        is($?, $expected);
    } else {
        ok(POSIX::WIFEXITED($?), 'exited');
        is(POSIX::WEXITSTATUS($?), $expected, 'expected status');
    }
}

sub prepare {
    my ($package, $mysqld) = @_;

    my $dbh = DBI->connect( $mysqld->dsn )
        or die $DBI::errstr;

    my $create_table = 'CREATE TABLE t1 (user_id INTEGER UNSIGNED NOT NULL)';
    $dbh->do( $create_table );

    my $insert = 'INSERT t1 VALUES (1)';
    $dbh->do( $insert );
}

1;
