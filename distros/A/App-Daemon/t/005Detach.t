# launch app-daemon
use File::Temp qw(tempfile);
use FindBin qw($Bin);
use Sysadm::Install qw(:all);
use Test::More;
use App::Daemon;

use Log::Log4perl qw(:easy);
# Log::Log4perl->easy_init($DEBUG);

plan tests => 2;

my( $fh, $tmpfile ) = tempfile( UNLINK => 1 );

my ( $stdout, $stderr, $rc );

my @cmdline = ( $^X, "-I$Bin/../blib/lib", "$Bin/../eg/test-detach",
                $tmpfile);

( $stdout, $stderr, $rc ) = tap @cmdline;
is $rc, 0, "detached process started";

for( 1 .. 10 ) {
    my $data = slurp $tmpfile;
    if( $data =~ /Done/ ) {
        ok 1, "detached process finished";
        last;
    }
    sleep 1;
}
