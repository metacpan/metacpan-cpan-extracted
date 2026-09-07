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

sub file_content {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    my $c = <$fh>;
    close $fh;
    return $c;
}

my ($td, $td2);
sub run_cli {
    my @args = @_;
    # bundle.t exercises the bundler directly; use the explicit 'bundle' step
    # (the default 'pack' subcommand runs the full fatpack pipeline instead).
    my $sub = (@args && $args[0] eq 'bundle') ? shift @args : 'bundle';
    unshift @args, ('--lib', "$td/lib")    unless grep { $_ eq '--lib' } @args;
    unshift @args, ('--fatlib', "$td/fatlib") unless grep { $_ eq '--fatlib' } @args;
    unshift @args, $sub;
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

{
    $td  = tempdir(CLEANUP => 1);
    $td2 = tempdir(CLEANUP => 1);
    mkpath("$td/lib/App/Lab/Adapter/Sub");
    mkpath("$td/bin");
    mkpath("$td/fatlib");

    write_fixture("$td/lib/App/MyMod.pm", <<'MOD');
package App::MyMod;
use strict; use warnings;
# keep me
sub greet {
    my $who = shift;
    return "hi " . $who;
}
1;
MOD
    write_fixture("$td/bin/myapp", <<'BOOT');
#!/usr/bin/perl
use lib 'lib';
use App::MyMod;
# boot comment
print App::MyMod::greet('cli'), "\n";
BOOT

    mkpath("$td/lib/App/Lab/Adapter");
    write_fixture("$td/lib/App/Lab/Adapter/A.pm", "package App::Lab::Adapter::A;\n1;\n");
    write_fixture("$td/lib/App/Lab/Adapter/B.pm", "package App::Lab::Adapter::B;\n1;\n");
    write_fixture("$td/lib/App/Lab/Adapter/Sub/C.pm", "package App::Lab::Adapter::Sub::C;\n1;\n");
    write_fixture("$td/bin/lab", <<'LAB');
use Module::Pluggable (
    search_path => 'App::Lab::Adapter',
);
use strict; use warnings;
print join(',', sort plugins()), "\n";
LAB

write_fixture("$td/fatlib/Std.pm", <<'FAT');
package Std;
# fatlib comment kept by convention
use strict;
my $fat_long_name = 1;
sub fat { return $fat_long_name + 1 }
1;
FAT
    # pack_string stress fixtures: one module whose minified source contains a
    # quote and a q{...}-with-backslash, both still load and run byte-identically
    # through deflate+base64 round-trip.  
    write_fixture("$td/lib/App/QuOt.pm", "package App::QuOt;\nsub once { return \"he said 'hi'\" }\n1;\n");
    write_fixture("$td/lib/App/Back.pm", "package App::Back;\nsub twice { return \"a\\\\b\" }\n1;\n");
    write_fixture("$td/bin/quback", <<'QBOOT');
#!/usr/bin/perl
use lib 'lib';
use App::QuOt;
use App::Back;
print App::QuOt::once(), "\n";
print App::Back::twice(), "\n";
QBOOT
    my ($out, $rc, $c);

    # -- plain bundle (compression is ON by default)
    ($out, $rc) = run_cli('-o', "$td/myapp_bundled", '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'build script exits 0';
    ok -f "$td/myapp_bundled", 'output file created';
    ok -x "$td/myapp_bundled", 'output file is executable';
    $c = file_content("$td/myapp_bundled");
    like $c, qr/^#!\/usr\/bin\/perl\n/, 'shebang first line';
    like $c, qr/SlimPacked::/, 'lazy @INC hook emitted';
    like $c, qr/"App\/MyMod\.pm" =>/, 'bundled module source held in hook map';
    unlike $c, qr/\$INC\{'App\/MyMod\.pm'\}=1;/, 'no eager %INC prefill';
    unlike $c, qr/# keep me/, 'module comments minified (default)';
    unlike $c, qr/# boot comment/, 'program comments minified (default)';
    unlike $c, qr/\$who/, 'short variable renamed (strings with it would block, fixture avoids that)';
    unlike $c, qr/use lib/, 'use lib stripped from program';
    like $c, qr/BEGIN\{my%sl=\(/, 'compact loader: single BEGIN{my%sl=(...) block';
    like $c, qr/bless\\%sl,\$class;/, 'compact loader: bless+unshift {$class} fragment';
    unlike $c, qr/__SLPACK_ENTRIES__/, 'loader placeholder spliced away';
    like $c, qr/use Compress::Raw::Zlib \(\);/, 'compressed loader: core zlib loaded';
    like $c, qr/use MIME::Base64 qw\(decode_base64\);/, 'compressed loader: core base64 loaded';
    my ($table) = $c =~ /BEGIN\{my%sl=\((.*?)\);my\$class=/s
        or die "cannot locate module table in bundle";
    unlike $table, qr/\\\$/, 'module table has no escaped sigils (all single-quoted)';
    like $table, qr/"App\/MyMod\.pm" => '[A-Za-z0-9+\/=]+'/, 'module source deflate+base64 in table (default)';
    unlike $table, qr/package App::MyMod;/, 'compressed source not embedded verbatim';
    like $table, qr/"__MAIN__" => '[A-Za-z0-9+\/=]+'/, 'boot program deflate+base64 in table (default)';
    unlike $c, qr/print App::MyMod::greet\('cli'\),/, 'boot program text not embedded verbatim (compressed)';
    is `"$td/myapp_bundled"`, "hi cli\n", 'bundled script runs standalone';
    {
        local $ENV{PERL5LIB};
        is `"$td/myapp_bundled"`, "hi cli\n", 'compressed bundle runs with @INC pruned';
    }

    # -- no-compress: identical behavior from visible, readable source literals
    ($out, $rc) = run_cli('-o', "$td/myapp_plain", '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--no-compress build exits 0';
    $c = file_content("$td/myapp_plain");
    unlike $c, qr/use Compress::Raw::Zlib/, '--no-compress omits zlib loader';
    my ($table3) = $c =~ /BEGIN\{my%sl=\((.*?)\);my\$class=/s
        or die "cannot locate module table in plain bundle";
    like $table3, qr/"App\/MyMod\.pm" => 'package App::MyMod;/, 'plain: module code embedded as single-quoted literal (pack_string)';
    is `"$td/myapp_plain"`, "hi cli\n", 'plain bundle runs standalone';
    is `"$td/myapp_plain"`, `"$td/myapp_bundled"`, 'compressed and plain bundles behave identically';

    # -- explicit --compress flag (default, but the switch must work)
    ($out, $rc) = run_cli('-o', "$td/myapp_comp", '--compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--compress flag build exits 0';
    like file_content("$td/myapp_comp"), qr/use Compress::Raw::Zlib \(\);/, '--compress embeds compressed loader';
    is `"$td/myapp_comp"`, "hi cli\n", '--compress bundle runs';

    # -- a boot program with __DATA__/__END__ cannot be string-eval'd, so it is
    #    left uncompressed (with a warning) while modules stay compressed
    write_fixture("$td/bin/dataapp", <<'DL');
#!/usr/bin/perl
use lib 'lib';
use App::MyMod;
print App::MyMod::greet('d'), "\n" . <DATA>;
__DATA__
data line
DL
    ($out, $rc) = run_cli('-o', "$td/dataapp_bundled", '--lib', "$td/lib", "$td/bin/dataapp");
    is $rc, 0, 'data-section boot build exits 0';
    like $out, qr/leaving the boot program uncompressed/, 'warns that boot program left uncompressed';
    my $dc = file_content("$td/dataapp_bundled");
    like $dc, qr/^__DATA__$/m, 'compressed build keeps __DATA__ at a line start';
    like $dc, qr/print App::MyMod::greet\('d'\),"\\n"\.<DATA>;\n__DATA__\n/, 'boot program embedded verbatim despite --compress';
    my ($dt) = $dc =~ /BEGIN\{my%sl=\((.*?)\);my\$class=/s
        or die "cannot locate module table in data bundle";
    like $dt, qr/"App\/MyMod\.pm" => '[A-Za-z0-9+\/=]+'/, 'modules still compressed when boot program is not';
    unlike $dt, qr/__MAIN__/, 'no __MAIN__ entry when boot program left raw';
    is `"$td/dataapp_bundled"`, "hi d\ndata line\n", 'data-section bundle runs (module + <DATA>)';
    is `"$td/dataapp_bundled"`, `perl -I"$td/lib" "$td/bin/dataapp"`, 'data-section bundle matches running the raw script';

    # -- pack_string endings under a real bundle: quote-rich module must land
    #    in a q<delim> literal, backslash module in an escaped single-quote,
    #    and both must still run against the embedded copies.
    ($out, $rc) = run_cli('-o', "$td/quback_plain", '--no-compress', '--lib', "$td/lib", "$td/bin/quback");
    is $rc, 0, 'quback --no-compress build exits 0';
    $c = file_content("$td/quback_plain");
    like $c, qr/"App\/QuOt\.pm" => q\^/, 'quote-rich module embedded via q<delim> literal';
    like $c, qr/"App\/Back\.pm" => '/, 'backslash module embedded as escaped single-quote (no perlstring)';
    my ($table2) = $c =~ /BEGIN\{my%sl=\((.*?)\);my\$class=/s
        or die "cannot locate module table in quback bundle";
    unlike $table2, qr/\\\$/ , 'quback table has no perlstring sigil escapes';
    is `"$td/quback_plain"`, "he said 'hi'\na\\b\n", 'q-delim and fallback modules run standalone';
    {
        local $ENV{PERL5LIB};
        is `"$td/quback_plain"`, "he said 'hi'\na\\b\n", 'plain stress bundle runs with @INC pruned';
    }

    # -- compressed equivalents of the same fixtures, incl. binary-clean
    #    round-trip of the backslash module through deflate/inflate
    ($out, $rc) = run_cli('-o', "$td/quback_bundled", '--lib', "$td/lib", "$td/bin/quback");
    is $rc, 0, 'quback build exits 0';
    $c = file_content("$td/quback_bundled");
    my ($tableq) = $c =~ /BEGIN\{my%sl=\((.*?)\);my\$class=/s
        or die "cannot locate module table in quback bundle";
    like $tableq, qr/"App\/QuOt\.pm" => '[A-Za-z0-9+\/=]+'/, 'quote-rich module deflate+base64 compressed';
    is `"$td/quback_bundled"`, "he said 'hi'\na\\b\n", 'compressed backslash/quotes round-trip byte-identically';
    is `"$td/quback_bundled"`, `"$td/quback_plain"`, 'compressed and plain quback behave identically';

    # -- unpacklisted (no .packlist) module pulled from @INC via $INC fallback
    #    A module installed into a dir on @INC with no .packlist (Debian /
    #    hand-installed) must still be bundled by the `bundle` subcommand.
    my $xp = "$td/extrainc";
    mkpath("$xp/App/Extra");
    write_fixture("$xp/App/Extra/NoPacklist.pm", "package App::Extra::NoPacklist;\nsub msg { 'extra' }\n1;\n");
    write_fixture("$td/bin/eed", "use App::Extra::NoPacklist;\nprint App::Extra::NoPacklist->msg, \"\\n\";\n");
    {
        my $old_p5l = $ENV{PERL5LIB};
        local $ENV{PERL5LIB} = join(':', $xp, ($old_p5l // ()));
        ($out, $rc) = run_cli('--lib', "$td/lib", '--fatlib', "$td/fatlib", '-o', "$td/eed_bundled", "$td/bin/eed");
        is $rc, 0, 'unpacklisted-module build exits 0';
        $c = file_content("$td/eed_bundled");
        like $c, qr/"App\/Extra\/NoPacklist\.pm" =>/, 'no-packlist module bundled from @INC';
        is `"$td/eed_bundled"`, "extra\n", 'unpacklisted-module bundle runs standalone';
        {
            local $ENV{PERL5LIB};
            is `"$td/eed_bundled"`, "extra\n", 'unpacklisted-module bundle runs with @INC pruned';
        }
    }

    # -- core modules are never bundled, even when a bundled dep uses them
    #    A lib module that `use Carp` (core) must not drag Carp into the bundle.
    my $coredir = "$td/lib/App/CoreDep";
    mkpath($coredir);
    write_fixture("$td/lib/App/CoreDep.pm", "package App::CoreDep;\nuse Carp;\nsub boom { croak 'x' }\n1;\n");
    write_fixture("$td/bin/coredep", "use App::CoreDep;\nprint \"ok\\n\";\n");
    ($out, $rc) = run_cli('--lib', "$td/lib", '--fatlib', "$td/fatlib", '-o', "$td/cd_bundled", "$td/bin/coredep");
    is $rc, 0, 'core-dep build exits 0';
    $c = file_content("$td/cd_bundled");
    like $c, qr/"App\/CoreDep\.pm" =>/, 'non-core dep module bundled';
    unlike $c, qr/"Carp\.pm" =>/, 'core module (Carp) NOT bundled';
    unlike $c, qr/"Config\.pm" =>/, 'core module (Config) NOT bundled';
    is `"$td/cd_bundled"`, "ok\n", 'core-dep bundle runs standalone';

    # -- deeply-nested unpacklisted module: exercises _mod_to_path and is_core
    #    A two-level deep non-core module chain with no .packlist, requiring
    #    _mod_to_path to correctly normalise Foo::Bar::Baz → Foo/Bar/Baz.pm,
    #    and Module::CoreList::is_core to be loadable in the standalone bundle path.
    my $deep = "$td/deepinc/Deep/Pkg/Sub";
    mkpath($deep);
    write_fixture("$td/deepinc/Deep/Pkg.pm", "package Deep::Pkg;\nsub greeting { 'deep' }\n1;\n");
    write_fixture("$td/deepinc/Deep/Pkg/Sub.pm", "package Deep::Pkg::Sub;\nsub nested { 'nested' }\n1;\n");
    write_fixture("$td/bin/deepboot", "use Deep::Pkg;\nuse Deep::Pkg::Sub;\nprint Deep::Pkg::greeting() . q{ } . Deep::Pkg::Sub::nested() . qq{\\n};\n");
    my $old_p5l3 = $ENV{PERL5LIB};
    local $ENV{PERL5LIB} = join(':', "$td/deepinc", ($old_p5l3 // ()));
    ($out, $rc) = run_cli('--lib', "$td/lib", '--fatlib', "$td/fatlib", '-o', "$td/deep_bundled", "$td/bin/deepboot");
    is $rc, 0, 'deep-nested build exits 0';
    diag $out if $rc;
    $c = file_content("$td/deep_bundled");
    like $c, qr/"Deep\/Pkg\.pm" =>/, 'deep module bundled (path normalised)';
    like $c, qr/"Deep\/Pkg\/Sub\.pm" =>/, 'deep submodule bundled (path normalised)';
    {
        local $ENV{PERL5LIB};
        is `"$td/deep_bundled"`, "deep nested\n", 'deep-nested bundle runs standalone';
    }

    # -- output to stdout
    ($out, $rc) = run_cli('-o', '-', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'stdout build exits 0';
    like $out, qr/^#!\/usr\/bin\/perl\n/, 'stdout build has shebang';

    # -- default output a.out in cwd
    my $prev = Cwd::getcwd;
    chdir $td or die "chdir $td: $!";
    ($out, $rc) = run_cli('--lib', "$td/lib", "$td/bin/myapp");
    chdir $prev or die "chdir $prev: $!";
    is $rc, 0, 'default-output build exits 0';
    ok -f "$td/a.out", 'defaults to ./a.out';
    unlink "$td/a.out";

    # -- no-minify
    ($out, $rc) = run_cli('-o', "$td/nm", '--no-minify', '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--no-minify build exits 0';
    $c = file_content("$td/nm");
    like $c, qr/# keep me/, '--no-minify keeps module comments';
    like $c, qr/# boot comment/, '--no-minify keeps program comments';
    like $c, qr/\$who/, '--no-minify keeps variable names';

    # -- no-rename: minify (drop comments) but leave variable names untouched
    ($out, $rc) = run_cli('-o', "$td/nr", '--no-rename', '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--no-rename build exits 0';
    $c = file_content("$td/nr");
    unlike $c, qr/# keep me/, '--no-rename minifies module comments';
    like $c, qr/\$who/, '--no-rename keeps variable names';
    is `"$td/nr"`, "hi cli\n", '--no-rename bundle runs standalone';

    # -- plugin inlining (default on)
    ($out, $rc) = run_cli('-o', "$td/lab_bundled", '--no-compress', '--lib', "$td/lib", "$td/bin/lab");
    is $rc, 0, 'inline-plugins build exits 0';
$c = file_content("$td/lab_bundled");
like $c, qr/"App::Lab::Adapter::A","App::Lab::Adapter::B"/, 'plugin classes inlined, sorted, one level';
my ($pluglist) = $c =~ /\bsort\s*\(\s*((?:"[^"]+")(?:\s*,\s*"[^"]+")*)\)/;
is $pluglist, '"App::Lab::Adapter::A","App::Lab::Adapter::B"', 'exactly the one-level plugins inlined';
unlike $c, qr/\Quse Module::Pluggable\E/, 'Module::Pluggable removed from bundle';
is `"$td/lab_bundled"`, "App::Lab::Adapter::A,App::Lab::Adapter::B\n", 'inlined script runs without Module::Pluggable';

    # -- no-inline-plugins
    ($out, $rc) = run_cli('-o', "$td/nip", '--no-inline-plugins', '--no-compress', '--lib', "$td/lib", "$td/bin/lab");
    is $rc, 0, '--no-inline-plugins build exits 0';
    $c = file_content("$td/nip");
    like $c, qr/Module::Pluggable/, '--no-inline-plugins keeps Module::Pluggable';
    like $c, qr/plugins\(\)/, '--no-inline-plugins keeps plugins() call';

    # -- fatlib bundled verbatim; lib minified
    ($out, $rc) = run_cli('-o', "$td/mix", '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, 'build with fatlib exits 0';
    $c = file_content("$td/mix");
    like $c, qr/package Std;/, 'fatlib module bundled';
    unlike $c, qr/# fatlib comment/, 'fatlib comment stripped (still minified)';
    like $c, qr/\$fat_long_name/, 'fatlib variables NOT renamed';
    unlike $c, qr/package App::MyMod;.*?\$who/s, 'lib module minified (var renamed)';

    # -- -e overrides positional script
    ($out, $rc) = run_cli('-o', "$td/ovr", '-e', 'print qq(override )', "$td/bin/myapp");
    is $rc, 0, '-e override build exits 0';
    like $out, qr/ignoring script/, '-e warns about ignored script';
    is `"$td/ovr"`, 'override ', '-e snippet wins over script';

    # -- -M module prepended to script
    ($out, $rc) = run_cli('-o', "$td/strict", '-M', 'strict', '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '-M build exits 0';
    is `"$td/strict"`, "hi cli\n", '-M script runs';
    like file_content("$td/strict"), qr/use strict;\s*use App::MyMod;\s*print App::MyMod::greet\('cli'\),\s*/, '-M line prepended before boot script';

    # -- -M list + -e program
    ($out, $rc) = run_cli('-o', "$td/ul", '--no-compress', '-M', 'List::Util=sum', '-e', 'print sum(1..100)');
    is $rc, 0, '-M/-e program builds';
my $ulc = file_content("$td/ul");
like $ulc, qr/use List::Util qw\(sum\);\s*print sum\(1\.\.100\)/, '-M/-e both honored';
is `"$td/ul"`, '5050', '-M List::Util=sum -e program runs';

    # -- -E enables features
    ($out, $rc) = run_cli('-o', "$td/sayb", '--no-compress', '-E', 'say "bye";');
    is $rc, 0, '-E program builds';
    like file_content("$td/sayb"), qr/use feature qw\(:all\);\s*say "bye";/, '-E prepends feature pragma';
    is `"$td/sayb"`, "bye\n", '-E program runs';

    # -- multiple -m
    ($out, $rc) = run_cli('-o', "$td/multi_m", '--no-compress', '-m', 'Carp', '-m', 'strict', '-e', 'print qq(ok)');
    is $rc, 0, 'multiple -m builds';
    my $mc = file_content("$td/multi_m");
    like $mc, qr/use Carp\(\);\s*use strict\(\);\s*print qq\(ok\)/, 'first -m as use X (); followed by second -m';
    is `"$td/multi_m"`, 'ok', 'multiple -m program runs';

    # -- bad option → Getopt fails, exit 2
    ($out, $rc) = run_cli('--bogus-flag', '-o', "$td/x", '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 2, 'unknown option exits 2';
    like $out, qr/Unknown option/, 'unknown option reported';

    # -- missing program
    ($out, $rc) = run_cli();
    isnt $rc, 0, 'no script exits nonzero';
    like $out, qr/missing boot script/, 'dies with usage';

    # -- nonexistent script file
    ($out, $rc) = run_cli('-o', "$td/x", '--lib', "$td/lib", "$td/nope.pl");
    isnt $rc, 0, 'missing script file exits nonzero';
    like $out, qr/Cannot read boot script/, 'reports unreadable boot script';

    # -- unwritable output path
    ($out, $rc) = run_cli('-o', "$td/nodir/out", '--lib', "$td/lib", "$td/bin/myapp");
    isnt $rc, 0, 'unwritable output exits nonzero';
    like $out, qr/Cannot write/, 'reports unwritable output';

    # -- unreadable module file under lib (reachable dependency)
    {
        mkpath("$td2/lib/App");
        write_fixture("$td2/lib/App/MyMod.pm", "package App::MyMod;\nuse App::Locked;\n1;\n");
        my $unread = "$td2/lib/App/Locked.pm";
        write_fixture($unread, "package App::Locked;\n1;\n");
        chmod 0000, $unread;
        ($out, $rc) = run_cli('-o', "$td2/x", '--lib', "$td2/lib", '--fatlib', "$td/fatlib", "$td/bin/myapp");
        chmod 0644, $unread;
        isnt $rc, 0, 'unreadable reachable module exits nonzero';
        like $out, qr/Cannot read/, 'reports unreadable reachable module';
    }

    # -- default: only reachable lib modules bundled, unused omitted
    {
        my $td3 = tempdir(CLEANUP => 1);
        mkpath("$td3/lib/App/Reachable");
        write_fixture("$td3/lib/App/Reachable.pm",     "package App::Reachable; sub x { 1 }\n1;\n");
        write_fixture("$td3/lib/App/Reachable/Sub.pm", "use App::Reachable;\npackage App::Reachable::Sub;\n1;\n");
        write_fixture("$td3/lib/App/Unused.pm",        "package App::Unused; sub y { 99 }\n1;\n");
        mkpath("$td3/bin");
        write_fixture("$td3/bin/prog", "use App::Reachable::Sub; print App::Reachable::x(), \"\n\";");
        ($out, $rc) = run_cli('-o', "$td3/out", '--no-compress', '--lib', "$td3/lib", '--fatlib', "$td/fatlib", "$td3/bin/prog");
        is $rc, 0, 'reachable-only build exits 0';
        $c = file_content("$td3/out");
        like $c, qr/package App::Reachable::Sub;/, 'directly-used module bundled';
        like $c, qr/package App::Reachable;/,      'transitive dependency bundled';
        unlike $c, qr/package App::Unused;/,       'unused module NOT bundled';
        is `"$td3/out"`, "1\n", 'reachable-only bundle runs';
    }

    # -- --bundle-lib-all: every lib module bundled
    {
        my $td4 = tempdir(CLEANUP => 1);
        mkpath("$td4/lib/App");
        write_fixture("$td4/lib/App/Used.pm",   "package App::Used; 1;\n");
        write_fixture("$td4/lib/App/Unused.pm", "package App::Unused; 1;\n");
        mkpath("$td4/bin");
        write_fixture("$td4/bin/prog", "use App::Used;");
        ($out, $rc) = run_cli('-o', "$td4/out", '--no-compress', '--bundle-lib-all', '--lib', "$td4/lib", '--fatlib', "$td4/fatlib", "$td4/bin/prog");
        is $rc, 0, '--bundle-lib-all build exits 0';
        $c = file_content("$td4/out");
        like $c, qr/package App::Used;/,   'used module bundled';
        like $c, qr/package App::Unused;/, 'unused module bundled with --bundle-lib-all';
    }

    # -- plugin search_path force-includes classes even if not use'd
    {
        my $td5 = tempdir(CLEANUP => 1);
        mkpath("$td5/lib/App/Plug");
        write_fixture("$td5/lib/App/Plug/Alpha.pm", "package App::Plug::Alpha; 1;\n");
        write_fixture("$td5/lib/App/Plug/Beta.pm",  "package App::Plug::Beta; 1;\n");
        mkpath("$td5/lib/App/Plug/Deep");
        write_fixture("$td5/lib/App/Plug/Deep/Gamma.pm", "package App::Plug::Deep::Gamma; 1;\n");
        mkpath("$td5/bin");
        write_fixture("$td5/bin/prog", 'use Module::Pluggable (search_path => "App::Plug"); my @p = plugins();');
        ($out, $rc) = run_cli('-o', "$td5/out", '--no-compress', '--lib', "$td5/lib", '--fatlib', "$td5/fatlib", "$td5/bin/prog");
        is $rc, 0, 'plugin search_path build exits 0';
        $c = file_content("$td5/out");
        like $c, qr/package App::Plug::Alpha;/,  'plugin Alpha force-included';
        like $c, qr/package App::Plug::Beta;/,   'plugin Beta force-included';
        unlike $c, qr/package App::Plug::Deep/,  'nested Gamma NOT force-included (one-level only)';
    }

    # -- unresolved dependency warning
    {
        my $td6 = tempdir(CLEANUP => 1);
        mkpath("$td6/lib");
        mkpath("$td6/bin");
        write_fixture("$td6/bin/prog", 'use NonExistent::Module; print "hi\n"');
        ($out, $rc) = run_cli('-o', "$td6/out", '--lib', "$td6/lib", '--fatlib', "$td6/fatlib", "$td6/bin/prog");
        like $out, qr/unresolved dependencies/, 'warns about unresolved deps';
        like $out, qr/NonExistent::Module/,      'names the unresolved module';
    }
}

# second tempdir for error-path tests that mess with permissions

done_testing;