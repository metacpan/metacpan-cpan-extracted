use ExtUtils::MakeMaker;
WriteMakefile (
    AUTHOR        => 'Nathan Wiger (nate@wiger.org)',
    NAME          => 'Catalyst::Plugin::FormBuilder',
    VERSION_FROM  => 'lib/Catalyst/Plugin/FormBuilder.pm', # finds $VERSION
    PREREQ_PM     => {
        'CGI::FormBuilder'  => '3.02',
        'Catalyst::Runtime' => '5.7',
    }
);
