use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CGI::Prototype',
    VERSION_FROM      => 'lib/CGI/Prototype.pm',
    PREREQ_PM         => {
			  'Template' => 0,
			  'Class::Prototyped' => 0,
			 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/CGI/Prototype.pm',
       AUTHOR         => 'Randal L. Schwartz <merlyn@stonehenge.com>') : ()),
);
