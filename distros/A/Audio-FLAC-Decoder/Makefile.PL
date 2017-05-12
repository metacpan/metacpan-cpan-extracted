use ExtUtils::MakeMaker;
use Config;

$LDDLFLAGS = '';
$LDDLFLAGS = '-all_load' if $^O eq 'darwin';
$LDDLFLAGS = '-L/usr/pkg/lib' if $^O eq 'netbsd';

if ($^O =~ /win32/i) {
        $LIBS = '-lFLAC_static';
} else {
        $LIBS = '-lFLAC';
}

WriteMakefile(
	'NAME'		=> 'Audio::FLAC::Decoder',
	'VERSION_FROM'	=> 'Decoder.pm',
	'LIBS'		=> [$LIBS],
	'DEFINE'	=> '-O',
	'LDDLFLAGS'	=> "$Config{'lddlflags'} $LDDLFLAGS",
	 MYEXTLIB	=> 'libflacsupport$(LIB_EXT)',
);

sub MY::postamble {

	if ($^O =~ /win32/i) {

return '$(MYEXTLIB): $(O_FILES)
	$(AR) -nologo -out:$(MYEXTLIB) $(O_FILES)
	$(RANLIB) $@';

	} else {

return '$(MYEXTLIB): $(MYEXTLIB)($(O_FILES))
	$(AR) cr $@ $?
	$(RANLIB) $@';

	}

}
