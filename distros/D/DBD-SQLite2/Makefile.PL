eval {
    require DBI;
    require DBI::DBD;
    die "Too old" unless $DBI::VERSION >= 1.03;
};
use ExtUtils::MakeMaker;
use Config;
use strict;

WriteMakefile(
    'NAME'          => 'DBD::SQLite2',
    'VERSION_FROM'  => 'lib/DBD/SQLite2.pm', # finds $VERSION
    'PREREQ_PM'     => {
      DBI => 1.625,
     },
    'OBJECT'        => '$(O_FILES)',
    'INC'           => '-I$(DBI_INSTARCH_DIR)',
    'OPTIMIZE'      => $Config{optimize} . (($^O eq 'solaris' and !$Config{gccversion}) ? "" : " -O2"),
    'DEFINE'        => "-DNDEBUG=1 -DSQLITE_PTR_SZ=$Config{ptrsize}" .
                       ($Config{d_usleep} ? " -DHAVE_USLEEP=1" : ""),
    'clean'         => { FILES => 'SQLite2.xsi config.h' },
    'ABSTRACT_FROM'  =>  'lib/DBD/SQLite2.pm',
    'AUTHOR'         => 'Matt Sergeant <matt@sergeant.org>',
  ($ExtUtils::MakeMaker::VERSION ge '6.52' ?
   ('CONFIGURE_REQUIRES' => {DBI => 1.625}) : ()),
  ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
   ('LICENSE'     => 'perl',
    'META_MERGE'  =>
    {"recommends" =>
     {
       'DBD::SQLite'  => '1.37',
       'DBI'          => '1.625',
     },
     resources =>
     {       
	license     => 'http://dev.perl.org/licenses/',
         repository  => 'https://github.com/rurban/DBD-SQLite2',
     },
    }
   ) : ()),
  SIGN  => 1
);

package MY;
sub postamble { 
  DBI::DBD::dbd_postamble(@_);
}
sub libscan {
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
}

sub depend {
  "
release : dist
	echo git commit -a -m\"release \$(VERSION)\"
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

test_cover :: pure_all
	\$(RM_RF) cover_db
	\$(PERLRUNINST) -S cover -test
test_coveralls :: pure_all
	\$(PERLRUNINST) -S cover -test -report coveralls

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
