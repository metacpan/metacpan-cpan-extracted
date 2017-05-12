use ExtUtils::MakeMaker;

# array_each() needs a prototype of (\[@%]); that was introduced in 5.8
use 5.008;

my $eumm_version = eval $ExtUtils::MakeMaker::VERSION;

my $module_file = 'lib/Array/Each/Override.pm';
WriteMakefile(
    NAME          => 'Array::Each::Override',
    AUTHOR        => 'Aaron Crane <arc@cpan.org>',
    ABSTRACT_FROM => $module_file,
    VERSION_FROM  => $module_file,
    OBJECT        => 'Override.o',
    PREREQ_PM     => {
        Scalar::Util => 0,
    },
    $eumm_version < 6.3002 ? () : (
        LICENSE => 'perl',
    ),
    $eumm_version < 6.46 ? () : (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/arc/array-each-override.git',
                    web  => 'https://github.com/arc/array-each-override',
                },
            },
        },
    ),
);
