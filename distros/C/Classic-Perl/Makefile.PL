BEGIN{ require 5; } # use

use ExtUtils::MakeMaker;

open FH, ">Perl.xs" and close FH;


my $dist = 'Classic-Perl';

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'ExtUtils::MakeMaker' => 0,
  'Test::More'          => 0,
 },
 resources => {
  bugtracker => "http://rt.cpan.org/NoAuth/ReportBug.html?Queue=$dist",
  license    => 'http://dev.perl.org/licenses/',
 },
 requires => {
         $]>5.0089999 ? (
          'XSLoader' => 0,
         ) : (),
         $]>5.0130069 ? (
           re        => 0,
         ) : (),
#         $]>5.0150029 ? (
#           'Array::Base' => "0.004",
#           'String::Base' => 0,
#         ) : (),
 }
);

WriteMakefile(
    NAME             => 'Classic::Perl',
    AUTHOR           => 'Father Chrysostomos <sprout at, er, cpan.org>',
    LICENSE          => 'perl',
    VERSION_FROM     => 'lib/Classic/Perl.pm',
#    VERSION          => '0.02a',
#    XS_VERSION       => '0.02',
    ABSTRACT_FROM    => 'lib/Classic/Perl.pm',
    PREREQ_PM        => { map %{$META{$_}}, 'requires','build_requires' },
    MIN_PERL_VERSION => 5,
    META_ADD         => \%META,
    dist             => {
        COMPRESS => 'gzip -9f', SUFFIX => 'gz',
        TAR => 'COPYFILE_DISABLE=1 tar',
    },
    clean            => {
        FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Perl.xs"
    },
);

unlink 'Perl.xs';

use File'Spec'Functions;
sub MY'postamble {
  my $xs_file = catfile("xs", $] < 5.0089999 ? 'old.xs' : 'new.xs');
  <<END;
Perl.xs : $xs_file
	\$(PERLRUN) -MFile::Copy "-ecopy '$xs_file', 'Perl.xs'"
END
}

