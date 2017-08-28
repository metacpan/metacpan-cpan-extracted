
package TestsFor::BioSAILs::Utils::Test001;

use Moose;
use Test::Class::Moose;

=head1 Purpose

These tests just run require to check for any major runtime errors

=cut

sub test_000 : Tags(require) {
    my $self = shift;

    require_ok('BioSAILs');
    require_ok('BioSAILs::Utils');
    require_ok('BioSAILs::Utils::CacheUtils');
    require_ok('BioSAILs::Utils::Plugin');
    require_ok('BioSAILs::Utils::Traits');
}

1;
