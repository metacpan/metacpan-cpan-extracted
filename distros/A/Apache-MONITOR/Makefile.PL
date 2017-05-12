use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $ap = 'lib/Apache/MONITOR.pm';
WriteMakefile(
    'NAME'		=> 'Apache::MONITOR',
    'VERSION_FROM'	=> $ap,
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
);


 
#WriteMakefile(
#              'NAME'    => 'Apache::UploadSvr',
#              'VERSION_FROM' => $upl,
#              'PREREQ_PM' => {
#                              Apache::Stage => 0,
#                              LWP => 0,
#                             },
#             test => { TESTS => "/dev/null" },
#              dist => {
#                       PREOP => "co -l README && pod2text $upl > README && ci -u README",
#                      }
#);
