#!perl

use strict;
use warnings;
use lib 'lib';

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Test::More;

use ASPEER::MakeMaker::Markdown::Pod::Constant;
use ASPEER::MakeMaker::Markdown::Pod::MM;

plan skip_all => 'pandoc is required for README generation tests'
    unless $PANDOC_EXE;


sub slurp {

    my ($fn)=@_;
    open(my $fh, '<', $fn) || die "unable to open $fn, $!";
    local $/=undef;
    my $text=<$fh>;
    close($fh) || die "unable to close $fn, $!";
    return $text;

}


sub spew {

    my ($fn, $content)=@_;
    open(my $fh, '>', $fn) || die "unable to open $fn, $!";
    print $fh $content;
    close($fh) || die "unable to close $fn, $!";

}


sub run_readme {

    my ($version_from)=@_;
    return ASPEER::MakeMaker::Markdown::Pod::MM::readme(
        undef,
        '',
        '',
        '',
        '',
        '',
        '',
        $version_from,
        '',
        '',
        '',
        '',
        '',
        '',
        '',
    );

}


sub start_fixture {

    my ($cwd)=@_;
    chdir($cwd) || die "unable to chdir $cwd, $!";
    my $temporary_dn=tempdir(CLEANUP => 1);
    chdir($temporary_dn) || die "unable to chdir $temporary_dn, $!";
    make_path('lib/Sample');
    return 'lib/Sample/Readme.pm';

}


my $cwd=getcwd();


#  Preserve an author-supplied plain README when no Markdown README exists
#
my $version_from=start_fixture($cwd);
spew($version_from, "package Sample::Readme;\nour \$VERSION='0.001';\n1;\n");
spew("${version_from}.md", "# NAME\n\nSidecar text that must not replace README\n");
spew('README', "Author supplied plain README\n");
spew('MANIFEST', "README\n${version_from}\n${version_from}.md\n");
run_readme($version_from);
is(slurp('README'), "Author supplied plain README\n",
    'plain README is preserved when README.md is absent');
ok(!-e 'README.md' && !-l 'README.md', 'README.md is not created beside a plain README');


#  Create a regular README.md from a VERSION_FROM sidecar
#
$version_from=start_fixture($cwd);
spew($version_from, "package Sample::Readme;\nour \$VERSION='0.001';\n1;\n");
my $sidecar_md="# NAME\n\nSample::Readme - README generated from sidecar\n";
spew("${version_from}.md", $sidecar_md);
spew('MANIFEST', "${version_from}\n${version_from}.md\n");
run_readme($version_from);
ok(-f 'README.md' && !-l 'README.md', 'regular README.md is created from sidecar markdown');
is(slurp('README.md'), $sidecar_md, 'README.md contains the sidecar markdown');
like(slurp('README'), qr/Sample::Readme - README generated from sidecar/,
    'plain README is rendered from the new README.md');
my $manifest_hr=ExtUtils::Manifest::maniread();
ok(exists $manifest_hr->{'README.md'}, 'README.md is added to MANIFEST');
ok(exists $manifest_hr->{'README'}, 'plain README is added to MANIFEST');
run_readme($version_from);
is(slurp('README.md'), $sidecar_md, 'existing README.md remains the markdown source');
my @readme_md_manifest=grep {/^README\.md(?:\s|$)/} split(/\n/, slurp('MANIFEST'));
is(scalar(@readme_md_manifest), 1,
    'repeated generation does not duplicate README.md in MANIFEST');


#  Create README.md from embedded VERSION_FROM markdown without a sidecar
#
$version_from=start_fixture($cwd);
spew($version_from, <<'PERL_MODULE');
package Sample::Readme;
our $VERSION='0.001';
1;
__END__

=begin markdown

# NAME

Sample::Readme - README generated from embedded markdown

=end markdown
=cut
PERL_MODULE
spew('MANIFEST', "${version_from}\n");
run_readme($version_from);
ok(-f 'README.md' && !-l 'README.md', 'regular README.md is created from embedded markdown');
like(slurp('README.md'), qr/Sample::Readme - README generated from embedded markdown/,
    'README.md contains embedded VERSION_FROM markdown');
ok(!-e "${version_from}.md", 'VERSION_FROM sidecar is not created');


#  Leave the project unchanged when VERSION_FROM has no markdown
#
$version_from=start_fixture($cwd);
spew($version_from, "package Sample::Readme;\nour \$VERSION='0.001';\n1;\n");
spew('MANIFEST', "${version_from}\n");
run_readme($version_from);
ok(!-e 'README.md' && !-l 'README.md', 'README.md is not created without markdown');
ok(!-e 'README' && !-l 'README', 'plain README is not created without markdown');


#  Leave the project unchanged when VERSION_FROM is not configured
#
$version_from=start_fixture($cwd);
spew('MANIFEST', '');
run_readme('');
ok(!-e 'README.md' && !-l 'README.md', 'README.md is not created without VERSION_FROM');
ok(!-e 'README' && !-l 'README', 'plain README is not created without VERSION_FROM');

chdir($cwd) || die "unable to chdir $cwd, $!";
done_testing();
