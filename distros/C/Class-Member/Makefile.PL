use 5.008_000;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Member',
    'VERSION_FROM'	=> 'lib/Class/Member.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PMLIBDIRS'		=> ['lib'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Class/Member.pm', # retrieve abstract from module
       AUTHOR     => 'Torsten Förtsch <Torsten.Foertsch@gmx.net>') : ()),
    dist              => {
			PREOP => './mk_README.sh',
		       },
);

sub MY::postamble {
  return <<'EOF';
COMPRESS = gzip -9f

README: lib/Class/Member.pm mk_README.sh
	./mk_README.sh

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Class-Member.spec
	rpmbuild -ba perl-Class-Member.spec
EOF
}
