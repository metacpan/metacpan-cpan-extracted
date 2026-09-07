#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Cwd ();
use File::Temp qw(tempdir);
use File::Path qw(mkpath);

use lib "$FindBin::Bin/../lib";

my $LIB = "$FindBin::Bin/../lib";
my $CLI = "$FindBin::Bin/../bin/slimpack";

# Run the CLI exactly as invoked — no subcommand is forced here, so these
# tests exercise dispatch (default 'pack', explicit subcommands, --help).
my $TD;
sub run {
    my @args = @_;
    our $TD_HOLDER;
    my $cover = '';
    if ($ENV{COVER_DB}) {
        my $sel = join ',', '-silent,+select,App/SlimPacker', '+select,bin/slimpack';
        $cover = qq{-MDevel::Cover=-db,$ENV{COVER_DB},$sel };
    }
    my $cmd = join ' ', (qq{'$^X'} . " -I'$LIB' $cover") . ("'$CLI'"), map { "'$_'" } @args;
    my $out = `$cmd 2>&1`;
    $out =~ s/^Devel::Cover:.*\n//mg;
    my $rc  = $? >> 8;
    return ($out, $rc);
}

sub write_fixture {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

my ($td, $out, $rc);
{
    $td = tempdir(CLEANUP => 1);
    mkpath("$td/lib/App");
    mkpath("$td/bin");
    mkpath("$td/fatlib");
    write_fixture("$td/lib/App/MyMod.pm", "package App::MyMod;\nsub greet { 'hi' }\n1;\n");
    write_fixture("$td/bin/myapp", "use lib 'lib';\nuse App::MyMod;\nprint App::MyMod::greet(), \"\\n\";\n");

    # -- help
    ($out, $rc) = run('--help');
    is $rc, 0, '--help exits 0';
    like $out, qr/Usage: slimpack/, '--help shows usage';
    like $out, qr/Commands:/,       '--help lists the subcommands';

    # -- default command is pack (full fatpack pipeline)
    ($out, $rc) = run('-o', "$td/packed", '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'default (pack) build exits 0';
    ok -f "$td/packed", 'pack output file created';
    is `"$td/packed"`, "hi\n", 'packed script runs standalone';

    # -- explicit pack
    ($out, $rc) = run('pack', '-o', "$td/packed2", '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'explicit pack subcommand exits 0';
    is `"$td/packed2"`, "hi\n", 'explicit pack script runs standalone';

    # -- bundle subcommand
    ($out, $rc) = run('bundle', '-o', "$td/bundled", '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'bundle subcommand exits 0';
    is `"$td/bundled"`, "hi\n", 'bundle script runs standalone';

    # -- trace subcommand (module list to stderr)
    ($out, $rc) = run('trace', '--to-stderr', "$td/bin/myapp");
    is $rc, 0, 'trace subcommand exits 0';
    like $out, qr/App\/MyMod\.pm/, 'trace lists the bundled module';

    # -- packlists-for subcommand
    #    FatPacker's packlists_containing requires each target module, then maps
    #    the loaded file's @INC path back to the .packlist(s) that list it. Use
    #    fixture modules we control so nothing depends on how a tester's perl is
    #    laid out (a core module like Carp can carry a site_perl .packlist).
    my $fixture = Cwd::abs_path("$td/inc");
    mkpath("$fixture/Fake");
    mkpath("$fixture/auto/Fake/Mod");
    write_fixture("$fixture/Fake/Mod.pm", "package Fake::Mod;\nsub ok { 1 }\n1;\n");
    write_fixture("$fixture/auto/Fake/Mod/.packlist", "$fixture/Fake/Mod.pm\n");
    write_fixture("$fixture/Fake/None.pm", "package Fake::None;\n1;\n");
    {
        local $ENV{PERL5LIB} = join(':', $fixture, ($ENV{PERL5LIB} // ()));
        ($out, $rc) = run('packlists-for', 'Fake::Mod');
        is $rc, 0, 'packlists-for exits 0 (bare module name)';
        unlike $out, qr/Failed to load/, 'bare module name normalised, no load failure';
        like $out, qr{auto/Fake/Mod/\.packlist\s*$}, 'prints the packlist for a module that has one';
        ($out, $rc) = run('packlists-for', 'Fake/Mod.pm');
        is $rc, 0, 'packlists-for exits 0 (path form)';
        like $out, qr{auto/Fake/Mod/\.packlist\s*$}, 'path form finds the same packlist';
        ($out, $rc) = run('packlists-for', 'Fake::None');
        is $rc, 0, 'packlists-for exits 0 for a module without a packlist';
        is $out, '', 'packlists-for prints nothing when no packlist exists';
    }

    # -- tree subcommand (no packlists → empty fatlib, still 0)
    ($out, $rc) = run('tree');
    is $rc, 0, 'tree exits 0';

    # -- unknown word is not a subcommand → treated as the boot script, pack fails
    ($out, $rc) = run('frobnicate');
    isnt $rc, 0, 'unknown word treated as script → exits nonzero';
    like $out, qr/Cannot read/, 'pack reports unreadable script';

    # -- no args: default pack with no script fails
    #    (error text comes from App::FatPacker internals, so match loosely)
    ($out, $rc) = run();
    isnt $rc, 0, 'no args exits nonzero';
    like $out, qr/uninitialized|missing|script/i, 'no args reports a missing script';
}

done_testing;