use strict;
use warnings FATAL => 'all';
use File::Spec::Functions qw( catdir  );
use BioSAILs::Command;
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin, 'lib' );
use Test::Class::Moose::Runner;

## BioSAILs::Command is just a wrapper around the BioX::Workflow::Command and HPC::Runner::Command libraries
## All there is here is just a 'require ok' series of tests

Test::Class::Moose::Runner->new(
    test_classes => [
                    'TestsFor::BioSAILs::Command::Test001',
    ],
)->runtests;
