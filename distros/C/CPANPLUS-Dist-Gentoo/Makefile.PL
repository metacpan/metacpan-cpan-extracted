use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'CPANPLUS-Dist-Gentoo';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Carp'              => 0,
 'CPANPLUS'          => 0,
 'Cwd'               => 0,
 'List::Util'        => 0,
 'File::Copy'        => 0,
 'File::Path'        => 0,
 'File::Spec'        => 0,
 'IPC::Cmd'          => 0,
 'Parse::CPAN::Meta' => 0,
 'Scalar::Util'      => 0,
 'base'              => 0,
);

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
  %PREREQ_PM,
 },
 dynamic_config => 0,
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => 5.006,
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 },
);

package MY;

sub postamble {
 <<POSTAMBLE
regen:
	\$(PERL) samples/gengentooisms
POSTAMBLE
}
