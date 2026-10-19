use Test2::V0;
use File::Temp qw/tempdir/;

use DBIx::QuickDB::Util qw/find_bin/;

# The Cygwin branch walks PATH itself. /cygdrive cannot be created here, so
# this covers the walk; the lab covers skipping real native installs.
skip_all "stub binaries require a POSIX shell (#!/bin/sh), unavailable on $^O"
    if $^O eq 'MSWin32';

my $root = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
mkdir("$root/$_") or die "mkdir: $!" for qw/first second/;

for my $dir (qw/first second/) {
    open(my $fh, '>', "$root/$dir/qdb-fake") or die "open: $!";
    print $fh "#!/bin/sh\n";
    close($fh);
    chmod(0755, "$root/$dir/qdb-fake");
}

open(my $fh, '>', "$root/first/qdb-noexec") or die "open: $!";
close($fh);

# A copy: $os aliasing $^O itself would be blanked by the local below.
my $native = $^O;
for my $os ($native, 'cygwin') {
    subtest "as $os" => sub {
        local $^O = $os;
        local $ENV{PATH} = "/cygdrive/c/qdb-missing::$root/first:$root/second";

        is(find_bin('qdb-fake'),    "$root/first/qdb-fake", 'first match on PATH wins');
        is(find_bin('qdb-noexec'),  undef,                  'non-executable file is skipped');
        is(find_bin('qdb-missing'), undef,                  'missing command is undef');
    };
}

done_testing;
