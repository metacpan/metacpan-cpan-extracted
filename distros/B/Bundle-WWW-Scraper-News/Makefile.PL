use ExtUtils::MakeMaker;
WriteMakefile(
         'NAME'	   => 'Bundle::WWW::Scraper::News'
        ,
        ,'ABSTRACT_FROM' => 'lib/Bundle/WWW/Scraper/News.pm'
        ,'AUTHOR'        => 'lib/Bundle/WWW/Scraper/News.pm'
        ,'PREREQ_PM' => { 'WWW::Scraper' => '3.02'
                       }
        ,'VERSION_FROM'  => 'lib/Bundle/WWW/Scraper/News.pm'
);
