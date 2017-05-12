use Test::More tests => 2;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 2 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<"EOT";
use App::Rad;
App::Rad->run();

sub default {
    return 'this is an override of the default command';
}

sub help {
    return 'this is an override of the help command';
}
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;

    is($ret, "this is an override of the default command\n");

    $ret = '';
    $ret = `$^X $filename help`;
    is($ret, "this is an override of the help command\n");
}
