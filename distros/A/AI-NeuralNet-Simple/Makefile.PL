use 5.005;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $module  = 'lib/AI/NeuralNet/Simple.pm';
my $ccflags = -d '.svn' ? '-Wall' : '';

WriteMakefile(
    'NAME'         => 'AI::NeuralNet::Simple',
    'VERSION_FROM' => $module,                   # finds $VERSION
    'CCFLAGS'      => $ccflags,
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'Log::Agent'      => '0.208',
        'Test::More'      => '0.48_01',
        'Test::Exception' => '0.15',
        'Sub::Uplevel'    => 0,                  # hate it, hate it, hate it
    },
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          ( ABSTRACT_FROM => $module,    # retrieve abstract from module
            AUTHOR => 'Curtis "Ovid" Poe <ovid@cpan.org>'
          )
        : ()
    ),
);
