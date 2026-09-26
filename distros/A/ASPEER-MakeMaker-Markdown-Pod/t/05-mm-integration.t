#!perl

use strict;
use warnings;
use lib 'lib';

use Config;
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;

use Markdown::Pod::Embed;
use ASPEER::MakeMaker::Markdown::Pod::MM;


#  Read and write test fixture files
#
sub slurp {

    my ($fn)=@_;
    open(my $input_fh, '<', $fn) || die "unable to open $fn, $!";
    local $/=undef;
    my $text=<$input_fh>;
    close($input_fh) || die "unable to close $fn, $!";
    return $text;

}


sub blurp {

    my ($fn, $text)=@_;
    open(my $output_fh, '>', $fn) || die "unable to open $fn, $!";
    print $output_fh $text;
    close($output_fh) || die "unable to close $fn, $!";
    return 1;

}


#  Locate both distributions before entering the disposable project
#
my $cwd=getcwd();
my $extutils_lib_dn=abs_path('lib');
my $common_pm_fn=abs_path($INC{'ASPEER/MakeMaker/MM.pm'});
$common_pm_fn=~s{[/\\]ASPEER[/\\]MakeMaker[/\\]MM\.pm$}{};
my $embed_pm_fn=abs_path($INC{'Markdown/Pod/Embed.pm'});
$embed_pm_fn=~s{[/\\]Markdown[/\\]Pod[/\\]Embed\.pm$}{};
my $temporary_dn=tempdir(CLEANUP => 1);
chdir($temporary_dn) || die "unable to chdir $temporary_dn, $!";
make_path('lib', 'bin', 'doc', 'local lib/Docbook/Convert');
my $local_lib_dn=abs_path('local lib');


#  Create a minimal MakeMaker distribution with a Markdown sidecar
#
blurp('Makefile.PL', <<'MAKEFILE_PL');
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
blurp('lib/Sample.pm', "package Sample;\nour \$VERSION='0.001';\n1;\n");
blurp('lib/Sample.pm.md', "# NAME\n\nSample - generated documentation\n");
blurp('bin/sample.pl', "#!perl\nour \$VERSION='0.001';\nprint qq(sample\\n);\n");
blurp('doc/guide.xml', "<?xml version=\"1.0\"?>\n<article><title>Guide</title></article>\n");
blurp('local lib/Docbook/Convert/Pandoc.pm', <<'PANDOC_STUB');
package Docbook::Convert::Pandoc;
sub new {return bless({}, shift())}
sub convert_articles {
    my ($self, $root_dn)=@_;
    die "unexpected document root\n" unless $root_dn eq 'doc';
    open(my $output_fh, '>', 'doc/guide.md') || die "unable to open output: $!";
    print {$output_fh} "# Guide\n" || die "unable to write output: $!";
    close($output_fh) || die "unable to close output: $!";
    return ['doc/guide.md'];
}
1;
PANDOC_STUB
blurp('LICENSE', "Sample license\n");
blurp('MANIFEST', "Makefile.PL\nLICENSE\nbin/sample.pl\nlib/Sample.pm\nlib/Sample.pm.md\n");


#  Create disposable Git provenance when Git is available
#
my $git_sha='';
if (system('git', 'init', '-q')==0) {
    system('git', 'add', '.')==0 || die "unable to add Git fixtures, $!";
    system(
        'git',
        '-c', 'user.name=ExtUtils Markdown Pod Test',
        '-c', 'user.email=test@example.invalid',
        'commit', '-qm', 'test fixture'
    )==0 || die "unable to commit Git fixtures, $!";
    $git_sha=qx(git rev-parse --short HEAD);
    chomp($git_sha);
}


#  Generate the Makefile using the two checkout libraries
#
local $ENV{'PERL5LIB'}=join(
    $Config{'path_sep'},
    grep {defined($_) && length($_)}
        ($extutils_lib_dn, $common_pm_fn, $embed_pm_fn, $ENV{'PERL5LIB'})
);
is(system($^X, "-I$local_lib_dn", '-MASPEER::MakeMaker::Markdown::Pod', 'Makefile.PL'), 0,
    'Makefile.PL succeeds with command-line import');
my $makefile=slurp('Makefile');
like($makefile, qr/^PERLRUN\s*=.*-MASPEER::MakeMaker::Markdown::Pod/m,
    'global PERLRUN reloads the MakeMaker integration');
like($makefile, qr/^PERLRUN\s*=.*-MExtUtils::MakeMaker/m,
    'global PERLRUN retains loaded MakeMaker modules');
like($makefile, qr/^Makefile\s*:\s*\$\(VERSION_FROM\)$/m,
    'Makefile depends on VERSION_FROM');
like($makefile, qr/^generated\.out\s*:\s*generated\.in$/m,
    'existing Makefile dependencies are retained');
like($makefile, qr/(?:'-I[^']*local lib'|"-I[^"]*local lib")/,
    'global PERLRUN quotes include paths containing spaces');
like($makefile, qr/^doc :: readme$/m, 'doc target generated');
like($makefile, qr/^readme ::$/m, 'readme target generated');
like($makefile,
    qr/^MARKPOD_PM_TARGET=\$\(PERLRUN\) -M\$\(MARKPOD_PM\).*\s-e\s/m,
    'target command explicitly reloads its dispatch module');
unlike($makefile, qr/^MM_PREFIX\s*=/m,
    'private macro prefix configuration is not emitted');
like($makefile, qr/^\s*\@\$\(MARKPOD_PM_TARGET\) doc$/m,
    'doc target passes its method explicitly');
like($makefile, qr/^LICENSE\s*=\s*perl$/m, 'license macro generated');
like(slurp('MYMETA.json'), qr/"license"\s*:\s*\[/,
    'license metadata generated');
like($makefile, qr/^EXE_FILES\s*=\s*bin\/sample\.pl$/m,
    'executable retains its declared filename');
ok(!-e 'bin/sample', 'extensionless executable is not created implicitly');
unlike($makefile, qr/lib\/Sample\.pm\.md\s+blib\//,
    'Markdown sidecar excluded from install map');
like($makefile, qr/'LICENSE'\s+'\$\(INST_LIBDIR\)/,
    'license file included in install map');
if (length($git_sha)) {
    is(slurp('lib/Sample.pm.sha'), "$git_sha\n", 'Git-SHA provenance generated');
    like($makefile, qr/lib\/Sample\.pm\.sha/, 'Git-SHA provenance included in install map');
    utime(1000000000, 1000000000, 'lib/Sample.pm.sha') ||
        die "unable to set Git-SHA fixture timestamp, $!";
}
else {
    ok(!-e 'lib/Sample.pm.sha', 'Git-SHA generation skipped outside a checkout');
    pass('Git-SHA install-map test skipped outside a checkout');
}


#  Exercise the generated target rather than calling its implementation directly
#
my $make=$Config{'make'} || 'make';
is(system($make, 'doc'), 0, 'generated doc target succeeds');
like(slurp('lib/Sample.pm'), qr/^=head1 NAME$/m,
    'generated target delegates Markdown conversion');
is(slurp('doc/guide.md'), "# Guide\n",
    'generated target converts article XML absent from MANIFEST');


#  Regenerate with optional integration declared inside Makefile.PL
#
my $embedded_import=<<'EMBEDDED_IMPORT';
eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};

EMBEDDED_IMPORT
my $makefile_pl=slurp('Makefile.PL');
$makefile_pl=~s/(use ExtUtils::MakeMaker;\n)/$1$embedded_import/ ||
    die 'unable to add embedded import to Makefile.PL';
blurp('Makefile.PL', $makefile_pl);

is(system($^X, 'Makefile.PL'), 0,
    'Makefile.PL succeeds with embedded optional import');
$makefile=slurp('Makefile');
like($makefile, qr/^PERLRUN\s*=.*-MASPEER::MakeMaker::Markdown::Pod/m,
    'embedded import installs the full integration');
my @doc_target=($makefile=~/^doc :: readme$/mg);
is(scalar(@doc_target), 1, 'embedded import generates one doc target');
if (length($git_sha)) {
    is((stat('lib/Sample.pm.sha'))[9], 1000000000,
        'unchanged Git-SHA provenance is not rewritten');
}
else {
    pass('Git-SHA rewrite test skipped outside a checkout');
}


#  Command-line and embedded activation together remain idempotent
#
is(system($^X, '-MASPEER::MakeMaker::Markdown::Pod', 'Makefile.PL'), 0,
    'combined command-line and embedded activation succeeds');
$makefile=slurp('Makefile');
@doc_target=($makefile=~/^doc :: readme$/mg);
is(scalar(@doc_target), 1, 'combined activation generates one doc target');


#  Install executable Git provenance as data rather than as another executable
#
blurp('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sample',
    VERSION_FROM => 'bin/sample.pl',
    EXE_FILES    => ['bin/sample.pl'],
    LICENSE      => 'perl',
    AUTHOR       => 'Andrew Speer',
);
MAKEFILE_PL
is(system($^X, '-MASPEER::MakeMaker::Markdown::Pod', 'Makefile.PL'), 0,
    'Makefile.PL succeeds with executable VERSION_FROM');
$makefile=slurp('Makefile');
like($makefile, qr/^EXE_FILES\s*=\s*bin\/sample\.pl$/m,
    'Git-SHA sidecar is not treated as an executable');
if (length($git_sha)) {
    is(slurp('bin/sample.pl.sha'), "$git_sha\n",
        'executable Git-SHA provenance generated');
    like($makefile,
        qr/'bin\/sample\.pl\.sha'\s+'\$\(INST_SCRIPT\)\/sample\.pl\.sha'/,
        'executable Git-SHA provenance mapped into INST_SCRIPT');
    is(system($make, 'pure_all'), 0, 'executable Git-SHA provenance copied');
    is(slurp('blib/script/sample.pl.sha'), "$git_sha\n",
        'installed executable Git-SHA provenance retains its content');
}
else {
    ok(!-e 'bin/sample.pl.sha',
        'executable Git-SHA generation skipped outside a checkout');
    pass('executable Git-SHA install-map test skipped outside a checkout');
    pass('executable Git-SHA copy test skipped outside a checkout');
    pass('installed executable Git-SHA content test skipped outside a checkout');
}


#  A distribution without VERSION_FROM must not create a root .sha file
#
blurp('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME    => 'Sample',
    VERSION => '0.001',
    LICENSE => 'perl',
    AUTHOR  => 'Andrew Speer',
);
MAKEFILE_PL
is(system($^X, '-MASPEER::MakeMaker::Markdown::Pod', 'Makefile.PL'), 0,
    'Makefile.PL succeeds without VERSION_FROM');
ok(!-e '.sha', 'Git-SHA provenance is not created without VERSION_FROM');


#  The documented minimal configuration does not require metadata fields
#
blurp('Makefile.PL', <<'MAKEFILE_PL');
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sample',
    VERSION_FROM => 'lib/Sample.pm',
);
MAKEFILE_PL
is(system($^X, '-MASPEER::MakeMaker::Markdown::Pod', 'Makefile.PL'), 0,
    'minimal Makefile.PL succeeds without LICENSE or AUTHOR');
$makefile=slurp('Makefile');
like($makefile, qr/^doc :: readme$/m,
    'minimal Makefile.PL retains documentation targets');

chdir($cwd) || die "unable to chdir $cwd, $!";


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

done_testing();


package Local::FailingWrite;

sub print {return 0}
sub close {return 1}


package Local::FailingClose;

sub print {return 1}
sub close {return 0}
