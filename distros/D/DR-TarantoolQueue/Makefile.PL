use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'DR::TarantoolQueue',
    VERSION_FROM      => 'lib/DR/TarantoolQueue.pm', # finds $VERSION
    PREREQ_PM         => {
            'Carp'                          => 0,
            'Mouse'                         => 0,
#             'DR::Tarantool'                 => 0,
            'DR::Tnt'                       => 0,
            'Coro'                          => 0,
            'JSON::XS'                      => 0,
            'List::MoreUtils'               => 0,
            'MIME::Base64'                  => 0,
            'Compress::Zlib'                => 0,
    },
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/dr-co/tarantool-queue',
            repository => 'https://github.com/dr-co/tarantool-queue',
            bugtracker => 'https://github.com/dr-co/tarantool-queue/issues',
        }
    },
    test    => {
        RECURSIVE_TEST_FILES    => 1,
    },
    ABSTRACT_FROM  => 'lib/DR/TarantoolQueue.pm',
    AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>',
    LICENSE           => 'perl',
);

# open my $file, '>>', 'Makefile';
# print $file "\n\nTEST_VERBOSE = 1\n";
