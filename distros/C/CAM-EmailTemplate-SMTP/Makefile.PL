use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::EmailTemplate::SMTP',
              'VERSION_FROM'	=> 'lib/CAM/EmailTemplate/SMTP.pm',
              'PREREQ_PM'		=> {
                 'CAM::EmailTemplate'       => '0.90',
                 'Net::SMTP'                => '1.03',
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/EmailTemplate/SMTP.pm',
                AUTHOR     => 'Clotho Advanced Media <cpan@clotho.com>') : ()),
              );
