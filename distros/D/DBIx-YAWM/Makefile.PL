use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'DBIx::YAWM',
    'VERSION_FROM'	=> 'YAWM.pm',
    'ABSTRACT_FROM'	=> 'YAWM.pod',
    'AUTHOR'		=> 'Andrew N. Hicox <andrew@hicox.com>',
    'PREREQ_PM'		=> {
        DBI::DBD				=> 11.02
    }
);
