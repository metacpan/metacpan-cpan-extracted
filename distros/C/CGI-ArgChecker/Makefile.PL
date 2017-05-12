use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'CGI::ArgChecker',
    'VERSION_FROM' => 'ArgChecker.pm',
    'PREREQ_PM'    => { 'String::Checker' => 0.01 },
);
