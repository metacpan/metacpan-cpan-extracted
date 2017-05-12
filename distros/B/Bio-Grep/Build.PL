use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
            code => q{

    sub ACTION_dist {
        my $self = shift;
        system('perl -I lib/ examples/benchmark.pl') if $self->y_n(
            "Do you want to create new benchmarks?",'N');
        $self->SUPER::ACTION_dist;
    }

},
);

my $builder = $class->new(
    module_name         => 'Bio::Grep',
    license             => 'perl',
    dist_author         => 'Markus Riester <mriester@gmx.de>',
    dist_version_from   => 'lib/Bio/Grep.pm',
    requires            => {
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
                            'IPC::Open3'         => 0,
                            'Readonly'           => 0,
                            'perl'               => '5.8.1',
                            'Bio::Factory::EMBOSS' => 0,
                            'Bio::Seq'             => 0, 
                            'Bio::Root::Root'      => 0,
                            'Bio::Index::Fasta'    => 0, 
                            'Bio::AlignIO'         => 0, 
                            'Bio::SeqIO'           => 0,
                            },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    }, 
    script_files        => [ 'examples/bgrep' ], 
    add_to_cleanup      => [ 'Bio-Grep-*' ],
);

$builder->create_build_script();
