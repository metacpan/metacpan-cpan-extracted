use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Mining::Apriori',
    VERSION_FROM      => 'lib/Data/Mining/Apriori.pm', # finds $VERSION
	LICENSE           => "perl",
    PREREQ_PM => {
        'Algorithm::Combinatorics'     => 0.27,
        'List::PowerSet'     => 0.01
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Mining/Apriori.pm', # retrieve abstract from module
       AUTHOR         => 'Alex Graciano <agraciano@cpan.org>') : ()),
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	META_MERGE => {
		resources => {
			homepage    => 'https://alexgracianoarj.github.io/data-mining-apriori',
			repository  => 'https://github.com/alexgracianoarj/data-mining-apriori',
			bugtracker  => 'https://github.com/alexgracianoarj/data-mining-apriori/issues',
		}
	}
);
