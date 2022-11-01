use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Data::Combination',
	VERSION_FROM      => 'lib/Data/Combination.pm',
	PREREQ_PM         => {}, 
	MIN_PERL_VERSION  => "v5.24.4",
	ABSTRACT_FROM     => 'lib/Data/Combination.pm', # retrieve abstract from module
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-data-combination.git",
				web => "http://github.com/drclaw1394/perl-data-combination",
			}
		}
	}

);
