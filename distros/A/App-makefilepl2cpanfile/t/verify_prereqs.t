use Test::Most;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file read_file);
use App::makefilepl2cpanfile;

# ----------------------------
# Setup temporary directory
# ----------------------------
my $dir = tempdir(CLEANUP => 1);
chdir $dir;

# Write a representative Makefile.PL with runtime, test, and configure deps
write_file 'Makefile.PL', <<'EOF';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Test::Dummy',
    PREREQ_PM => {
        'Foo::Bar' => 0,
        'Baz::Qux' => '1.23',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    MIN_PERL_VERSION => '5.008',
);
EOF

# ----------------------------
# Generate cpanfile
# ----------------------------
my $cpanfile_text = App::makefilepl2cpanfile::generate(
    makefile => 'Makefile.PL',
    with_develop => 0,  # skip develop for this test
);

# ----------------------------
# Parse Makefile.PL to get expected modules
# ----------------------------
my $content = read_file('Makefile.PL');
my %expected;

for my $key (qw(PREREQ_PM TEST_REQUIRES CONFIGURE_REQUIRES)) {
    while ($content =~ /
        $key \s*=>\s*\{
        ( (?: [^{}] | \{[^}]*\} )*? )
        \}
    /gsx) {
        my $block = $1;
        while ($block =~ /
            ['"]([^'"]+)['"]
            \s*=>\s*
            ['"]?([\d._]+)?['"]?
        /gx) {
            $expected{$1} = $2 // 0;
        }
    }
}

# ----------------------------
# Verify all expected modules appear in the generated cpanfile
# ----------------------------
for my $mod (sort keys %expected) {
    like($cpanfile_text, qr/\b\Q$mod\E\b/, "Module $mod appears in cpanfile");
}

done_testing;
