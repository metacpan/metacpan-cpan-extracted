PERL=/usr/bin/perl

all: test

test: test_files
	$(PERL) -MTest::Harness -e'runtests(@ARGV)' t/*.t

clean:
	@rm -f t/*.t

test_files: clean
	$(PERL) t/maketests.pl
