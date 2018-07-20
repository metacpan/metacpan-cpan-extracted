
package TestsFor::BioSAILs::Command::Test001;

use Moose;
use Test::Class::Moose;

=head1 Purpose

These tests just run require to check for any major runtime errors

=cut

sub test_000 : Tags(require) {
    my $self = shift;

    require_ok('BioSAILs::Command::add');
    require_ok('BioSAILs::Command::execute_array');
    require_ok('BioSAILs::Command::execute_job');
    require_ok('BioSAILs::Command::new');
    require_ok('BioSAILs::Command::render');
    require_ok('BioSAILs::Command::submit_jobs');
    require_ok('BioSAILs::Command::version');
}

1;
