use strict;
use warnings;
use lib ();
use Cwd qw( abs_path );
use File::Temp qw/ tempdir /;
use File::Spec;
use FindBin qw/$Bin/;
use Catalyst::Devel;
use Catalyst::Helper;
use Test::More;
use Config;

eval "use IPC::Run3";
plan skip_all => 'These tests require IPC::Run3' if $@;

my $share_dir = abs_path('share');
plan skip_all => "No share dir at $share_dir!"
    unless -d $share_dir;

$ENV{CATALYST_DEVEL_SHAREDIR} = $share_dir;
my $instdir = tempdir(CLEANUP => 1);

$ENV{PERL_MM_OPT} = "INSTALL_BASE=$instdir";
$ENV{INSTALL_BASE} = $instdir;
if ($ENV{MAKEFLAGS}) {
    $ENV{MAKEFLAGS} =~ s/PREFIX=[^\s]+//;
    $ENV{MAKEFLAGS} =~ s/INSTALL_BASE=[^\s]+//;
}

my $dir = tempdir(CLEANUP => 1);
my $devnull = File::Spec->devnull;

diag "Generated app is in $dir";

chdir $dir or die "Cannot chdir to $dir: $!";

{
    open my $fh, '>', $devnull or die "Cannot write to $devnull: $!";

    local *STDOUT = $fh;

    my $helper = Catalyst::Helper->new(
        {
            name => 'TestApp',
        }
    );

    $helper->mk_app('TestApp');
}

my $app_dir = File::Spec->catdir($dir, 'TestApp');
chdir($app_dir) or die "Cannot chdir to $app_dir: $!";
lib->import(File::Spec->catdir($dir, 'TestApp', 'lib'));

my @files = qw|
    Makefile.PL
    testapp.conf
    testapp.psgi
    lib/TestApp.pm
    lib/TestApp/Controller/Root.pm
    README
    Changes
    t/01app.t
    t/02pod.t
    t/03podcoverage.t
    root/static/images/catalyst_logo.png
    root/static/images/btn_120x50_built.png
    root/static/images/btn_120x50_built_shadow.png
    root/static/images/btn_120x50_powered.png
    root/static/images/btn_120x50_powered_shadow.png
    root/static/images/btn_88x31_built.png
    root/static/images/btn_88x31_built_shadow.png
    root/static/images/btn_88x31_powered.png
    root/static/images/btn_88x31_powered_shadow.png
    root/favicon.ico
    Makefile.PL
    script/testapp_cgi.pl
    script/testapp_fastcgi.pl
    script/testapp_server.pl
    script/testapp_test.pl
    script/testapp_create.pl
|;

foreach my $fn (map { File::Spec->catdir(@$_) } map { [ File::Spec::Unix->splitdir($_) ] } @files) {
    test_fn($fn);
}
create_ok($_, 'My' . $_) for qw/Model View Controller/;

command_ok( [ $^X, 'Makefile.PL' ] );
ok -e "Makefile", "Makefile generated";
#NOTE: do not assume that 'make' is always 'make' as e.g. Win32/strawberry perl uses 'dmake'
command_ok( [ ($Config{make} || 'make') ] );

run_generated_component_tests();

my $server_script_file = File::Spec->catdir(qw/script testapp_server.pl/);
my $server_script = do {
    open(my $fh, '<', $server_script_file) or fail $!;
    local $/;
    <$fh>;
};

ok $server_script;
ok $server_script =~ qr/CATALYST_SCRIPT_GEN}\s+=\s+(\d+)/,
    'SCRIPT_GEN found in generated output';
is $1, $Catalyst::Devel::CATALYST_SCRIPT_GEN, 'Script gen correct';

{
    open(my $fh, '>', $server_script_file) or fail $!;
    print $fh "MOO\n";
}
my $helper = Catalyst::Helper->new(
    {
        '.newfiles' => 0,
        'makefile'  => 0,
        'scripts'   => 1,
        name => '.',
    }
);
$helper->mk_app( '.' ) or fail;

my $server_script_new = do {
    open(my $fh, '<', $server_script_file) or fail $!;
    local $/;
    <$fh>;
};

is $server_script, $server_script_new;

diag "Installed app is in $instdir";
command_ok( [ ($Config{make} || 'make', 'install') ] );

my $inst_app_dir = File::Spec->catdir($instdir);
chdir($inst_app_dir) or die "Cannot chdir to $inst_app_dir: $!";
lib->import(File::Spec->catdir($instdir, 'lib', 'perl5'));

my @installed_files = qw|
    lib/perl5/TestApp.pm
    lib/perl5/TestApp/testapp.conf
    lib/perl5/TestApp/Controller/Root.pm
    lib/perl5/TestApp/root/static/images/catalyst_logo.png
    lib/perl5/TestApp/root/static/images/btn_120x50_built.png
    lib/perl5/TestApp/root/static/images/btn_120x50_built_shadow.png
    lib/perl5/TestApp/root/static/images/btn_120x50_powered.png
    lib/perl5/TestApp/root/static/images/btn_120x50_powered_shadow.png
    lib/perl5/TestApp/root/static/images/btn_88x31_built.png
    lib/perl5/TestApp/root/static/images/btn_88x31_built_shadow.png
    lib/perl5/TestApp/root/static/images/btn_88x31_powered.png
    lib/perl5/TestApp/root/static/images/btn_88x31_powered_shadow.png
    lib/perl5/TestApp/root/favicon.ico
    bin/testapp_cgi.pl
    bin/testapp_fastcgi.pl
    bin/testapp_server.pl
    bin/testapp_test.pl
    bin/testapp_create.pl
|;

foreach my $fn (map { File::Spec->catdir(@$_) } map { [ File::Spec::Unix->splitdir($_) ] } @installed_files) {
    my $ffn = File::Spec->catfile($inst_app_dir, $fn);
    ok -r $ffn, "'$fn' installed in correct location";
}

chdir('/');
done_testing;

sub command_ok {
    my $cmd = shift;
    my $desc = shift;

    my $stdout;
    my $stderr;
    run3( $cmd, \undef, \$stdout, \$stderr );

    $desc ||= "Exit status ok for '@{$cmd}'";
    unless ( is $? >> 8, 0, $desc ) {
        diag "STDOUT:\n$stdout" if defined $stdout;
        diag "STDERR:\n$stderr" if defined $stderr;
    }
}

sub runperl {
    my $comment = pop @_;
    command_ok( [ $^X, '-I', File::Spec->catdir($Bin, '..', 'lib'), @_ ], $comment );
}

my @generated_component_tests;

sub test_fn {
    my $fn = shift;
    ok -r $fn, "Have $fn in generated app";
    if ($fn =~ /script/) {
        SKIP: {
            skip 'Executable file flag test does not make sense on Win32', 1 if ($^O eq 'MSWin32');
            ok -x $fn, "$fn is executable";
       }
    }
    if ($fn =~ /\.p[ml]$/) {
        runperl( '-c', $fn, "$fn compiles" );
    }
    # Save these till later as Catalyst::Test will only be loaded once :-/
    push @generated_component_tests, $fn
        if $fn =~ /\.t$/;
}

sub run_generated_component_tests {
    local $ENV{TEST_POD} = 1;
    local $ENV{CATALYST_DEBUG} = 0;
    foreach my $fn (@generated_component_tests) {
        subtest "Generated app test: $fn", sub {
            do $fn;
        };
    }
}

sub create_ok {
    my ($type, $name) = @_;
    runperl( File::Spec->catdir('script', 'testapp_create.pl'), $type, $name,
        "'script/testapp_create.pl $type $name' ok");
    test_fn(File::Spec->catdir('t', sprintf("%s_%s.t", lc $type, $name)));
}
