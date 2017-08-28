package TestsFor::BioSAILs::Integrations::GitHub::Test001;
# package TestsFor::BioSAILs::GitIntegration::Test001;

use Moose;
use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use File::Slurp;
use File::Spec;

##This test is a placeholder for github integration tests

sub test_000 : Tags(require) {
    my $self = shift;

    ok(1);
}

1;
