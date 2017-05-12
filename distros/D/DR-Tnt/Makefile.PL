use 5.010000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DR::Tnt',
    VERSION_FROM      => 'lib/DR/Tnt.pm',
    PREREQ_PM         => {
        'AnyEvent'              => 0,
        'Carp'                  => 0,
        'Coro'                  => 0,
        'Data::Dumper'          => 0,
        'Digest::SHA'           => 0,
#        'DR::Msgpuck'           => 0,
        'File::Spec::Functions' => 0,
        'File::Temp'            => 0,
        'IO::Socket::INET'      => 0,
        'IO::Socket::UNIX'      => 0,
        'List::MoreUtils'       => 0,
        'MIME::Base64'          => 0,
        'Mouse'                 => 0,
        'Scalar::Util'          => 0,
        'Time::HiRes'           => 0,
    },

    test    => {
        RECURSIVE_TEST_FILES    => 1,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/DR/Tnt.pm',
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
