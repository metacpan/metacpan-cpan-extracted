use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CGI::Prototype::Mecha',
    VERSION_FROM      => 'lib/CGI/Prototype/Mecha.pm',
    PREREQ_PM         => {
			  'CGI::Prototype' => 0.9051,
			  'WWW::Mechanize' => 0,
			  'File::Temp' => 0,
			  'LWP' => 5.803, # apparently some older versions break Mecha
			 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/CGI/Prototype/Mecha.pm',
       AUTHOR         => 'Randal L. Schwartz <merlyn@stonehenge.com>') : ()),
);
