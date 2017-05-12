use Test::More tests => 5;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir }";
    skip "File::Temp not installed", 5 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad; 
App::Rad->run();

sub default {
    my $c = shift;

    if ( $c->cmd ) {
        return 'oops';
    }
    else {
        return 'keys: ' . (keys %{ $c->options });
    }
}

sub invalid {
    my $c = shift;
    return 'sorry, but "' . $c->cmd . '" does not exist.';
}
EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename`;
    is($ret, "keys: 0\n", 'no command (should fall to default)');

    $ret = `$^X $filename --test`;
    is($ret, "keys: 1\n", 'no command, with parameters (should fall to default)');

    $ret = `$^X $filename test`;
    is($ret, "sorry, but \"test\" does not exist.\n", 'invalid command (should fall to invalid)');

    $ret = `$^X $filename test --something`;
    is($ret, "sorry, but \"test\" does not exist.\n", 'invalid command, with parameters (should fall to invalid)');



my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    help\tshow syntax and available commands

EOHELP

    $ret = '';
    $ret = `$^X $filename help`;
    is($ret, $helptext);
}
