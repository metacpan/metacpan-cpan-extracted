#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempdir);

use lib "$FindBin::Bin/../lib";

my $LIB    = "$FindBin::Bin/../lib";
my $CLI    = "$FindBin::Bin/../bin/slimpack";
my $MINIFY = "$FindBin::Bin/../bin/minify";

# minify-only mode: run the CLI scripts exactly as a user would. slimpack's
# minify subcommand, the --minify flag, and the standalone minify script all
# share App::SlimPacker::minify_file.
sub run_cli {
    my ($bin, @args) = @_;
    my $cmd = join ' ', (qq{'$^X'} . " -I'$LIB'", "'$bin'"), map { "'$_'" } @args;
    my $out = `$cmd 2>&1`;
    my $rc  = $? >> 8;
    return ($out, $rc);
}

sub write_fixture {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print {$fh} $content;
    close $fh;
}

my $TD = tempdir(CLEANUP => 1);

my $hello = <<'HELLO';
#!/usr/bin/perl
use strict;            # a trailing comment
use warnings;

my $longname = "world";

print "Hello, " . $longname . "!\n";
HELLO

write_fixture("$TD/hello.pl",      $hello);
write_fixture("$TD/a.pl",          "#!/usr/bin/perl\nprint \"a\\n\";\n");
write_fixture("$TD/b.pl",          "#!/usr/bin/perl\nprint \"b\\n\";\n");

my ($out, $rc);

# -- minify subcommand: strips comments, preserves the shebang, renames my vars
($out, $rc) = run_cli($CLI, 'minify', "$TD/hello.pl");
is $rc, 0, 'minify subcommand exits 0';
like $out, qr/^#!/,          'minify keeps the shebang line';
like $out, qr/Hello/,        'minify keeps the code';
unlike $out, qr/trailing comment/, 'minify strips comments';
unlike $out, qr/\$longname/, 'minify renames my variables by default';
write_fixture("$TD/run.pl", $out);
is `"$^X" "$TD/run.pl"`, "Hello, world!\n", 'minified hello.pl runs standalone';

# -- --minify flag behaves identically to the subcommand
my ($flag_out, $flag_rc) = run_cli($CLI, '--minify', "$TD/hello.pl");
is $flag_rc, 0, '--minify flag exits 0';
is $flag_out, $out, '--minify flag matches the minify subcommand';

# -- --no-rename keeps variable names
($out, $rc) = run_cli($CLI, 'minify', '--no-rename', "$TD/hello.pl");
is $rc, 0, 'minify --no-rename exits 0';
like $out, qr/\$longname/, 'minify --no-rename keeps variable names';
unlike $out, qr/trailing comment/, 'minify --no-rename still strips comments';

# -- --rename matches the default (both spellings negatable)
my ($ren_out, $ren_rc) = run_cli($CLI, 'minify', '--rename', "$TD/hello.pl");
is $ren_rc, 0, 'minify --rename exits 0';
unlike $ren_out, qr/\$longname/, 'minify --rename renames variables (like default)';

# -- --no-rewrite and --rewrite are both accepted (rewrite is off by default)
my ($def_out) = run_cli($CLI, 'minify', "$TD/hello.pl");
($out, $rc) = run_cli($CLI, 'minify', '--rewrite', "$TD/hello.pl");
is $rc, 0, 'minify --rewrite exits 0';
($out, $rc) = run_cli($CLI, 'minify', '--no-rewrite', "$TD/hello.pl");
is $rc, 0, 'minify --no-rewrite exits 0';
is $out, $def_out, 'minify --no-rewrite matches the default (off) output';

# -- -o writes a file (single input)
($out, $rc) = run_cli($CLI, 'minify', '-o', "$TD/out.pl", "$TD/hello.pl");
is $rc, 0, 'minify -o exits 0';
ok -f "$TD/out.pl", 'minify -o writes the output file';
is `"$^X" "$TD/out.pl"`, "Hello, world!\n", 'minify -o output runs standalone';

# -- multiple inputs go to STDOUT, each minified
($out, $rc) = run_cli($CLI, 'minify', "$TD/a.pl", "$TD/b.pl");
is $rc, 0, 'minify with several files exits 0';
is scalar(() = $out =~ /^#!/mg), 2, 'minify prints each file with its shebang';
like $out, qr/\Q"a\n";\E/, 'minify prints the first file';
like $out, qr/\Q"b\n";\E/, 'minify prints the second file';

# -- errors
($out, $rc) = run_cli($CLI, 'minify');
isnt $rc, 0, 'minify with no files exits nonzero';
like $out, qr/missing source/, 'minify reports the missing file';

($out, $rc) = run_cli($CLI, 'minify', '-o', "$TD/one", "$TD/a.pl", "$TD/b.pl");
isnt $rc, 0, 'minify -o with several files exits nonzero';
like $out, qr/exactly one source file/, 'minify -o reports the input count';

($out, $rc) = run_cli($CLI, 'minify', '--help');
is $rc, 0, 'minify --help exits 0';
like $out, qr/minify/, 'minify --help mentions the minify command';

# -- unreadable input
($out, $rc) = run_cli($CLI, 'minify', "$TD/missing.pl");
isnt $rc, 0, 'minify with an unreadable file exits nonzero';
like $out, qr/Cannot read/, 'minify reports the unreadable file';

# -- standalone minify script
($out, $rc) = run_cli($MINIFY, "$TD/hello.pl");
is $rc, 0, 'bin/minify exits 0';
like $out, qr/^#!/,          'bin/minify keeps the shebang line';
unlike $out, qr/trailing comment/, 'bin/minify strips comments';
unlike $out, qr/\$longname/, 'bin/minify renames my variables by default';
write_fixture("$TD/minified.pl", $out);
is `"$^X" "$TD/minified.pl"`, "Hello, world!\n", 'bin/minify output runs standalone';

($out, $rc) = run_cli($MINIFY, '-o', "$TD/minified2.pl", "$TD/hello.pl");
is $rc, 0, 'bin/minify -o exits 0';
ok -f "$TD/minified2.pl", 'bin/minify -o writes the output file';
is `"$^X" "$TD/minified2.pl"`, "Hello, world!\n", 'bin/minify -o output runs standalone';

($out, $rc) = run_cli($MINIFY, '--no-rename', "$TD/hello.pl");
is $rc, 0, 'bin/minify --no-rename exits 0';
like $out, qr/\$longname/, 'bin/minify --no-rename keeps variable names';

($out, $rc) = run_cli($MINIFY, '--help');
is $rc, 0, 'bin/minify --help exits 0';
like $out, qr/Usage: minify/, 'bin/minify --help shows usage';

($out, $rc) = run_cli($MINIFY);
isnt $rc, 0, 'bin/minify with no files exits nonzero';
like $out, qr/missing source/, 'bin/minify reports the missing file';

($out, $rc) = run_cli($MINIFY, '-o', "$TD/one", "$TD/a.pl", "$TD/b.pl");
isnt $rc, 0, 'bin/minify -o with several files exits nonzero';
like $out, qr/exactly one source file/, 'bin/minify -o reports the input count';

done_testing;