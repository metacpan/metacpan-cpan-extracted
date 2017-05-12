use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(NAME         => 'CGI::Application::Plugin::RateLimit',
              VERSION_FROM => 'RateLimit.pm',
              PREREQ_PM    => {
                            'CGI::Application' => '4',
                            'Class::Accessor'  => '0.25',
                            'Test::More'       => '0',
                           },);
