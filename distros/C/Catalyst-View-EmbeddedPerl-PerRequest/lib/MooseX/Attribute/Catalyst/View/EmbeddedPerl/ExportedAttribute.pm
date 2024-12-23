package MooseX::Attribute::Catalyst::View::EmbeddedPerl::ExportedAttribute;

use Moose::Role;

# You only really need to change this if you change the code in this file
# but syncing it to the main version is ok as well.
our $VERSION = 0.001017;
eval $VERSION;

has 'exported_to_template' => (is=>'ro');
 
around '_process_options' => sub {
  my ($orig, $self, $name, $options) = (@_);
  if(delete($options->{export})) {
    $options->{exported_to_template} = 1;
  } else {
    $options->{exported_to_template} = 0;
  }
  return $self->$orig($name, $options);
};

package Moose::Meta::Attribute::Custom::Trait::Catalyst::View::EmbeddedPerl::ExportedAttribute;
sub register_implementation { 'MooseX::Attribute::Catalyst::View::EmbeddedPerl::ExportedAttribute' }

1;