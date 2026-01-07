use Test::Most;
use File::Temp qw(tempdir);
use File::Slurp qw(write_file);
use App::makefilepl2cpanfile;

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

# Minimal Makefile.PL
write_file 'Makefile.PL', <<'EOF';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Test::Dummy',
    PREREQ_PM => { 'Foo::Bar' => 0 },
);
EOF

# Generate cpanfile with develop deps
my $cpanfile_text = App::makefilepl2cpanfile::generate(
    makefile => 'Makefile.PL',
    with_develop => 1,
);

# Expected default develop modules
my @dev_modules = qw(
    Perl::Critic
    Devel::Cover
    Test::Pod
    Test::Pod::Coverage
);

for my $mod (@dev_modules) {
    like($cpanfile_text, qr/\b\Q$mod\E\b/, "Develop module $mod appears in cpanfile");
}

done_testing;
