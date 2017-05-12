use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Bio::Tools::CodonOptTable',
    AUTHOR        => 'Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>',
    VERSION_FROM  => 'lib/Bio/Tools/CodonOptTable.pm',
    ABSTRACT_FROM => 'lib/Bio/Tools/CodonOptTable.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'             => 0,
        'Data::Dumper'           => 0,
        'Bio::Root::Root'        => 0,
        'Bio::PrimarySeq'        => 0,
        'Bio::SeqIO'             => 0,
        'Bio::Tools::SeqStats'   => 0,
        'Bio::Tools::CodonTable' => 0,
        'Bio::DB::GenBank'       => 0,
        'GD::Graph::bars'        => 0,
        'Text::Textile'          => 0,
        'File::Slurp'            => 0,
	'URI::Escape'		 => 0,
	'LWP::UserAgent' 	 => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Bio-Tools-CodonOptTable-*' },
);
