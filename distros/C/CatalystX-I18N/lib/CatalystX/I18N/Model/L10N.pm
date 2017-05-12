# ============================================================================
package CatalystX::I18N::Model::L10N;
# ============================================================================

use namespace::autoclean;
use Moose;
extends 'CatalystX::I18N::Model::Maketext';

before 'BUILD' => sub {
    my ($self) = @_;
    
    my $app = $self->_app;
    $app->log->warn('CatalystX::I18N::Model::L10N is deprecated, use CatalystX::I18N::Model::Maketext instead');
};

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;
