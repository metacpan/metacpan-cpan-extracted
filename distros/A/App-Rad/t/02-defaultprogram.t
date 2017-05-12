use Test::More tests => 2;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 2 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<"EOT";
use App::Rad;
App::Rad->run();
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help\tshow syntax and available commands

EOHELP

    is($ret, $helptext);

    $ret = '';
    $ret = `$^X $filename help`;
    is($ret, $helptext);
}
