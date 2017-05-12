package TestApp::Backend::InnerPackage;

sub foo { 42 }

package TestApp::Backend::InnerPackage::Inner;

use Moose;

has 'okay' => (
  is => 'ro',
  default => 'Alright!',
);

no Moose;
__PACKAGE__->meta->make_immutable;
