#$Id: Makefile.PL 1217 2008-02-10 00:06:02Z jimk $
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Data::Presenter',
    'VERSION_FROM'	=> 'lib/Data/Presenter.pm',
    'ABSTRACT_FROM'	=> 'lib/Data/Presenter.pm',
    'PREREQ_PM'		=> { 
        List::Compare           => 0.15,
        IO::Capture             => 0.05,
        IO::Capture::Extended   => 0.09,
        Tie::File               => 0,
    }, 
);

