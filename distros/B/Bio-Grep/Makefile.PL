use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bio::Grep',
    VERSION_FROM      => 'lib/Bio/Grep.pm', # finds $VERSION
    PREREQ_PM         => { 
                            'Class::MethodMaker' => 2.02,
                            'version'            => 0,
                            'autodie'            => 0,
    		                'IO::String'         => 1.0, 
                            'Getopt::Long'       => 2.32,   
                            'Pod::Usage'         => 0,   
                            'UNIVERSAL::require' => 0.11,   
                            'Carp::Assert'       => 0,
                            'ToolSet'            => 0.13,
                            'Bio::Root::Version' => 0,
                            'IPC::Open3'           => 0,
                            'Readonly'             => 0,
                            'Bio::Factory::EMBOSS' => 0,
                            'Bio::Seq'             => 0, 
                            'Bio::Root::Root'      => 0,
                            'Bio::Index::Fasta'    => 0, 
                            'Bio::AlignIO'         => 0, 
                            'Bio::SeqIO'           => 0,
                            'Test::NoWarnings' => 0,
                          }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/Grep.pm', # retrieve abstract from module
       AUTHOR         => 'Markus Riester <mriester@gmx.de>') : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
            ('LICENSE'  => 'perl')         : ()),
    EXE_FILES         => [ 'examples/bgrep' ], 
);
