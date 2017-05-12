use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'B::Deobfuscate',
    'VERSION_FROM' => 'lib/B/Deobfuscate.pm',
    'PREREQ_PM'    => {
        'B::Keywords' => '1.04',
        'YAML'        => '0'
    },
    'ABSTRACT_FROM' => 'lib/B/Deobfuscate.pod',
    'AUTHOR'        => 'Joshua ben Jore <jjore@cpan.org>',
);
