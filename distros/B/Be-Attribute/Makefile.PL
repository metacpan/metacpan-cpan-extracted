use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@mm=(
    'NAME'	=> 'Be::Attribute',
    'VERSION_FROM' => 'Attribute.pm', # finds $VERSION
    'LIBS'	=> ['-lbe -lroot'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'CC'	=> 'g++',
    'LD'	=> 'g++',
#    'XS'	=> { 'Attribute.xs' => 'Attribute.cpp' },
    'XSOPT'	=> '-C++',
#    'xs_cpp'	=> 'Attribute.xs',
);

die "OS unsupported" unless $^O eq "BeOS";

WriteMakefile(@mm);
