#!perl

use Test::More tests => 7;
use IO::Handle;

BEGIN {
    use_ok( 'Dancer::Logger::Pipe' ) || print "Bail out!\n";
    use_ok( 'File::Temp' ) || print "Bailing out!\n";
}
diag( "Testing Dancer::Logger::Pipe $Dancer::Logger::Pipe::VERSION, Perl $], $^X" );

my $MESSAGE = 'The quick brown fox jumped over the lazy dog';
sub run_test {
    my $test = shift;
    my $info = shift;
    ok(run_test_on_pipe($info, 'core', $MESSAGE) == $info->{ok}, "Passed test $test");
}

sub run_test_on_pipe {
    my ( $test, $level, $message ) = @_;

    eval {
        local $SIG{__WARN__} = sub { diag(@_) };
        use Dancer::Config 'setting';
        setting ('pipe' => $test);
        my $logger = Dancer::Logger::Pipe->new;
        $logger->_log($level,$message);
    };
    if ($@) {
        my $err = $@;
        diag($err);
        return 0;
    }

    eval {
        if ($test->{after}) {
            diag("Running after test");
            $test->{after}->();
        }
    };
    if ($@) {
        my $err = $@;
        diag($err);
        return 0;
    }

    return 1;
}

my $fh = File::Temp->new;
my $filename = $fh->filename;
$fh->close;

my %tests = (
    empty => {
        ok => 0,
    },
    bad => {
        ok => 0,
        command => 'foobar',
    },
    no_args => {
        ok => 1,
        command => 'cat',
    },
    good => {
        ok => 1,
        command => "tee $filename",
        after => sub {
            open(my $fh, '<', $filename) || die "Unable to open file: $filename";
            while(<$fh>) {
                diag("data: $_");
                if( m/$MESSAGE/ ) {
                    pass("Found message in file: $filename");
                    return;
                }
            }
            fail("Did not find message in file: $filename");
        },
    }
);

foreach my $test ( keys %tests ) {
    run_test($test, $tests{$test});
}

