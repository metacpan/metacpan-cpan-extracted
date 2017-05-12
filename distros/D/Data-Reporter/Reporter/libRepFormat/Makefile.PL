use ExtUtils::MakeMaker;
$Verbose = 1;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'libRepFormat',
	'LINKTYPE' 	=> 'static',
	'SKIP'		=> [qw(dynamic test)],
	'H'			=> [qw(RepFormat.h)],
	'C'			=> [qw(RepFormat.c)],
	'OBJECT'	=> q[$(O_FILES)],
	'clean'		=> {'FILES' => 'libRepFormat$(LIB_EXT)'}
);

sub MY::post_constants {
	<<'END'
INST_STATIC = libRepFormat$(LIB_EXT)
END
	;
}

sub MY::top_targets {
	my $top_targets = <<'END';
all	::	static

static	::	libRepFormat$(LIB_EXT)

config	::

test	:

END

	;
	$top_targets;
}
