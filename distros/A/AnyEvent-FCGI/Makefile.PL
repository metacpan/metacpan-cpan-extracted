use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::FCGI',
    VERSION_FROM      => 'lib/AnyEvent/FCGI.pm', # finds $VERSION
    ABSTRACT_FROM     => 'lib/AnyEvent/FCGI.pm', # retrieve abstract from module
    AUTHOR            => 'Vitaly Kramskikh <vkramskih@cpan.org>',
    PREREQ_PM         => {
        'AnyEvent'          => '5.2',
        'Scalar::Util'      => '1.21',
        'Test::More'        => 0
    }
);
