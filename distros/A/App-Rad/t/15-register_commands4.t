use Test::More tests => 7;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 7 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents= <<'EOT';
use App::Rad;
App::Rad->run();

sub setup {
    my $c = shift;
    $c->register_commands( qw/foo bar/,
                { -ignore_prefix => '_',
                  -ignore_suffix => 'bar'
                } );
}

sub foo { return 'hello'; }

sub _foo { return 'internal _foo!!!'; }

sub foocmd { return 'yo'; }

sub foo1bar { return 'internal foo1bar!!!'; }

sub bar { return 'hi'; }

sub default { return 'This is default. Over and out.'; }

EOT

    print $fh $contents;
    close $fh;

    my $ret = `$^X $filename`;

    is($ret, "This is default. Over and out.\n");

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    bar   \t
    foo   \t
    foocmd\t
    help  \tshow syntax and available commands

EOHELP


    $ret = `$^X $filename help`;
    is($ret, $helptext);

    $ret = `$^X $filename foo _foo foocmd foo1bar bar`;
    is($ret, "hello\n");

    $ret = `$^X $filename _foo foocmd foo1bar bar foo `;
    is($ret, "This is default. Over and out.\n");

    $ret = `$^X $filename foocmd foo1bar bar foo _foo`;
    is($ret, "yo\n");

    $ret = `$^X $filename foo1bar bar foo _foo foocmd`;
    is($ret, "This is default. Over and out.\n");

    $ret = `$^X $filename bar foo _foo foocmd foo1bar`;
    is($ret, "hi\n");

} 
