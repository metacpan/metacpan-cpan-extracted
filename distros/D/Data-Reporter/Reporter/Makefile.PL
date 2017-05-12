use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
push my(@extralibs), "-lm" unless $^O eq 'MSWin32';

WriteMakefile(
    'NAME'	=> 'Data::Reporter::RepFormat',
    'VERSION_FROM' => 'RepFormat.pm', # finds $VERSION
	'MYEXTLIB' => 'libRepFormat/libRepFormat$(LIB_EXT)',
    'LIBS'	=> [@extralibs],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);

sub MY::postamble {
	my $postamble = <<'END';
$(MYEXTLIB):	libRepFormat/Makefile
END

	$postamble .= ($^O eq 'MSWin32') ? <<'END1' : <<'END2';
	cd libRepFormat && $(MAKE) all DEFINE=$(DEFINE)
END1
	cd libRepFormat && $(MAKE) -e all
END2

	$postamble;
}
