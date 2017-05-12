use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DR::Tarantool',
    VERSION_FROM      => 'lib/DR/Tarantool.pm', # finds $VERSION
    PREREQ_PM         => {
            'Carp'                          => 0,
            'File::Temp'                    => 0,
            'File::Path'                    => 0,
            'File::Spec::Functions'         => 0,
            'Cwd'                           => 0,
            'IO::Socket::INET'              => 0,
            'AnyEvent'                      => 0,
            'Devel::GlobalDestruction'      => 0,
            'JSON::XS'                      => 0,
            'List::MoreUtils'               => 0,
    }, # e.g., Module::Name => 1.1
    META_MERGE => {
        resources => {
            homepage   => 'https://github.com/dr-co/dr-tarantool',
            repository => 'https://github.com/dr-co/dr-tarantool',
            bugtracker => 'https://github.com/dr-co/dr-tarantool/issues',
        }
    },
    ABSTRACT_FROM  => 'lib/DR/Tarantool.pm', # retrieve abstract from module
    AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>',
    LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    LICENSE           => 'artistic',
);

# if (open my $fh, '>>', 'Makefile') {
#     print $fh "\n\nTEST_VERBOSE=1\n";
# }
