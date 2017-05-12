use Test::More tests => 3;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 3 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad; 
App::Rad->run();

sub default {
    return 'this is an override of the default command';
}
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;

    is($ret, "this is an override of the default command\n");

    $ret = `$^X $filename unknown`;
    is($ret, "this is an override of the default command\n");

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help\tshow syntax and available commands

EOHELP

    $ret = '';
    $ret = `$^X $filename help`;
    is($ret, $helptext);
}
