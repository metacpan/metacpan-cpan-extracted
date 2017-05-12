use strict;
use ExtUtils::MakeMaker;
use lib 't/lib';  # distributed here until changes are incorporated into the real version
use Apache::test qw(have_httpd);

my %params = Apache::test->get_test_params();
Apache::test->write_httpd_conf
    (%params,
     include => do {local $/; open FH, 't/config.incl'; <FH>});
*MY::test = sub { Apache::test->MM_test(%params) } if have_httpd();

my $module = 'Apache::Filter';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'	=> $module,
   'VERSION_FROM' => "lib/Apache/$name", # finds $VERSION
   'dist' => { COMPRESS=>"gzip", 
	       SUFFIX=>"gz", 
               PREOP=>('rm -f README; '.
                       "pod2text -80 < $name > README; ".
                       "cp -f README $dir-\$(VERSION); "
                      ),
             },
   'PL_FILES' => {},
   'clean' => {FILES => "t/httpd t/httpd.conf t/error_log"},
   'PREREQ_PM' => {
                   'mod_perl' => '1.24_01',
		  },
  );
