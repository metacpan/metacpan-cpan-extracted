use Test::More;
use warnings;

sub runcmd {
    my ($cmd) = @_;
    system "$cmd >./t/stdout 2>./t/stderr";
    $EXITCODE = $? >> 8;
    if (open my $fh, "<", "./t/stdout") {
        $STDOUT = do {local $/; <$fh>};
        close $fh;
    }
    if (open my $fh, "<", "./t/stderr") {
        $STDERR = do {local $/; <$fh>};
        close $fh;
    }
    if ($ENV{DEBUG}) {
        print "STDOUT: $STDOUT\n";
        print "STDERR: $STDERR\n";
        print "EXITCODE: $EXITCODE\n";
    }
    END {system "rm ./t/stdout ./t/stderr"}
}

$ENV{PATH} = "./bin:$ENV{PATH}";

runcmd("elog -h");
ok $STDOUT =~ /Usage:/, "elog runs";

runcmd("alog -h");
ok $STDOUT =~ /Usage:/, "alog runs";

done_testing();

