package TestsFor::BioX::Workflow::Command::Test001;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;

sub test_001 : Tags(req) {
    require_ok('BioX::Workflow::Command');

    require_ok('BioX::Workflow::Command::run');
    require_ok('BioX::Workflow::Command::new');
    require_ok('BioX::Workflow::Command::add');
    require_ok('BioX::Workflow::Command::inspect');

    require_ok('BioX::Workflow::Command::run::Utils::Attributes');
    require_ok('BioX::Workflow::Command::run::Rules::Directives');
    require_ok('BioX::Workflow::Command::run::Utils::Samples');
    require_ok('BioX::Workflow::Command::run::Utils::WriteMeta');
    require_ok('BioX::Workflow::Command::run::Utils::Files::ResolveDeps');
    require_ok('BioX::Workflow::Command::run::Utils::Files::TrackChanges');

    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Hash');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::List');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Array');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::HPC');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Path');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Config');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::CSV');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Glob');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Mustache');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Types::Roles::File');
    require_ok('BioX::Workflow::Command::run::Rules::Rules');

    require_ok('BioX::Workflow::Command::run::Rules::Directives::Functions');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Interpolate::Mustache');
    require_ok('BioX::Workflow::Command::run::Rules::Directives::Interpolate::Text');

    require_ok('BioX::Workflow::Command::Utils::Create');
    require_ok('BioX::Workflow::Command::Utils::Files');
    require_ok('BioX::Workflow::Command::Utils::Log');

    ##DEPRACATED
    # require_ok('BioX::Workflow::Command::Utils::Files::TrackChanges');
}

1;
