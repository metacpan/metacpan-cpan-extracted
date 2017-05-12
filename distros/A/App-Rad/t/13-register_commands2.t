use Test::More tests => 5;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 5 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents= <<'EOT';
use App::Rad;
App::Rad->run();

sub setup {
    my $c = shift;
    $c->register_commands({
        ignore_prefix => 'this is a command',
        ignore_regexp => 'this is another command',
        ignore_suffix => 'this too, since none of us start with a dash',
    });
}

sub ignore_prefix { return 1; }

sub ignore_suffix { return 2; }

sub ignore_regexp { return 3; }

sub internal { return "I should *not* be available"; }

EOT

    print $fh $contents;
    close $fh;

    my $ret = `$^X $filename`;

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help         \tshow syntax and available commands
    ignore_prefix\tthis is a command
    ignore_regexp\tthis is another command
    ignore_suffix\tthis too, since none of us start with a dash

EOHELP

    is($ret, $helptext);

    $ret = `$^X $filename internal`;
    is($ret, $helptext);

    $ret = `$^X $filename ignore_prefix`;
    is($ret, "1\n");

    $ret = `$^X $filename ignore_suffix`;
    is($ret, "2\n");

    $ret = `$^X $filename ignore_regexp`;
    is($ret, "3\n");

} 
