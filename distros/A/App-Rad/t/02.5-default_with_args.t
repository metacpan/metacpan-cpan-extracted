use Test::More tests => 2;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 2 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad qw(include exclude);
App::Rad->run();
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    exclude\tcompletely erase command from your program
    help   \tshow syntax and available commands
    include\tinclude one-liner as a command

EOHELP

    is($ret, $helptext);

    $ret = '';
    $ret = `$^X $filename help`;
    is($ret, $helptext);
}
