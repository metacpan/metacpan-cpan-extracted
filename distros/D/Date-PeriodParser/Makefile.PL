use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Date::PeriodParser',
    'VERSION_FROM'	=> 'lib/Date/PeriodParser.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        "Lingua::EN::Words2Nums" => 0,
        "Date::Calc" => 0,
        "POSIX" => 0,
        }, # e.g., Module::Name => 1.1
	    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	    clean               => { FILES => 'Date-PeriodParser-*' },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Date/PeriodParser.pm', # retrieve abstract from module
       AUTHOR     => 'Joe McMahon <mcmahon@cpan.org>') : ()),
);
