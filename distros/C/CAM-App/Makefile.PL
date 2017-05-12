use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'		=> 'CAM::App',
              'VERSION_FROM'	=> 'lib/CAM/App.pm',
              'PREREQ_PM'		=> {
                 'CGI'                      => '2.00',
                 'CAM::Template'            => '0.76',
                 'Test::More'               => '0.01',

                 ## Optional
                 #'CGI::Cookie'              => '1.00',
                 #'CGI::Compress::Gzip'      => '0.11',
                 #'DBI'                      => '1.10',
                 #'CAM::Session'             => '0.01',
                 #'CAM::SQLManager'          => '0.01',
                 #'CAM::SQLObject'           => '0.01',
                 #'CAM::EmailTemplate'       => '0.15',
                 #'CAM::EmailTemplate::SMTP' => '0.20',
                 #'CAM::Template::Cache'     => '0.11',
              },
              'PL_FILES'        => {},
              ($] >= 5.005 ?
               (ABSTRACT_FROM => 'lib/CAM/App.pm',
                AUTHOR     => 'Clotho Advanced Media Inc., <cpan@clotho.com>') : ()),
              );
