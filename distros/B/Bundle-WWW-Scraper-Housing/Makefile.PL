use ExtUtils::MakeMaker;
WriteMakefile(
         'NAME'	   => 'Bundle::WWW::Scraper::Housing'
        ,
        ,'ABSTRACT_FROM' => 'lib/Bundle/WWW/Scraper/Housing.pm'
        ,'AUTHOR'        => 'lib/Bundle/WWW/Scraper/Housing.pm'
        ,'PREREQ_PM' => { 'WWW::Scraper' => '2.28'
                       }
        ,'VERSION_FROM'  => 'lib/Bundle/WWW/Scraper/Housing.pm'
);
