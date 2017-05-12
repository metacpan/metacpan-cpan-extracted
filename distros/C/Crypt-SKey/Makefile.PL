use strict;
use ExtUtils::MakeMaker;

my %have;
foreach my $mod (qw(Digest::MD4 Digest::MD5 Term::ReadKey)) {
  eval "use $mod";
  $have{$mod} = not $@;
}

unless ($have{'Digest::MD4'} or $have{'Digest::MD5'}) {
  die("This module requires either Digest::MD4 or Digest::MD5 for proper operation.\n".
      "See the documentation for more details.\n");
}
unless ($have{'Term::ReadKey'}) {
  warn("This module recommends installing Term::ReadKey for full functionality.\n".
       "See the documentation for more details.\n");
}


my $module = 'Crypt::SKey';
my ($file, $dir);
($file = $module) =~ s/::/\//g;
$file = "lib/$file.pm";
($dir = $module) =~ s/::/-/g;

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
   PL_FILES => {},
  );
