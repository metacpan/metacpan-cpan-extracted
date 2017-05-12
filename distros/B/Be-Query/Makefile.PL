use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
@mm=(
    'NAME'	=> 'Be::Query',
    'VERSION_FROM' => 'Query.pm', # finds $VERSION
    'LIBS'	=> ['-lbe -lroot'],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'CC'	=> 'g++',
    'LD'	=> 'g++',
#    'XS'	=> { 'Query.xs' => 'Query.cpp' },
    'XSOPT'	=> '-C++',
#    'xs_cpp'	=> 'Query.xs',
);

die "OS unsupported" unless $^O eq "BeOS";

WriteMakefile(@mm);
