use strict;
use warnings FATAL => 'all';
use lib 'lib';
use Apache::SWIT::Maker::Makefile;

Apache::SWIT::Maker::Makefile->new({ no_swit_overrides => 1, overrides => {
postamble => sub { return q{

APACHE_TEST_FILES = t/apache/*.t
test :: test_apache

t/templates/2mb.tt :: Makefile
	perl -e 'print "<html><body>" . ("x" x (2048 * 64)) . " [% hello %] </body></html>"' > t/templates/2mb.tt

t/conf/extra.conf.in :: t/conf/extra.conf.part blib/lib/Apache/SWIT/Maker.pm
	perl -I blib/lib -MApache::SWIT::Maker \
		-e 'print Apache::SWIT::Maker->gen_conf_header' > t/conf/extra.conf.in
	cat t/conf/extra.conf.part >> t/conf/extra.conf.in

t/conf/mime.types ::
	ln -sf /etc/mime.types t/conf

t/public_html/hello.xhtml ::
	ln -sf `pwd`/t/public_html/hello.html t/public_html/hello.xhtml

t/public_html/hello.svg ::
	ln -sf `pwd`/t/public_html/hello.html t/public_html/hello.svg

test_apache :: pure_all t/templates/2mb.tt t/conf/extra.conf.in t/conf/mime.types \
			t/public_html/hello.xhtml t/public_html/hello.svg
	$(RM_F) t/logs/access_log  t/logs/error_log
	ulimit -c unlimited && PERL_DL_NONLAZY=1 $(FULLPERLRUN) -I t/ t/apache_test.pl $(APACHE_TEST_FILES)

realclean ::
	$(RM_RF) t/htdocs t/logs t/templates/2mb.tt
	$(RM_F) t/conf/apache_test_config.pm  t/conf/modperl_inc.pl
	$(RM_F) t/conf/extra.conf t/conf/httpd.conf t/conf/modperl_startup.pl
	$(RM_RF) blib/conf
}}, } })->write_makefile(
    NAME         => 'Apache::SWIT',
    VERSION_FROM => 'lib/Apache/SWIT.pm', # finds $VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'mod_perl server with integrated testing',
    EXE_FILES    => [ 'scripts/swit_init' ],
    PREREQ_PM    => { 'Test::Simple' => 0.44, 'Apache::Test' => '',
	'WWW::Mechanize' => '', 'Template' => '', 'HTML::Tested' => '0.48',
	'ExtUtils::ModuleMaker' => '', 'HTML::Tested::ClassDBI' => '0.21',
	'Apache2::Request' => '', 'Class::Accessor' => '', YAML => '',
	'Apache2::Cookie' => '', 'DBIx::VersionedSchema' => '0.03',
	'Test::TempDatabase' => '0.16', 'Class::DBI::Pg::More' => '0.04',
	'Class::DBI' => '', 'Class::DBI::Pg' => '0.09', 'File::Slurp' => '',
	'IPC::Run' => '', 'HTML::Tested::JavaScript' => '0.13'
	, 'Package::Alias' => '', 'Linux::Unshare' => ''
	, 'Queue::Worker' => '', 'IO::CaptureOutput' => ''
	, 'Linux::Smaps' => '', 'Devel::NYTProf' => ''
    },
);

