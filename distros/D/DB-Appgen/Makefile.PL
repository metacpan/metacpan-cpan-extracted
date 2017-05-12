use ExtUtils::MakeMaker;
#######################################################################################
# Put your appgen library here (see README for details)
#
my $appgenlibdir='appgen-libs';
#
# That's all you need to change.
#######################################################################################
if(! -x $appgenlibdir || ! -r "$appgenlibdir/libappgen_appl.a"
                      || ! -r "$appgenlibdir/libappgen_strings.a"
                      || ! -r "$appgenlibdir/libappgen.a") {
    print <<EOT;
You did not set up APPGEN library correctly. Please read the README file
and follow instructions. The following files must exist:

$appgenlibdir/libappgen_appl.a
$appgenlibdir/libappgen_strings.a
$appgenlibdir/libappgen.a

EOT
    die "Cannot continue without proper APPGEN libraries\n";
}

WriteMakefile(
    'NAME'              => 'DB::Appgen',
    'ABSTRACT'          => 'Perl interface for APPGEN Custom Suite databases',
    'AUTHOR'            => 'Andrew Maltsev',
    'VERSION_FROM'      => 'Appgen.pm',
    'PREREQ_PM'         => {
        Error => 0.13,
    },
    'LIBS'              => [
        '-L' . $appgenlibdir .
        ' -lappgen_appl -lappgen -lappgen_strings' .
        ' -lncurses',
    ],
    'DEFINE'            => '',
    'INC'               => '',
    'MYEXTLIB'          => 'aglib/libappgen$(LIB_EXT)',
    'clean'             => {
        'FILES' => 'test.db'
    },
);

sub MY::postamble
{ <<'EOT';
$(MYEXTLIB): aglib/Makefile
	cd aglib && $(MAKE) $(PASSTHRU)
EOT
}
