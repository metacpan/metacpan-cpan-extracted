use ExtUtils::MakeMaker;

#if (-e "VERSION") { $version = `cat VERSION`; } else { $version = "1.0";}

check_optional($_) for qw(Clone::PP Test::Deep);

WriteMakefile(
    'NAME'         => 'Bio::NEXUS',
    'VERSION_FROM' => 'lib/Bio/NEXUS.pm',
	'PREREQ_PM'    => { 
		# XXX we don't *need* the following releases.
		# WriteMakefile doesn't seem to have a way to
		# indicate optional dependencies, so we'll just
		# ignore them
		#'Clone::PP'  => 1.02, 
		#'Test::Deep' => 0		
		'Test::More' => 0,
	},
    'EXE_FILES' => [ 
		'exec/nexplot.pl',
		'exec/nextool.pl',
		'exec/nex2text_tree.pl'
	],
    'PL_FILES' => {},
    'ABSTRACT' => 'Bio::NEXUS - A NEXUS Application Programming Interface in Perl',
    'AUTHOR'   => 'Hladish, Liang, Qiu, Yang, Gopalan, & Stoltzfus (arlin.stoltzfus@nist.gov)',
   'dist'      => {
		'COMPRESS' => 'gzip', 
		'SUFFIX'   => 'gz'
    },
);

sub check_optional {
	my $class = shift;
	my $path = $class;
	$path =~ s/::/\//g;
	$path .= '.pm';
	eval { require $path };
	if ( $@ ) {
		print STDERR <<"WARNING_NOT_INSTALLED";
*** You don't seem to have $class installed.
This means some functionality won't be
available (though core functionality will be).
		
WARNING_NOT_INSTALLED
		
	}
}
