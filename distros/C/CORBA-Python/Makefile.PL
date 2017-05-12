use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::Python',
    'VERSION_FROM'  => 'lib/CORBA/Python.pm',
    'ABSTRACT'      => 'IDL compiler to Python mapping',
    'PREREQ_PM'     => {
                        'CORBA::IDL'    => 2.60,
                        'CORBA::C'      => 2.60,
    },
    'INSTALLDIRS'   => 'site',
    'EXE_FILES'     => [
                        'bin/idl2py',
                        'bin/idl2pycli',
                        'bin/idl2pysrv',
                        'bin/idl2pyemb',
                        'bin/idl2pyext',
    ],
    'C'             => [],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

sub MY::install {
    package MY;
    my $script = shift->SUPER::install(@_);
    $script =~ s/install :: (.*)$/install :: $1 install_pyidl/m;
    $script .= <<"INSTALL";

install_pyidl :
\t\@python setup.py install

INSTALL

    return $script;
}

