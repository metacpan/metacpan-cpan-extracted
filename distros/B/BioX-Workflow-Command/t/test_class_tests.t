use File::Spec::Functions qw( catdir  );
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin, 'lib' );
use Test::Class::Moose::Runner;

##Run the main applications tests

Test::Class::Moose::Runner->new(
    test_classes => [
        'TestsFor::BioX::Workflow::Command::Test001',
        'TestsFor::BioX::Workflow::Command::run::Test001',
        'TestsFor::BioX::Workflow::Command::run::Test002',
        'TestsFor::BioX::Workflow::Command::run::Test003',
        'TestsFor::BioX::Workflow::Command::run::Test004',
        'TestsFor::BioX::Workflow::Command::run::Test005',
        'TestsFor::BioX::Workflow::Command::run::Test006',
        'TestsFor::BioX::Workflow::Command::run::Test007',
        'TestsFor::BioX::Workflow::Command::run::Test008',
        'TestsFor::BioX::Workflow::Command::run::Test009',
        'TestsFor::BioX::Workflow::Command::run::Test010',
        'TestsFor::BioX::Workflow::Command::run::Test011',
        'TestsFor::BioX::Workflow::Command::run::Test012',
    ],
)->runtests;
