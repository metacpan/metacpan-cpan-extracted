use ExtUtils::MakeMaker;
WriteMakefile
  (
   'NAME'		=> 'B::Flags',
   'VERSION_FROM'	=> 'Flags.pm',
   'AUTHOR'             => 'Simon Cozens <simon@cpan.org>, Reini Urban <rurban@cpan.org>',
   'ABSTRACT_FROM'      => 'Flags.pm',
   'SIGN'               => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       license     => 'http://dev.perl.org/licenses/',
       repository  => 'http://github.com/rurban/b-flags',
      },
     }
    ) : ()),
  );

package MY;

sub depend { "
README : Flags.pm
	pod2text Flags.pm > README
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

gcov : \$(BASEEXT).c.gcov cover_db/\$(BASEEXT)-xs.html
\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs
cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover
";
}

