use ExtUtils::MakeMaker 7.24;

my %parms = (
	'NAME'      => 'Bio::PhyloXS',
	'INC'       => '-Isrc -I.',
	'VERSION'   => 'v0.1.0',
	'AUTHOR'    => 'Rutger Vos',
	'LICENSE'   => 'perl',  
	'XSMULTI'   => 1,
	'ABSTRACT'  => 'Core modules for Bio::Phylo, re-implemented using C',
	'PREREQ_PM' => { 'Bio::Phylo' => '0.58' },  
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            homepage    => 'http://biophylo.blogspot.com/',
            bugtracker  => 'https://github.com/rvosa/bio-phylo-xs/issues',
            repository  => 'git://github.com/rvosa/bio-phylo-xs.git',
            license     => 'http://dev.perl.org/licenses/',
            MailingList => 'mailto:bio-phylo@googlegroups.com',
        },
    };
}

WriteMakefile( %parms );

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }

