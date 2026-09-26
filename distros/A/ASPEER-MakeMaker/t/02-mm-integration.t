#!perl

use strict;
use warnings;
use lib 'lib';

use Config;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More qw(no_plan);

use ASPEER::MakeMaker::MM::Util ();


#  Read and write test fixture files
#
sub slurp {

    my ($fn)=@_;
    open(my $input_fh, '<', $fn) || die("unable to open $fn, $!");
    local $/=undef;
    my $text=<$input_fh>;
    close($input_fh) || die("unable to close $fn, $!");
    return $text;

}


sub blurp_test {

    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) || die("unable to open $fn, $!");
    print $output_fh $text;
    close($output_fh) || die("unable to close $fn, $!");
    return 1;

}


#  Module loading must not modify the caller's default variable
#
my $common_lib_dn=abs_path('lib');
is(
    system(
        $^X,
        "-I$common_lib_dn",
        '-e',
        '$_=q(caller value); require ASPEER::MakeMaker; exit($_ eq q(caller value) ? 0 : 1)'
    ),
    0,
    'loading module preserves caller default variable'
);


#  Create a disposable MakeMaker distribution
#
my $cwd=getcwd();
my $temporary_dn=tempdir(CLEANUP => 1);
chdir($temporary_dn) || die("unable to chdir $temporary_dn, $!");
make_path('lib', 'bin', 'local lib');
my $local_lib_dn=abs_path('local lib');

blurp_test('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sample',
    VERSION_FROM => 'lib/Sample.pm',
    EXE_FILES    => ['bin/sample.pl'],
    LICENSE      => 'perl',
    AUTHOR       => 'Andrew Speer',
    depend       => {'generated.out' => 'generated.in'},
);
MAKEFILE_PL
blurp_test('lib/Sample.pm', "package Sample;\nour \$VERSION='0.001';\n1;\n");
blurp_test('lib/Sample.pm.md', "# Sample\n");
blurp_test('lib/Sample.pm.new', "temporary\n");
blurp_test('lib/Sample.pm.1', "temporary\n");
blurp_test('bin/sample.pl', "#!perl\nour \$VERSION='0.001';\nprint qq(sample\\n);\n");
blurp_test('LICENSE', "Sample license\n");
blurp_test('MANIFEST', <<'MANIFEST');
Makefile.PL
LICENSE
bin/sample.pl
lib/Sample.pm
lib/Sample.pm.md
lib/Sample.pm.new
lib/Sample.pm.1
MANIFEST


#  Create disposable Git provenance when Git is available
#
my $git_sha='';
if (system('git', 'init', '-q')==0) {
    system('git', 'add', '.')==0 || die("unable to add Git fixtures, $!");
    system(
        'git',
        '-c', 'user.name=Local ExtUtils Common Test',
        '-c', 'user.email=test@example.invalid',
        'commit', '-qm', 'test fixture'
    )==0 || die("unable to commit Git fixtures, $!");
    $git_sha=qx(git rev-parse --short HEAD);
    chomp($git_sha);
}


#  Generate the Makefile through command-line activation
#
local $ENV{'PERL5LIB'}=join(
    $Config{'path_sep'},
    grep {defined($_) && length($_)} ($common_lib_dn, $ENV{'PERL5LIB'})
);
is(system($^X, "-I$local_lib_dn", '-MASPEER::MakeMaker', 'Makefile.PL'), 0,
    'Makefile.PL succeeds with command-line import');
my $makefile=slurp('Makefile');
like($makefile, qr/^PERLRUN\s*=.*-MASPEER::MakeMaker/m,
    'global PERLRUN reloads the MakeMaker integration');
like($makefile, qr/^PERLRUN\s*=.*-MExtUtils::MakeMaker/m,
    'global PERLRUN retains loaded MakeMaker modules');
like($makefile, qr/(?:'-I[^']*local lib'|"-I[^"]*local lib")/,
    'global PERLRUN quotes include paths containing spaces');
like($makefile, qr/^Makefile\s*:\s*\$\(VERSION_FROM\)$/m,
    'Makefile depends on VERSION_FROM');
like($makefile, qr/^generated\.out\s*:\s*generated\.in$/m,
    'existing Makefile dependencies are retained');
like($makefile,
    qr/^ASPEER_MAKEMAKER_PM_TARGET=\$\(PERLRUN\) -M\$\(ASPEER_MAKEMAKER_PM\).*\s-e\s/m,
    'target command explicitly reloads its dispatch module');
like($makefile,
    qr/^\s*\@\$\(ASPEER_MAKEMAKER_PM_TARGET\) util_sync \$\(UPDATE_SOURCE_UTIL_FN\)$/m,
    'util_sync target passes its method explicitly');
unlike($makefile, qr/^MM_PREFIX\s*=/m,
    'private macro prefix configuration is not emitted');
my ($perlrun)=($makefile=~/^(PERLRUN\s*=.*)$/m);
my @common_import=($perlrun=~/-MASPEER::MakeMaker(?==|\s|$)/g);
is(scalar(@common_import), 1,
    'global PERLRUN contains the active extension once');
unlike($makefile, qr/(?:gherkin|foobar|serfin)/,
    'generated Makefile contains no demonstration targets');
like($makefile, qr/^EXE_FILES\s*=\s*bin\/sample\.pl$/m,
    'executable retains its declared filename');
ok(!-e 'bin/sample', 'extensionless executable is not created implicitly');
unlike($makefile, qr/lib\/Sample\.pm\.(?:md|new|1)\s+blib\//,
    'documentation and temporary sidecars are excluded from install map');
like($makefile, qr/'LICENSE'\s+'\$\(INST_LIBDIR\)/,
    'license file is included in install map');
like(slurp('MYMETA.json'), qr/"license"\s*:\s*\[/,
    'license metadata is generated');
my $make=$Config{'make'} || 'make';
is(system($make, 'dump_param'), 0,
    'generated method-dispatch target executes successfully');

if (length($git_sha)) {
    is(slurp('lib/Sample.pm.sha'), "$git_sha\n",
        'Git-SHA provenance is generated');
    like($makefile, qr/lib\/Sample\.pm\.sha/,
        'Git-SHA provenance is included in install map');
    utime(1000000000, 1000000000, 'lib/Sample.pm.sha') ||
        die("unable to set Git-SHA fixture timestamp, $!");
    is(system($^X, "-I$local_lib_dn", '-MASPEER::MakeMaker', 'Makefile.PL'), 0,
        'Makefile.PL can be regenerated');
    is((stat('lib/Sample.pm.sha'))[9], 1000000000,
        'unchanged Git-SHA provenance is not rewritten');
}
else {
    ok(!-e 'lib/Sample.pm.sha', 'Git-SHA generation is skipped without Git');
    pass('Git-SHA install-map test skipped without Git');
    pass('Git-SHA regeneration test skipped without Git');
    pass('Git-SHA rewrite test skipped without Git');
}


#  Embedded activation remains compatible and idempotent
#
my $makefile_pl=slurp('Makefile.PL');
my $embedded_import=<<'EMBEDDED_IMPORT';
eval {
    require ASPEER::MakeMaker;
    ASPEER::MakeMaker->import();
    1;
};

EMBEDDED_IMPORT
$makefile_pl=~s/(use ExtUtils::MakeMaker;\n)/$1$embedded_import/ ||
    die('unable to add embedded import to Makefile.PL');
blurp_test('Makefile.PL', $makefile_pl);
is(system($^X, 'Makefile.PL'), 0,
    'Makefile.PL succeeds with embedded activation');
$makefile=slurp('Makefile');
my @util_sync_target=($makefile=~/^util_sync ::\s*$/mg);
is(scalar(@util_sync_target), 1, 'embedded activation generates one util_sync target');
is(system($^X, '-MASPEER::MakeMaker', 'Makefile.PL'), 0,
    'command-line and embedded activation succeed together');
$makefile=slurp('Makefile');
@util_sync_target=($makefile=~/^util_sync ::\s*$/mg);
is(scalar(@util_sync_target), 1, 'combined activation generates one util_sync target');


#  Executable provenance is installed as data, not another executable
#
blurp_test('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sample',
    VERSION_FROM => 'bin/sample.pl',
    EXE_FILES    => ['bin/sample.pl'],
);
MAKEFILE_PL
is(system($^X, '-MASPEER::MakeMaker', 'Makefile.PL'), 0,
    'minimal Makefile.PL succeeds without LICENSE or AUTHOR');
$makefile=slurp('Makefile');
like($makefile, qr/^EXE_FILES\s*=\s*bin\/sample\.pl$/m,
    'executable Git-SHA sidecar is not treated as an executable');
if (length($git_sha)) {
    is(slurp('bin/sample.pl.sha'), "$git_sha\n",
        'executable Git-SHA provenance is generated');
    like($makefile,
        qr/'bin\/sample\.pl\.sha'\s+'\$\(INST_SCRIPT\)\/sample\.pl\.sha'/,
        'executable Git-SHA provenance is mapped into INST_SCRIPT');
    is(system($make, 'pure_all'), 0, 'executable Git-SHA provenance is copied');
    is(slurp('blib/script/sample.pl.sha'), "$git_sha\n",
        'installed executable Git-SHA provenance retains its content');
}
else {
    ok(!-e 'bin/sample.pl.sha', 'executable Git-SHA generation is skipped without Git');
    pass('executable Git-SHA install-map test skipped without Git');
    pass('executable Git-SHA copy test skipped without Git');
    pass('installed executable Git-SHA content test skipped without Git');
}


#  Missing VERSION_FROM must not create a root sidecar
#
blurp_test('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME    => 'Sample',
    VERSION => '0.001',
);
MAKEFILE_PL
is(system($^X, '-MASPEER::MakeMaker', 'Makefile.PL'), 0,
    'Makefile.PL succeeds without VERSION_FROM');
ok(!-e '.sha', 'Git-SHA provenance is not created without VERSION_FROM');

chdir($cwd) || die("unable to chdir $cwd, $!");


#  File writes must report both data and close failures
#
{
    no warnings qw(redefine);
    local *IO::File::new=sub {bless({}, 'Local::FailingWrite')};
    my $write_ok=eval {
        ASPEER::MakeMaker::MM::Util::blurp('ignored', 'text');
        1;
    };
    ok(!$write_ok, 'file write failure is fatal');
}
{
    no warnings qw(redefine);
    local *IO::File::new=sub {bless({}, 'Local::FailingClose')};
    my $close_ok=eval {
        ASPEER::MakeMaker::MM::Util::blurp('ignored', 'text');
        1;
    };
    ok(!$close_ok, 'file close failure is fatal');
}


package Local::FailingWrite;

sub print {return 0}
sub close {return 1}


package Local::FailingClose;

sub print {return 1}
sub close {return 0}
