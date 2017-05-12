use ExtUtils::MakeMaker;

WriteMakefile( NAME         => "CGI::Wiki::Formatter::Pod",
               VERSION_FROM => "lib/CGI/Wiki/Formatter/Pod.pm",
               PREREQ_PM    => { 'IO::Scalar'      => 0,
				 'Pod::Tree' => '1.10' # for link map
                               }
             );
