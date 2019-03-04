use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Test::File::Contents;
use Test::More;

use App::NDTools::NDProc;

my $ndproc = App::NDTools::NDProc->new() or
    die "Failed to instantiate 'App::NDTools::NDProc'";

for my $name (sort keys %{$ndproc->{MODS}}) {
    $ndproc->{OPTS}->{module} = $name;
    ok(eval { $ndproc->init_module($name) }, "Init mod $name") or next;

    can_ok($ndproc->{MODS}->{$name}, qw(
        MODINFO
        VERSION
        arg_opts
        check_rule
        configure
        defaults
        get_opts
        load_struct
        usage
        parse_args
        process
        restore_preserved
        stash_preserved
        usage
    ));

    my ($out, $err);
    ($out, $err) = capture { eval {
        my $mod = $ndproc->{MODS}->{$name}->new();
        $mod->parse_args(['--help']);
    }};
    is($out, '', "$name: Usage goes to STDERR (STDOUT must remain empty)");
    like($err, qr/^Name:/, "$name: Usage must starts with 'Name' field");
    like($err, qr/^Options:/m, "$name: Usage must contain 'Options' field");

    ($out, $err) = capture { eval {
        my $mod = $ndproc->{MODS}->{$name}->new();
        $mod->parse_args(['--version']);
    }};
    like($out, qr/\d+\.\d+.*/, "$name: version must be a number");
    is($err, '', "$name: STDOUT must remain empty for --version");

    # each module should have this options
    my $opts = { $ndproc->{MODS}->{$name}->new()->arg_opts() };
    for (qw(
        blame!
        cond=s@
        help|h
        path=s@
        preserve=s@
        version|V
    )) {
        next if ($_ eq 'path=s@' and $name eq 'Merge'); # has it's own format
        ok(exists $opts->{$_}, "Common opt '$_' missing in module $name");
    }
}

done_testing(keys(%{$ndproc->{MODS}}) * 13 - 1);
