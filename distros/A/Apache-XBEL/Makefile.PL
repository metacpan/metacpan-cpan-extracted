use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	     => 'Apache::XBEL',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (ascope@cpan.org)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/Apache/XBEL.pm',
	      'PREREQ_PM'    => {
				 Apache           => '1.26',
				 Digest::MD5      => '1.0',
				 File::Basename   => 0,
				 File::Copy       => '0',
				 File::Spec       => '0',
				 XML::LibXML      => '1.51',
				 XML::LibXSLT     => '1.31',
				 Memoize          => '0',
				 
				 # For test.pl
				 Cwd              => 0,
				},
	      dist	        => {COMPRESS => 'gzip', SUFFIX => 'tar.gz'},
	     );
