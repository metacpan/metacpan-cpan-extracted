
use ExtUtils::MakeMaker;

unless (eval "use Scalar::Util; 1") {
  warn("You seem not to have the Scalar::Util module installed.\n" .
       "Its installation is recommended (but not required) for Class::Container - see the README.\n");
  sleep 4;
}

my $module = 'Class::Container';
my ($file, $dir);
($file = "lib/$module.pm") =~ s{::}{/}g;
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $file, # finds $VERSION
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               PREOP=>('rm -f README; '.
                       "pod2text -80 < $file > README; ".
                       "cp -f README $dir-\$(VERSION); "
                      ),
             },
   'PREREQ_PM' => {
		   Params::Validate => '0.23',
		  },
   'PL_FILES' => {},
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $file, # retrieve abstract from module
     AUTHOR     => 'Ken Williams <ken@mathforum.org>') : 
    ()
   ),
   NO_META => 1,
  );

