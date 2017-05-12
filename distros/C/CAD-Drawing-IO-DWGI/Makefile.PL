use Inline::MakeMaker;
BEGIN {
	use File::Find;
	use Getopt::Long;
	my $ad_init = '/usr/local/stow/openDWG/adinit/adinit.dat';
	(-e $ad_init) or undef($ad_init);
	GetOptions(
		"help" => sub {usage()},
		"adinit=s" => \$ad_init,
		);
	sub usage {
		print "usage: perl $0 [--help], [--adinit <initfile>]\n";
		exit;
	}
	if($ad_init and not (-e $ad_init)) {
		die "no such file '$ad_init'\n";
	}

	unless($ad_init and (-e $ad_init)) {
		print "searching your hard-drive for adinit.dat ...\n";
		foreach my $dir ("/usr/", "/home/") {
			find(
			sub {
				if($_ eq "adinit.dat") {
					($File::Find::name =~ m#/ptc/#) && next;
					$ad_init = $File::Find::name;
					last;	
				}
			}, $dir);
			$ad_init && last;
		}
		$ad_init or die "could not find any adinit.dat file\n\t";
		print "found $ad_init\n";
	}
	# always make the change?
	open(FUNC, "lib/CAD/Drawing/IO/DWGI/functions.c") or
		die "cannot read functions.c!";
	my @file = <FUNC>;
	my $okay;
	my $changed = 1;
	foreach my $line (@file) {
		# XXX really need to get here sooner instead of searching my own drive.
		if($line =~ s/(const char initfilepath\[\]=")(.*?)";/$1$ad_init";/) {
			if(my $f = $2) {
				if($f eq $ad_init) {
					warn "no changes need\n";
					$okay = 800;
					$changed = 0;
					last;
				}
			}
			$okay++;
			last;
		}
	}
	$okay or die "failed to insert initfilename\n";
	if($changed) {
		open(FUNC, ">lib/CAD/Drawing/IO/DWGI/functions.c") or
			die "cannot write functions.c!";
		print FUNC @file;
		close(FUNC);
	}
}
unless(-e 'DWGI.pm') {
	# what's this "make dependency" about?
	#my $h;
	#open($h, '>DWGI.inl');
	symlink('lib/CAD/Drawing/IO/DWGI.pm', 'DWGI.pm');
}

WriteMakefile(
	'NAME'         => 'CAD::Drawing::IO::DWGI',
	'VERSION_FROM' => 'lib/CAD/Drawing/IO/DWGI.pm',
	AUTHOR         => 'Eric L. Wilhelm <ewilhelm at cpan dot org>',
	'PREREQ_PM'    => {
		'Inline'          => 0,
		#'Inline::Filters' => 0,
		},
	dist           => {
		COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		},
	clean          => {
		FILES => 'CAD-Drawing-IO-DWGI-* DWGI.inl _Inline DWGI.pm'
		},
);
