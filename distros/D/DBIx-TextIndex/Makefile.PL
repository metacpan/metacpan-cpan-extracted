require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'DBIx::TextIndex',
    'VERSION_FROM' => 'lib/DBIx/TextIndex.pm',
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
                         'Bit::Vector'      => 6.3,
			 'DBI'              => 1.43,
			 'HTML::Entities'   => 1.22,
			 'Exception::Class' => 1.12,
                         'Text::Balanced'   => 1.83,
                      },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/TextIndex.pm',
       AUTHOR         => 'Daniel Koch <dkoch@cpan.org>') : ()),
);

