use ExtUtils::MakeMaker;
WriteMakefile(
         'NAME'	   => 'Bundle::WWW::Scraper::Job'
        ,
        ,'ABSTRACT_FROM' => 'lib/Bundle/WWW/Scraper/Job.pm'
        ,'AUTHOR'        => 'lib/Bundle/WWW/Scraper/Job.pm'
        ,'PREREQ_PM' => { 'WWW::Scraper' => '3.01'
                       }
        ,'VERSION_FROM'  => 'lib/Bundle/WWW/Scraper/Job.pm'
);
