use Test::More tests => 1;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 1 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

#TODO: add precedence confirmation with $c->register_commands()
#and $c->register()
    my $contents= <<'EOT';
use App::Rad;
App::Rad->run();

sub foo :Help(help for foo) { return 'foo'; }

sub bar :Help(help for bar) { return 'bar'; }

sub baz
:Help(yet another help) { return 'baz'; }

sub singleword :Help(single) { return 'single word inside help' }

EOT

    print $fh $contents;
    close $fh;

my $helptext = <<"EOHELP";
Usage: $filename command [arguments]

Available Commands:
    bar       \thelp for bar
    baz       \tyet another help
    foo       \thelp for foo
    help      \tshow syntax and available commands
    singleword\tsingle

EOHELP

    $ret = `$^X $filename`;
    is($ret, $helptext);


} 
