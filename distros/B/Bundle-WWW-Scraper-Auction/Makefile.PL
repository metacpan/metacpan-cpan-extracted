use ExtUtils::MakeMaker;
WriteMakefile(
         'NAME'	   => 'Bundle::WWW::Scraper::Auction'
        ,
        ,'ABSTRACT_FROM' => 'lib/Bundle/WWW/Scraper/Auction.pm'
        ,'AUTHOR'        => 'lib/Bundle/WWW/Scraper/Auction.pm'
        ,'PREREQ_PM' => { 'WWW::Scraper' => '3.01'
                       }
        ,'VERSION_FROM'  => 'lib/Bundle/WWW/Scraper/Auction.pm'
);
