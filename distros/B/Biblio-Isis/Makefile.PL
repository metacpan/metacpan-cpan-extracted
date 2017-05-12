use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME => 'Biblio::Isis',
	VERSION_FROM => 'lib/Biblio/Isis.pm', # finds $VERSION
	AUTHOR => 'Dobrica Pavlinusic (dpavlin@rot13.org)',
	ABSTRACT_FROM => 'lib/Biblio/Isis.pm',
	PREREQ_PM => {
		'Test::More' => 0,
		'Carp' => 0,
		'File::Glob' => 0,
		'File::Spec' => 0,
	},
	depend => {
		dist => 'changelog',
	},
);

sub MY::postamble {
	return <<'MAKE_MORE';

HTML_DIR=pod2html

html: $(TO_INST_PM)
	test -e $(HTML_DIR) && rm -Rf $(HTML_DIR) || true
	mkdir $(HTML_DIR)
	allpod2xhtml.pl lib/ $(HTML_DIR)
	test ! -z "`which svn2html.pl`" && svn update && svn2html.pl > $(HTML_DIR)/Changes.html

changelog:
	svk update && svk -v log > Changes

tags:
	ctags *.p? */*.p?

cmp:
	time ./scripts/dump_isis.pl > isis.txt
	time ./scripts/dump_openisis.pl > openisis.txt

bench:	all
	cd ./scripts/ && ./bench.pl

cpan:
	make clean
	rm -f Biblio-Isis-*.tar.gz
	perl Makefile.PL
	make changelog
	make dist
	make disttest
	@echo
	@echo -n "Upload" Biblio-Isis-*.tar.gz "to CPAN? [y/N]:"
	@read upload && test "$$upload" == "y" && cpan-upload -verbose Biblio-Isis-*.tar.gz
MAKE_MORE
}
