use ExtUtils::MakeMaker;
use lib 't/lib';
use Apache::test;

my %params = Apache::test->get_test_params();
chomp (my $cwd = `pwd`);
Apache::test->write_httpd_conf
    (%params, 
     include => do {local $/; open FH, 't/config.incl' or die $!; <FH>});
*MY::test = sub { Apache::test->MM_test(%params) };


my $module = 'Apache::SSI';
my ($name, $dir);
($name = $module) =~ s{::}{/}g; $name = "lib/$name.pm";
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $name, # finds $VERSION
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               PREOP=>('rm -f README; '.
                       "pod2text -80 < $name > README; ".
                       "cp -f README $dir-\$(VERSION); "
                      ),
             },
   'clean' => {FILES => "t/httpd.conf t/error_log t/httpd"},
   'PREREQ_PM' => {
		   'Apache::Constants' => '1.00',
		   'HTML::SimpleParse' => '0.06',
		  }
  );
