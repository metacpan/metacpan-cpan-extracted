use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing" if $@;

my $tests = 8;
my $HAVE_LP = 0;
eval "use Lexical::Persistence 1.01 ()";
if ( !$@ ) {
    $HAVE_LP = 1;
    $tests++;
}
my $HAVE_MR = 0;
eval "use Module::Refresh";
if ( !$@ ) {
    $HAVE_MR = 1;
    $tests++;
}

plan tests => $tests;
pod_coverage_ok("App::PerlShell");
pod_coverage_ok("App::PerlShell::Config");
if ( $HAVE_LP ) {
    pod_coverage_ok("App::PerlShell::LexPersist");
}
if ( $HAVE_MR ) {
    pod_coverage_ok("App::PerlShell::ModRefresh");
}
pod_coverage_ok("App::PerlShell::Plugin::File");
pod_coverage_ok("App::PerlShell::Plugin::Gnuplot");
pod_coverage_ok("App::PerlShell::Plugin::Macros");
pod_coverage_ok("App::PerlShell::Plugin::ShellCommands");
pod_coverage_ok("App::PerlShell::Plugin::TextCSV");
pod_coverage_ok("App::PerlShell::Plugin::TextTable");
