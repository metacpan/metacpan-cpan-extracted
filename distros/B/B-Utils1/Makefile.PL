#!perl
use 5.006;
use strict;

my $req_EUDepends = 0.404;
eval { require ExtUtils::Depends; };
if ( $@ or ExtUtils::Depends->VERSION < $req_EUDepends ) {
  warn "ExtUtils::Depends $req_EUDepends is required to maintain this module.\nUsing the packaged helper file.";
} else {
  my $pkg = ExtUtils::Depends->new('B::Utils1');
  $pkg->install('BUtils1.h');
  $pkg->add_xs("Utils1.xs");
  $pkg->add_pm( 'lib/B/Utils1.pm' => '$(INST_LIB)/B/Utils1.pm',
                'lib/B/Utils1/OP.pm' => '$(INST_LIB)/B/Utils1/OP.pm' );
  $pkg->add_typemaps("typemap");
  $pkg->save_config('lib/B/Utils1/Install/IFiles.pm');
}

use ExtUtils::MakeMaker;
WriteMakefile1(
    NAME          => 'B::Utils1',
    VERSION_FROM  => 'lib/B/Utils1.pm',
    PREREQ_PM     => {
        'Scalar::Util' => 0,
        'Exporter'     => 0,
    },
    BUILD_REQUIRES => {
        'ExtUtils::Depends' => 0.404, # DD Sortkeys
        'Test::More' => 0,
    },
    ABSTRACT_FROM => 'lib/B/Utils1.pm',
    AUTHOR        => 'Reini Urban <rurban@cpan.org>',
    LICENSE       => 'perl',
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
      resources => {
        repository => 'http://github.com/rurban/B-Utils1',
        license    => 'http://dev.perl.org/licenses/',
      },
      keywords => ['op tree','perl internals'],
    },
    SIGN          => 1,
    (($^O eq 'hpux') ? () :
     (FUNCLIST => [
	'boot_B__Utils1', #necessary
	qw/BUtils1_cc_opclassname BUtils1_make_sv_object BUtils1_op_name_to_num/, #defined in BUtils1.h
      ])),
);

sub WriteMakefile1 {
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    if ($params{BUILD_REQUIRES}) { #and $eumm_version < 6.5503
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    WriteMakefile(%params);
}

package MY;
use Config;

sub depend {
  "
MANIFEST :
	git ls-tree -r --name-only HEAD >MANIFEST

ppport :
	\$(PERLRUNINST) -MDevel::PPPort -e'Devel::PPPort::WriteFile'

README.md : \$(VERSION_FROM)
	pod2markdown \$(VERSION_FROM) > \$@

release : README.md dist
	test -z \"\$(shell git diff --raw)\" || exit
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

test_cover :: pure_all
	\$(RM_RF) cover_db
	\$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	+\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
