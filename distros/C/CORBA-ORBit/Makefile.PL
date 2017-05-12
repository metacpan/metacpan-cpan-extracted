use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

@OBJECTS = qw(ORBit.o
	      client.o
	      demarshal.o 
	      errors.o
              extras.o
	      exttypes.o
              idl.o
	      interfaces.o 
	      marshal.o
              server.o
	      types.o);

$orbit_cflags = `orbit-config --cflags client server`;
undef $orbit_cflags if $?;
$orbit_libs = `orbit-config --libs client server`;
undef $orbit_libs if $?;

if (!defined $orbit_libs) {
    print STDERR "orbit-config not found\n";
    exit 1;
}

if ($] < 5.0045) {
    print STDERR "Using compatibility macros/routines for Perl 5.004\n";
    push @OBJECTS,'constsub.o';
}

WriteMakefile(
    'NAME'	=> 'CORBA::ORBit',
    'VERSION_FROM' => 'ORBit.pm',
    'LIBS'	=> [$orbit_libs." -lIDL"],
    'DEFINE'	=> 
        ($] < 5.0045         ? '-DPERL5004_COMPAT ' : ''),
    'INC'	=> $orbit_cflags,
    'OBJECT'    => join(" ", @OBJECTS),
#    'XSOPT'     => '-nolinenumbers',
    'OPTIMIZE'  => '-g -Wall',
#    'OPTIMIZE'  => '-O2 -Wall',
    'MAP_TARGET' => 'orbitperl',
#    'MAKEAPERL' => 1,
    'dist'      => { COMPRESS=>"gzip", SUFFIX=>"gz" },
);
