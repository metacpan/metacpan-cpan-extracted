use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$headers  = "../acelib/wh";

WriteMakefile(
	      'NAME'	     => 'Ace::RPC',
	      'VERSION_FROM' => 'RPC.pm', # finds $VERSION
	      'DEFINE'	     => '',
	      'MYEXTLIB'     => '../acelib/libaceperl.a',
	      'LIBS'         => ['-lc'],
	      'OBJECT'       => '$(O_FILES)',
	      'XSPROTOARG'   => '-noprototypes',
	      'XS'           => { 'RPC.xs'  => 'RPC.c' },
	      'INC'	     => "-I$headers",
);

sub MY::postamble {
    my $definition = guess_definition();
    warn "Using $definition definitions to build ace library.\n";
"
\$(MYEXTLIB): ../acelib/Makefile
	cd ../acelib && \$(MAKE) ACEDB_MACHINE=$definition all
";
}

sub guess_definition {
    return $ENV{ACEDB_MACHINE} if $ENV{ACEDB_MACHINE};
    return uc $Config{osname};
}

