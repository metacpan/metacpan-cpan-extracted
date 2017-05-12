use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Array::OneOf',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Array::OneOf -- checks if an element is in an array',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Array/OneOf.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {}
             };


WriteMakefile(%$make_args);
