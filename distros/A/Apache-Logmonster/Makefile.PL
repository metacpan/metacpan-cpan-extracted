use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use lib 'lib';

sub MY::postamble 
{

'LOGMONSTER = /Users/Shared/Sites/www.tnpi.net/internet/www/logmonster

docs:
	pod2text bin/logmonster.pl         > README
	pod2text doc/FAQ.pod               > FAQ
	pod2text doc/Changes.pod           > Changes
 
web:
	install -m 0644 bin/logmonster.pl $(LOGMONSTER)/logmonster.pl
	install -m 0644 logmonster.conf   $(LOGMONSTER)/logmonster.conf
	install -m 0644 doc/Changes.html  $(LOGMONSTER)/changes.html
	install -m 0644 doc/FAQ.html      $(LOGMONSTER)/faq.html
	install -m 0644 doc/README.html   $(LOGMONSTER)/README.html
	cp Apache-Logmonster-$(VERSION).tar.gz $(LOGMONSTER)/Logmonster.tar.gz
	mv Apache-Logmonster-$(VERSION).tar.gz $(LOGMONSTER)/Apache-Logmonster.tar.gz

conf:
	install -d /usr/local
	install -d /usr/local/etc
	install -m 0644 logmonster.conf /usr/local/etc/logmonster.conf-dist

newconf:
	install -d /usr/local
	install -d /usr/local/etc
	install -m 0644 logmonster.conf /usr/local/etc/logmonster.conf

deps:
	perl bin/install_deps.pl

';

};

WriteMakefile(
	'NAME'	           => 'Apache::Logmonster',
	'AUTHOR'           => 'Matt Simerson (msimerson@cpan.org)',
	'ABSTRACT'         => 'Apache log utility for merging, sorting, and processing web logs',
	'EXE_FILES'        => [ 'bin/logmonster.pl' ],
	'INSTALLSCRIPT'    => '/usr/local/sbin',
	'LICENSE'	       => 'bsd',
    'MIN_PERL_VERSION' => 5.008001,
	'VERSION_FROM'     => 'lib/Apache/Logmonster.pm',
	'PREREQ_PM'        => {
                            'Params::Validate'   => .8,
                            'Compress::Zlib'     => 2, 
                            'Date::Parse'        => 2,
                            'Regexp::Log'        => .04,
                            'Mail::Send'         => 0,
                            'URI'                => 1,
                            'LWP'                => 0,
                          },
    'TEST_REQUIRES'    => {
                          'Test::Pod'          => 0,
                          'Test::Pod::Coverage'=> 0,
                          },
    'BUILD_REQUIRES'   => {
                          'Test::Pod'          => 0,
                          'Test::Pod::Coverage'=> 0,
                          },
	 clean             => {
                            FILES => [  "t/trash",
                                        "t/tmp_*",
                                     ],
                          },
);

