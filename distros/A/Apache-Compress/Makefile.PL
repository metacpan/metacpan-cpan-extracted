use ExtUtils::MakeMaker;
use lib 't/lib';  # distributed here until changes are incorporated into the real version
use Apache::test;

my %params = Apache::test->get_test_params();
chomp (my $cwd = `pwd`);
Apache::test->write_httpd_conf
    (%params,
     include => do {local $/; <DATA>});
*MY::test = sub { Apache::test->MM_test(%params) };

my $module = 'Apache::Compress';
my ($name, $dir);
($name = $module) =~ s/.*::(\w+)/$1.pm/;
($dir = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'	=> $module,
   'VERSION_FROM' => $name, # finds $VERSION
   'dist' => { COMPRESS=>"gzip", 
	       SUFFIX=>"gz", 
               PREOP=>('rm -f Changes README; '.
                       "cvs log $name | \$(PERL) -MCVS::Parse -e prettylog > Changes; ".
                       "pod2text -80 < $name > README; ".
                       "cp -f Changes README $dir-\$(VERSION); "
                      ),
             },
   'PREREQ_PM' => {
                   'Compress::Zlib' => '1.08',
                  },
   'PL_FILES' => {},
   'clean' => {FILES => 't/httpd t/httpd.conf t/error_log'},
  );

__DATA__

PerlModule Apache::Compress
<FilesMatch "\.html$">
 SetHandler perl-script
 PerlHandler Apache::Compress
</FilesMatch>
