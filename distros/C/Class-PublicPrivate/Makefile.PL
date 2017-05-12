use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Class::PublicPrivate',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Class::PublicPrivate - Class with public keys with any name and a separate set of private keys',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Class/PublicPrivate.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {}
             };


WriteMakefile(%$make_args);
