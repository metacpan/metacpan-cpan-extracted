use ExtUtils::MakeMaker;
use Config;

if($ENV{RELEASE_TESTING}) {
    opendir(T, 't') || die("Can't read t/ directory: $!\n");
    my @tests = grep { -f "t/$_" } readdir(T);
    closedir(T);
    foreach my $test (@tests) {
        open(IN, "t/$test") || die("Can't read t/$test: $!\n");
        open(OUT, ">t/XX-$test") || die("Can't write t/XX-$test: $!\n");
        print OUT "use Devel::Hide qw(LWP::Protocol::https);\n";
        print OUT <IN>;
        close(OUT);
        close(IN);
    }
}

WriteMakefile(
  NAME         => 'CPAN::FindDependencies',
  META_MERGE => {
    license => 'open_source',
    resources => {
      repository => 'https://github.com/DrHyde/perl-modules-CPAN-FindDependencies',
      bugtracker => 'https://github.com/DrHyde/perl-modules-CPAN-FindDependencies/issues'
    },
  },
  VERSION_FROM => 'lib/CPAN/FindDependencies.pm',
  EXE_FILES    => [qw(
    examples/cpandeps
  )],
  PREREQ_PM    => {
    'Parse::CPAN::Packages' => 2.31,
    'Module::CoreList'      => 2.90,
    'YAML::Tiny'            => 1.57,
    'LWP::UserAgent'        => 0,
    'Scalar::Util'          => 1.14,
    'URI::file'             => 4.13,
    'File::Temp'            => 0.19,
    'Capture::Tiny'         => 0.05,
    'Devel::CheckOS'        => 1.52,
    $^O eq 'MSWin32' ? ('Win32::Job' => 0,) : (),
  },
  dist => {
    DIST_CP => 'cp',
    PREOP => "$Config{perlpath} -Mstrict -w shared/doincludes \$(EXE_FILES) \$(TO_INST_PM)"
  }
);

# commented out cos doesn't work on Doze
# package MY;
# sub test {
#     my $text = shift->SUPER::test(@_);
#     $text =~ s/\t(.*test_harness)/\tHARNESS_OPTIONS=j8 $1/;
#     $text;
# }
