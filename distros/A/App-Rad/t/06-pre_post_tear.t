use Test::More tests => 3;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 3 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad;
App::Rad->run();

sub test1 {
    my $c = shift;
    if ($c->argv->[0]) {
        return 'got ' . $c->argv->[0];
    }
    else {
        return 'my test #1';
    }
}

sub pre_process {
    my $c = shift;

    if ($c->argv->[0] eq 'tested') {
        $c->argv->[0] .= ' again';
    }
}

sub teardown {
    print 'tearing down...';
}

sub post_process {
    my $c = shift;
    print $c->output() . ' [NARF!]' . $/;
}
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;


my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help \tshow syntax and available commands
    test1\t
 [NARF!]
EOHELP

$helptext .= 'tearing down...';

    is($ret, $helptext);

    $ret = '';
    $ret = `$^X $filename test1`;
    is($ret, "my test #1 [NARF!]\ntearing down...");

    $ret = '';
    $ret = `$^X $filename test1 tested`;
    is($ret, "got tested again [NARF!]\ntearing down...");
}
