use Test::More tests => 24;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 24 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad;
App::Rad->run();

sub command {
    my $c = shift;

    my $ret = 'Called: ' . $c->cmd . ' (' . $c->command . ")\n";

    $c->execute('list_commands');
    $ret .= 'Called: ' . $c->cmd . ' (' . $c->command . ")\n";

    $c->register($c->create_command_name(), sub { return "test" });
    $c->register_command('alias', \&anothercommand, 'this is an alias');
    $c->unregister_command('yetanothercommand');
    $c->unregister('andanotherone');

    $c->execute('list_commands');
    $ret .= 'Called: ' . $c->cmd . ' (' . $c->command . ")\n";

    $c->execute('alias');
    $ret .= 'Called: ' . $c->cmd . ' (' . $c->command . ")\n";

    $c->execute('cmd1');
    $ret .= 'Called: ' . $c->cmd . ' (' . $c->command . ")\n";

    if ( $c->is_command('yetanothercommand') ) {
        $ret .= "error unregistering 'yetanothercommand'";
    }

    return $ret;
}

sub anothercommand { return "this is an alias, over" };

sub andanotherone { }

sub yetanothercommand { }

sub list_commands {
    my $c = shift;

    my $ret .= 'Available: ' . $c->commands . "\n";

    foreach ( sort $c->commands ) {
        $ret .= "$_:";
        $ret .= $c->is_command($_) ? 'ok' : 'not a command';
        $ret .= "\n";
    }
    return $ret;
}

EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename command`;
    my @ret = split m{$/}, $ret;
    is(scalar (@ret), 23);
    is($ret[0], 'Available: 6');
    is($ret[1], 'andanotherone:ok');
    is($ret[2], 'anothercommand:ok');
    is($ret[3], 'command:ok');
    is($ret[4], 'help:ok');
    is($ret[5], 'list_commands:ok');
    is($ret[6], 'yetanothercommand:ok');
    is($ret[7], '');
    is($ret[8], 'Available: 6');
    is($ret[9], 'alias:ok');
    is($ret[10], 'anothercommand:ok');
    is($ret[11], 'cmd1:ok');
    is($ret[12], 'command:ok');
    is($ret[13], 'help:ok');
    is($ret[14], 'list_commands:ok');
    is($ret[15], '');
    is($ret[16], 'this is an alias, over');
    is($ret[17], 'test');
    is($ret[18], 'Called: command (command)');
    is($ret[19], 'Called: list_commands (list_commands)');
    is($ret[20], 'Called: list_commands (list_commands)');
    is($ret[21], 'Called: alias (alias)');
    is($ret[22], 'Called: cmd1 (cmd1)');
}
