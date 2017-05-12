use strict;
use warnings;

use POSIX        ();
use File::Temp   ();
use MIME::Base64 ();

sub exec_tar {
    my (@args) = @_;

    my @PATH     = qw(/usr/local/bin /usr/bin /bin);
    my @COMMANDS = qw(gtar tar bsdtar);

    foreach my $command (@COMMANDS) {
        foreach my $dir (@PATH) {
            my $file = "$dir/$command";

            if ( -x $file ) {
                exec( $file, @args ) or die("Unable to exec() $command: $!");
            }
        }
    }

    die( 'Could not locate tar binary in ' . join( ':', @PATH ) );
}

sub extract_to {
    my ($tmpdir) = @_;

    pipe my ( $out, $in ) or die("Unable to pipe(): $!");

    my $pid = fork();

    if ( !defined $pid ) {
        die("Unable to fork(): $!");
    }
    elsif ( $pid == 0 ) {
        close $in;

        POSIX::dup2( fileno($out), fileno(STDIN) ) or die("Unable to dup2(): $!");

        chdir $tmpdir or die("Unable to chdir() to $tmpdir: $!");

        exec_tar( 'mpzxf', '-' );
    }

    close $out;

    while ( my $len = read( DATA, my $buf, 4081 ) ) {
        my $decoded = MIME::Base64::decode_base64($buf);

        syswrite( $in, $decoded ) or die("Failed to syswrite(): $!");
    }

    close $in;

    waitpid( $pid, 0 );

    my $status = $? >> 8;

    return $status == 0;
}

sub run {
    my ( $tmpdir, @args ) = @_;
    my $main = "$tmpdir/scripts/main.pl";
    my $lib  = "$tmpdir/lib";

    my $pid = fork();

    if ( $pid == 0 ) {
        $ENV{'PERLLIB'} = $lib;
        $ENV{'PERLLIB'} .= ":$ENV{'PERLLIB'}" if defined $ENV{'PERLLIB'};

        exec( $^X, $main, @args ) or die("Unable to exec() $main: $!");
    }
    elsif ( !defined($pid) ) {
        die("Unable to fork(): $!");
    }

    waitpid( $pid, 0 );

    return $? >> 8;
}

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 ) or die("Cannot create temporary directory: $!");

extract_to($tmpdir) or die("Unable to extract to $tmpdir");

exit run( $tmpdir, @ARGV );

__DATA__
