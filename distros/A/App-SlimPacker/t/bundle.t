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
    # unless 'pack' (the full fatpack pipeline) is asked for.
    my $sub = (@args && $args[0] =~ /^(?:bundle|pack)$/) ? shift @args : 'bundle';
    unshift @args, ('--lib', "$td/lib")    unless grep { $_ eq '--lib' } @args;
    unshift @args, ('--fatlib', "$td/fatlib") unless grep { $_ eq '--fatlib' } @args;
    unshift @args, '--no-rename-modules'
        unless grep { /^--(?:no-)?rename-modules$/ } @args;
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
    like $c, qr/"App\/MyMod\.pm"=>/, 'bundled module source held in hook map';
    unlike $c, qr/\$INC\{'App\/MyMod\.pm'\}=1;/, 'no eager %INC prefill';
    unlike $c, qr/# keep me/, 'module comments minified (default)';
    unlike $c, qr/# boot comment/, 'program comments minified (default)';
    unlike $c, qr/\$who/, 'short variable renamed (strings with it would block, fixture avoids that)';
    unlike $c, qr/use lib/, 'use lib stripped from program';
    like $c, qr/BEGIN\{my%c=\(/, 'compact loader: single BEGIN{my%c=(...) block';
    like $c, qr/bless\\%c,\$d;/, 'compact loader: bless+unshift {$d} fragment';
    unlike $c, qr/__SLPACK_ENTRIES__/, 'loader placeholder spliced away';
    like $c, qr/use Compress::Raw::Zlib \(\);/, 'compressed loader: core zlib loaded';
    unlike $c, qr/use MIME::Base64/, 'default loader is binary: no base64 dependency';
    unlike $c, qr/[\x0d\x1a]/, 'default bundle contains no CR or ctrl-Z bytes';
    my ($table) = $c =~ /BEGIN\{my%c=\((.*?)\);my%u=/s
        or die "cannot locate module table in bundle";
    unlike $table, qr/\\\$/, 'module table has no escaped sigils (all single-quoted)';
    like $table, qr/"App\/MyMod\.pm"=>'/, 'module source a quoted literal in table (binary, default)';
    unlike $table, qr/package App::MyMod;/, 'compressed source not embedded verbatim';
    like $table, qr/"__MAIN__"=>'/, 'boot program entry in table (binary, default)';
    unlike $c, qr/print App::MyMod::greet\('cli'\),/, 'boot program text not embedded verbatim (compressed)';
    is `"$^X" "$td/myapp_bundled"`, "hi cli\n", 'bundled script runs standalone';
    {
        local $ENV{PERL5LIB};
        is `"$^X" "$td/myapp_bundled"`, "hi cli\n", 'compressed bundle runs with @INC pruned';
    }

    # -- no-compress: identical behavior from visible, readable source literals
    ($out, $rc) = run_cli('-o', "$td/myapp_plain", '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--no-compress build exits 0';
    $c = file_content("$td/myapp_plain");
    unlike $c, qr/use Compress::Raw::Zlib/, '--no-compress omits zlib loader';
    my ($table3) = $c =~ /BEGIN\{my%c=\((.*?)\);my\$d=/s
        or die "cannot locate module table in plain bundle";
    like $table3, qr/"App\/MyMod\.pm"=>'package App::MyMod;/, 'plain: module code embedded as single-quoted literal (pack_string)';
    is `"$^X" "$td/myapp_plain"`, "hi cli\n", 'plain bundle runs standalone';
    is `"$^X" "$td/myapp_plain"`, `"$^X" "$td/myapp_bundled"`, 'compressed and plain bundles behave identically';

    # -- no-binary: base64 entries, a plain text file at the cost of size
    ($out, $rc) = run_cli('-o', "$td/myapp_base64", '--no-binary', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--no-binary build exits 0';
    $c = file_content("$td/myapp_base64");
    like $c, qr/use Compress::Raw::Zlib \(\);/, 'base64 loader: core zlib loaded';
    like $c, qr/use MIME::Base64 qw\(decode_base64\);/, 'base64 loader: core base64 loaded';
    my ($btable) = $c =~ /BEGIN\{my%c=\((.*?)\);my\$x=/s
        or die "cannot locate module table in base64 bundle";
    like $btable, qr/"App\/MyMod\.pm"=>'[A-Za-z0-9+\/=]+'/, 'module source deflate+base64 in table';
    unlike $btable, qr/package App::MyMod;/, 'base64 source not embedded verbatim';
    unlike $c, qr/[^\t\n\x20-\x7e]/, '--no-binary bundle is pure printable ASCII';
    cmp_ok length(file_content("$td/myapp_bundled")), '<', length($c),
        'default binary bundle smaller than --no-binary bundle';
    is `"$^X" "$td/myapp_base64"`, "hi cli\n", '--no-binary bundle runs standalone';

    # -- --binary without compression is refused
    ($out, $rc) = run_cli('-o', "$td/myapp_nope", '--binary', '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    isnt $rc, 0, '--binary --no-compress is an error';
    like $out, qr/--binary needs compression/, '--binary --no-compress error message';

    # -- explicit --compress flag (default, but the switch must work)
    ($out, $rc) = run_cli('-o', "$td/myapp_comp", '--compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '--compress flag build exits 0';
    like file_content("$td/myapp_comp"), qr/use Compress::Raw::Zlib \(\);/, '--compress embeds compressed loader';
    is `"$^X" "$td/myapp_comp"`, "hi cli\n", '--compress bundle runs';

    # -- a boot program with __DATA__/__END__ is compressed like everything
    #    else: the data section is split into its own '__DATA__' entry and
    #    the loader aliases *main::DATA to an in-memory handle over it
    write_fixture("$td/bin/dataapp", <<'DL');
#!/usr/bin/perl
use lib 'lib';
use App::MyMod;
print App::MyMod::greet('d'), "\n" . <DATA>;
print "rest: $_" while <DATA>;
__DATA__
data line
more data
DL
    ($out, $rc) = run_cli('-o', "$td/dataapp_bundled", '--lib', "$td/lib", "$td/bin/dataapp");
    is $rc, 0, 'data-section boot build exits 0';
    unlike $out, qr/uncompressed/, 'no warning: data-section boot program is compressed now';
    my $dc = file_content("$td/dataapp_bundled");
    unlike $dc, qr/^__DATA__$/m, 'no verbatim __DATA__ section in the bundle';
    unlike $dc, qr/data line/, 'data section not embedded verbatim';
    like $dc, qr/fileno\*main::DATA/, 'loader guards an already-open main::DATA';
    like $dc, qr/\*main::DATA=/, 'loader aliases *main::DATA';
    my ($dt) = $dc =~ /BEGIN\{my%c=\((.*?)\);my%u=/s
        or die "cannot locate module table in data bundle";
    like $dt, qr/"__MAIN__"=>'/, 'boot program compressed despite data section';
    like $dt, qr/"__DATA__"=>'/, 'data section compressed as its own entry';
    is `"$^X" "$td/dataapp_bundled"`, "hi d\ndata line\nrest: more data\n", 'data-section bundle runs (module + <DATA>)';
    is `"$^X" "$td/dataapp_bundled"`, `"$^X" -I"$td/lib" "$td/bin/dataapp"`, 'data-section bundle matches running the raw script';

    # -- same boot program under --no-binary
    ($out, $rc) = run_cli('-o', "$td/dataapp_base64", '--no-binary', '--lib', "$td/lib", "$td/bin/dataapp");
    is $rc, 0, 'data-section --no-binary build exits 0';
    like file_content("$td/dataapp_base64"), qr/"__DATA__"=>'[A-Za-z0-9+\/=]+'/,
        'data section deflate+base64 under --no-binary';
    is `"$^X" "$td/dataapp_base64"`, "hi d\ndata line\nrest: more data\n", 'data-section --no-binary bundle runs';

    # -- a boot program that bundles no modules at all still builds a valid
    #    table (the __MAIN__/__DATA__ entries must not leave a stray comma)
    write_fixture("$td/bin/lonely", "print 'solo: ' . <DATA>;\n__DATA__\nok\n");
    mkpath("$td/emptylib"); mkpath("$td/emptyfat");
    ($out, $rc) = run_cli('-o', "$td/lonely_bundled", '--lib', "$td/emptylib", '--fatlib', "$td/emptyfat", "$td/bin/lonely");
    is $rc, 0, 'module-less boot build exits 0';
    is `"$^X" "$td/lonely_bundled"`, "solo: ok\n", 'module-less bundle runs (boot + data only)';

    # -- shebang: the boot script's own is kept (tested on myapp above); a
    #    script without one gets the portable env form, --shebang overrides
    like file_content("$td/lonely_bundled"), qr{^#!/usr/bin/env perl\n},
        'shebang-less boot script gets #!/usr/bin/env perl';
    ($out, $rc) = run_cli('-o', "$td/lonely_sb", '--shebang', '/opt/perl/bin/perl -w',
        '--lib', "$td/emptylib", '--fatlib', "$td/emptyfat", "$td/bin/lonely");
    is $rc, 0, '--shebang build exits 0';
    like file_content("$td/lonely_sb"), qr{^#!/opt/perl/bin/perl -w\n},
        '--shebang overrides the bundle shebang (#! added)';

    # -- pack_string endings under a real bundle: quote-rich module must land
    #    in a q<delim> literal, backslash module in an escaped single-quote,
    #    and both must still run against the embedded copies.
    ($out, $rc) = run_cli('-o', "$td/quback_plain", '--no-compress', '--lib', "$td/lib", "$td/bin/quback");
    is $rc, 0, 'quback --no-compress build exits 0';
    $c = file_content("$td/quback_plain");
    like $c, qr/"App\/QuOt\.pm"=>q\^/, 'quote-rich module embedded via q<delim> literal';
    like $c, qr/"App\/Back\.pm"=>'/, 'backslash module embedded as escaped single-quote (no perlstring)';
    my ($table2) = $c =~ /BEGIN\{my%c=\((.*?)\);my\$d=/s
        or die "cannot locate module table in quback bundle";
    unlike $table2, qr/\\\$/ , 'quback table has no perlstring sigil escapes';
    is `"$^X" "$td/quback_plain"`, "he said 'hi'\na\\b\n", 'q-delim and fallback modules run standalone';
    {
        local $ENV{PERL5LIB};
        is `"$^X" "$td/quback_plain"`, "he said 'hi'\na\\b\n", 'plain stress bundle runs with @INC pruned';
    }

    # -- compressed equivalents of the same fixtures, incl. binary-clean
    #    round-trip of the backslash module through deflate/inflate
    ($out, $rc) = run_cli('-o', "$td/quback_bundled", '--lib', "$td/lib", "$td/bin/quback");
    is $rc, 0, 'quback build exits 0';
    $c = file_content("$td/quback_bundled");
    my ($tableq) = $c =~ /BEGIN\{my%c=\((.*?)\);my%u=/s
        or die "cannot locate module table in quback bundle";
    like $tableq, qr/"App\/QuOt\.pm"=>'/, 'quote-rich module compressed into table';
    is `"$^X" "$td/quback_bundled"`, "he said 'hi'\na\\b\n", 'compressed backslash/quotes round-trip byte-identically';
    is `"$^X" "$td/quback_bundled"`, `"$^X" "$td/quback_plain"`, 'compressed and plain quback behave identically';

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
        like $c, qr/"App\/Extra\/NoPacklist\.pm"=>/, 'no-packlist module bundled from @INC';
        is `"$^X" "$td/eed_bundled"`, "extra\n", 'unpacklisted-module bundle runs standalone';
        {
            local $ENV{PERL5LIB};
            is `"$^X" "$td/eed_bundled"`, "extra\n", 'unpacklisted-module bundle runs with @INC pruned';
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
    like $c, qr/"App\/CoreDep\.pm"=>/, 'non-core dep module bundled';
    unlike $c, qr/"Carp\.pm"=>/, 'core module (Carp) NOT bundled';
    unlike $c, qr/"Config\.pm"=>/, 'core module (Config) NOT bundled';
    is `"$^X" "$td/cd_bundled"`, "ok\n", 'core-dep bundle runs standalone';

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
    like $c, qr/"Deep\/Pkg\.pm"=>/, 'deep module bundled (path normalised)';
    like $c, qr/"Deep\/Pkg\/Sub\.pm"=>/, 'deep submodule bundled (path normalised)';
    {
        local $ENV{PERL5LIB};
        is `"$^X" "$td/deep_bundled"`, "deep nested\n", 'deep-nested bundle runs standalone';
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
    is `"$^X" "$td/nr"`, "hi cli\n", '--no-rename bundle runs standalone';

    # -- plugin inlining (default on)
    ($out, $rc) = run_cli('-o', "$td/lab_bundled", '--no-compress', '--lib', "$td/lib", "$td/bin/lab");
    is $rc, 0, 'inline-plugins build exits 0';
$c = file_content("$td/lab_bundled");
like $c, qr/"App::Lab::Adapter::A","App::Lab::Adapter::B"/, 'plugin classes inlined, sorted, one level';
my ($pluglist) = $c =~ /\bsort\s*\(\s*((?:"[^"]+")(?:\s*,\s*"[^"]+")*)\)/;
is $pluglist, '"App::Lab::Adapter::A","App::Lab::Adapter::B"', 'exactly the one-level plugins inlined';
unlike $c, qr/\Quse Module::Pluggable\E/, 'Module::Pluggable removed from bundle';
is `"$^X" "$td/lab_bundled"`, "App::Lab::Adapter::A,App::Lab::Adapter::B\n", 'inlined script runs without Module::Pluggable';

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
    is `"$^X" "$td/ovr"`, 'override ', '-e snippet wins over script';

    # -- -M module prepended to script
    ($out, $rc) = run_cli('-o', "$td/strict", '-M', 'strict', '--no-compress', '--lib', "$td/lib", "$td/bin/myapp");
    is $rc, 0, '-M build exits 0';
    is `"$^X" "$td/strict"`, "hi cli\n", '-M script runs';
    like file_content("$td/strict"), qr/use strict;\s*use App::MyMod;\s*print App::MyMod::\w+\('cli'\),"\\n";/, '-M line prepended before boot script (minified)';

    # -- -M list + -e program
    ($out, $rc) = run_cli('-o', "$td/ul", '--no-compress', '-M', 'List::Util=sum', '-e', 'print sum(1..100)');
    is $rc, 0, '-M/-e program builds';
my $ulc = file_content("$td/ul");
like $ulc, qr/use List::Util qw\(sum\);\s*print sum\(1\.\.100\)/, '-M/-e both honored';
is `"$^X" "$td/ul"`, '5050', '-M List::Util=sum -e program runs';

    # -- -E enables features
    ($out, $rc) = run_cli('-o', "$td/sayb", '--no-compress', '-E', 'say "bye";');
    is $rc, 0, '-E program builds';
    like file_content("$td/sayb"), qr/use feature qw\(:all\);\s*say "bye";/, '-E prepends feature pragma';
    is `"$^X" "$td/sayb"`, "bye\n", '-E program runs';

    # -- multiple -m
    ($out, $rc) = run_cli('-o', "$td/multi_m", '--no-compress', '-m', 'Carp', '-m', 'strict', '-e', 'print qq(ok)');
    is $rc, 0, 'multiple -m builds';
    my $mc = file_content("$td/multi_m");
    like $mc, qr/use Carp\(\);\s*use strict\(\);\s*print qq\(ok\)/, 'first -m as use X (); followed by second -m';
    is `"$^X" "$td/multi_m"`, 'ok', 'multiple -m program runs';

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
        is `"$^X" "$td3/out"`, "1\n", 'reachable-only bundle runs';
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

    # -- module renaming (--rename-modules, the default) and --rename-exports
    {
        my $tdm = tempdir(CLEANUP => 1);
        mkpath("$tdm/lib/App/Pack");
        mkpath("$tdm/bin");
        mkpath("$tdm/fatlib");
        write_fixture("$tdm/lib/App/Pack/Thing.pm", <<'THING');
package App::Pack::Thing;
use strict; use warnings;
sub new { my $class = shift; bless {}, $class }
sub greet { my ($self, $who) = @_; return "hi " . $who }
sub me { return "App::Pack::Thing" }
1;
THING
        # A mini exporter written without Exporter (which would only bloat the
        # bundle): can('name') + typeglob install is exactly the seam
        # --rename-exports watches.
        write_fixture("$tdm/lib/App/Pack/Chair.pm", <<'CHAIR');
package App::Pack::Chair;
use strict; use warnings;
our @EXPORT_OK = qw(squeak);
sub import {
    my $class = shift;
    no strict 'refs';
    for my $name (@_) {
        my $code = $class->can($name);
        *{caller() . '::' . $name} = $code if $code;
    }
}
sub new { my $class = shift; bless {}, $class }
sub squeak { return 42 }
sub via_can { my $o = shift; return $o->can('squeak') ? $o->squeak : 'none' }
1;
CHAIR
        write_fixture("$tdm/bin/packer", <<'PBOOT');
#!/usr/bin/perl
use lib 'lib';
require "App/Pack/Thing.pm";
use App::Pack::Thing;
use App::Pack::Chair qw(squeak);
my $t = App::Pack::Thing->new;
my $c = App::Pack::Chair->new;
print $t->greet('c'), "\n";
print squeak(), " ", $c->via_can, "\n";
PBOOT

        # Default rename-modules on: loader keys and sources agree with the
        # renamed `package`/`use`, INCLUDING each package's leaf component,
        # and a string-form `require` still resolves.
        ($out, $rc) = run_cli('--rename-modules', '--no-rename-subs',
            '--no-rename-vars', '-o', "$tdm/pkrm", '--no-compress',
            '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/bin/packer");
        is $rc, 0, 'rename-modules build exits 0';
        $c = file_content("$tdm/pkrm");
        unlike $c, qr/"App\/Pack\/Thing\.pm"=>/, 'loader key no longer the original path';
        like $c, qr/"\w+(?:\/\w+)+\.pm"=>/,      'loader key rewritten to short components (leaf renamed too)';
        like $c, qr/package \w+(?:::\w+)+;/,      'package declaration renamed, leaf renamed too';
        like $c, qr/use \w+(?:::\w+)+ qw/,        'use statement renamed in step';
        like $c, qr/require "\w+(?:\/\w+)+\.pm";/, 'string-form require path rewritten';
        unlike $c, qr/App::Pack::(?:Thing|Chair)/, 'no original package name left';
        is `"$^X" "$tdm/pkrm"`, "hi c\n42 42\n", 'rename-modules bundle runs standalone';

        # A single-component package (no ::) keeps its name.
        write_fixture("$tdm/lib/Std.pm", <<'STD');
package Std;
use strict; use warnings;
#  $td/bin/stds is a single-component main that only calls Std::ans().
my $fat_long_name = 1;
sub ans { return $fat_long_name + 41 }
1;
STD
        write_fixture("$tdm/bin/stds", <<'SBOOT');
#!/usr/bin/perl
use lib 'lib';
require "Std.pm";
use Std;
print "build " . Std::ans() . "\n";
SBOOT
        ($out, $rc) = run_cli('--rename-modules', '-o', "$tdm/pkstd",
            '--no-compress', '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/bin/stds");
        is $rc, 0, 'standalone-main build exits 0';
        $c = file_content("$tdm/pkstd");
        like $c, qr/"Std\.pm"=>/,        'single-component loader key kept';
        like $c, qr/package Std;/,        'single-component package kept';
        like $c, qr/require "Std\.pm";/,  'Std.pm string require kept';
        is `"$^X" "$tdm/pkstd"`, "build 42\n",   'standalone-main bundle runs';

        # --no-rename-modules keeps the original names (default alone does not
        # break existing bundles).
        ($out, $rc) = run_cli('--no-rename-modules', '-o', "$tdm/pknrm",
            '--no-compress', '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/bin/packer");
        is $rc, 0, 'no-rename-modules build exits 0';
        $c = file_content("$tdm/pknrm");
        like $c, qr/"App\/Pack\/Thing\.pm"=>/,   'loader key kept verbatim';
        like $c, qr/package App::Pack::Thing;/,   'package declaration kept';
        is `"$^X" "$tdm/pknrm"`, "hi c\n42 42\n", 'no-rename-modules bundle runs';

        # --rename-exports: sub names that only pass through the export/import
        # protocol (no display strings) are shortened in step across modules.
        ($out, $rc) = run_cli('--rename-modules', '--rename-exports',
            '--no-rename-vars', '-o', "$tdm/pkex", '--no-compress',
            '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/bin/packer");
        is $rc, 0, 'rename-exports build exits 0';
        $c = file_content("$tdm/pkex");
        like $c, qr/\@EXPORT_OK=qw\(\w+\)/,   'export list entry renamed';
        unlike $c, qr/qw\(squeak\)/,         'squeak no longer verbatim in qw lists';
        unlike $c, qr/sub squeak\{/,         'squeak sub renamed';
        is `"$^X" "$tdm/pkex"`, "hi c\n42 42\n", 'rename-exports bundle runs standalone';

        # --rename-exports OFF freezes names that would round-trip through a
        # can()/import() string (the historical behavior).
        ($out, $rc) = run_cli('--rename-modules', '--no-rename-exports',
            '--no-rename-vars', '-o', "$tdm/pknoex", '--no-compress',
            '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/bin/packer");
        is $rc, 0, 'no-rename-exports build exits 0';
        $c = file_content("$tdm/pknoex");
        like $c, qr/qw\(squeak\)/,      'squeak frozen in qw lists without rename-exports';
        like $c, qr/sub squeak\{/,      'squeak sub kept when rename-exports off';
        is `"$^X" "$tdm/pknoex"`, "hi c\n42 42\n", 'no-rename-exports bundle runs standalone';
    }
}

# second tempdir for error-path tests that mess with permissions

# ── real-world bundle: a small Moo program, with and without module renaming.
#    Moo installs subs through globs, builds code from strings (Sub::Quote)
#    and looks classes up by name, so it exercises every rename pass.  The
#    fatlib is copied from the installed Moo, so the test follows whatever
#    Moo version is around and is skipped without it.
SKIP: {
    skip 'Moo not installed', 10 unless eval { require Moo; 1 };
    require Module::CoreList;
    my $tdm = tempdir(CLEANUP => 1);
    mkpath("$tdm/lib");
    write_fixture("$tdm/hello.pl", <<'EOF');
package MyGreeter;
use Moo;

has name => (is => 'ro', default => sub { 'world' });

sub greet {
    my $self = shift;
    return "Hello, " . $self->name . "!\n";
}

package main;
print MyGreeter->new->greet;
# report every module loaded from outside the bundle
END { print "INC $_ $INC{$_}\n" for grep { defined $INC{$_} && !ref $INC{$_} && $INC{$_} !~ m{^(?:/loader/|\(eval )} } sort keys %INC }
EOF
    my $is_core = sub {
        (my $mod = shift) =~ s{/}{::}g;
        $mod =~ s/\.p[ml]\z//;
        return Module::CoreList::is_core($mod, undef, $]);
    };

    # copy exactly the non-core modules the program loads into the fatlib
    my @loaded = map { /^INC (\S+) (\S+)$/ ? [$1, $2] : () }
        `'$^X' '$tdm/hello.pl'`;
    for my $m (grep { !$is_core->($_->[0]) } @loaded) {
        my ($rel, $from) = @$m;
        (my $dir = "$tdm/fatlib/$rel") =~ s{/[^/]+\z}{};
        mkpath($dir);
        write_fixture("$tdm/fatlib/$rel", file_content($from));
    }

    for my $rename ('--rename-modules', '--no-rename-modules') {
        my ($out, $rc) = run_cli($rename, '-o', "$tdm/hello-packed",
            '--lib', "$tdm/lib", '--fatlib', "$tdm/fatlib", "$tdm/hello.pl");
        is $rc, 0, "Moo bundle builds ($rename)" or diag $out;
        # run without PERL5LIB, so only the bundle and core perl can be found
        local $ENV{PERL5LIB};
        local $ENV{PERL5OPT};
        my @run = `'$^X' '$tdm/hello-packed' 2>&1`;
        is $run[0], "Hello, world!\n", "Moo bundle runs ($rename)"
            or diag @run;
        my @outside = grep { !$is_core->($_) }
            map { /^INC (\S+) / ? $1 : () } @run;
        is_deeply \@outside, [], "Moo bundle loads nothing from outside ($rename)";
    }

    # the full pipeline leaves Moose out: Moo only loads it when Moose is used
    my ($out, $rc) = run_cli('pack', '--no-compress', '-o', "$tdm/hello-pack",
        '--lib', "$tdm/lib", "$tdm/hello.pl");
    is $rc, 0, 'Moo pack builds' or diag $out;
    my $c = file_content("$tdm/hello-pack");
    like $c, qr/"Moo\/sification\.pm"=>/, 'Moo pack bundles Moo';
    unlike $c, qr/"(?:Moo\/HandleMoose|Moose|Class\/MOP)\.pm"=>/,
        'Moo pack leaves out Moo::HandleMoose and Moose';
    local $ENV{PERL5LIB};
    local $ENV{PERL5OPT};
    my @run = `'$^X' '$tdm/hello-pack' 2>&1`;
    is $run[0], "Hello, world!\n", 'Moo pack runs' or diag @run;
}

# ── gated, included and excluded modules.  Moo::HandleMoose is only bundled
#    when Moose is in the bundle anyway; fake modules stand in for both.
{
    my $tdg = tempdir(CLEANUP => 1);
    mkpath(["$tdg/lib/Moo", "$tdg/lib/Extra"]);
    write_fixture("$tdg/lib/Lazy.pm",
        "package Lazy;\nsub meta { require Moo::HandleMoose; }\n1;\n");
    write_fixture("$tdg/lib/Moo/HandleMoose.pm",
        "package Moo::HandleMoose;\nuse Moose ();\n1;\n");
    write_fixture("$tdg/lib/Moose.pm", "package Moose;\n1;\n");
    write_fixture("$tdg/lib/Extra/$_.pm", "package Extra::$_;\n1;\n")
        for qw(One Two);
    write_fixture("$tdg/lazy.pl", "use Lazy;\nprint qq{ok\\n};\n");
    write_fixture("$tdg/moose.pl", "use Lazy;\nuse Moose ();\nprint qq{ok\\n};\n");
    my $bundled = sub {
        my ($script, @opts) = @_;
        my ($out, $rc) = run_cli('--no-compress', @opts, '-o', "$tdg/packed",
            '--lib', "$tdg/lib", '--fatlib', "$tdg/fatlib", "$tdg/$script");
        is $rc, 0, "bundle $script @opts" or diag $out;
        my $c = file_content("$tdg/packed");
        return join ' ', sort map { (my $m = $_) =~ s{/}{::}g; $m } $c =~ /"([\w\/]+)\.pm"=>/g;
    };
    is $bundled->('lazy.pl'), 'Lazy', 'gated module left out without its gate';
    is $bundled->('moose.pl'), 'Lazy Moo::HandleMoose Moose',
        'gated module bundled when its gate is';
    is $bundled->('lazy.pl', '--include', 'Moo::HandleMoose'),
        'Lazy Moo::HandleMoose Moose', '--include overrides the gate';
    is $bundled->('lazy.pl', '--include', 'Extra::*'), 'Extra::One Extra::Two Lazy',
        '--include with a wildcard';
    is $bundled->('moose.pl', '--exclude', 'Moose'), 'Lazy',
        '--exclude drops the module and what is gated on it';
    is $bundled->('moose.pl', '--exclude', 'Moo*'), 'Lazy',
        '--exclude with a wildcard';
}

done_testing;