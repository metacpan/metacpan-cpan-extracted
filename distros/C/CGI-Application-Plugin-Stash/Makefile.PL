use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'CGI::Application::Plugin::Stash',
    VERSION_FROM      => 'lib/CGI/Application/Plugin/Stash.pm',
    PREREQ_PM         => {
        CGI::Application => '3.31'
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/CGI/Application/Plugin/Stash.pm',
       AUTHOR         => 'Masahiro Nagano <kazeburo@gmail.com>') : ()),
);
