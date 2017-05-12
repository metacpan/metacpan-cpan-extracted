use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTTPD::Bench::ApacheBench',
    'VERSION_FROM' => 'lib/HTTPD/Bench/ApacheBench.pm', # finds $VERSION
    'PREREQ_PM' => { Net::HTTP => 0 },
    'DIR' => ['src'],
);
