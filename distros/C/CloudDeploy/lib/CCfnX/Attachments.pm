package CCfnX::Attachments;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
  with_meta => [ 'attachment' ],
);

sub attachment {
  Moose->throw_error(
    'Usage: attachment \'name\' => (type => \'Type\', documentation => \'\',' .
    ' provides => { param => key_from_attachment, ... })'
  ) if (@_ < 2);
  my ( $meta, $name, %options ) = @_;

  # Add the attachment
  $meta->add_attribute(
    $name,
    is     => 'rw',
    isa    => 'Str',
    type   => $options{ type },
    traits => [ 'Attachable' ],
    generates_params => [ keys %{ $options{provides} } ],
  );

  # Every attachment will declare that it provides some extra parameters in the provides
  # these will be converted in attributes. If they start with "-", then they will not be
  # StackParameters, that is they will not be accessible in CF via a Ref.
  foreach my $attribute (keys %{ $options{ provides } }){
    my $lookup_in_attachment = $options{ provides }->{$attribute};

    if ($meta->find_attribute_by_name($attribute)) {
        Moose->throw_error("An attribute with name $attribute already exists");
    }

    my @extra_traits = ();
    if (substr($attribute,0,1) eq '-'){
      # Strip off the '-' in the attribute name
      substr($attribute,0,1) = '';
    } else {
      push @extra_traits, 'StackParameter';
    }

    $meta->add_attribute(
      $attribute,
      is      => 'rw',
      isa     => 'Any',
      lazy    => 1,
      traits  => [ 'NoGetopt', 'Attached', @extra_traits ],
      default => sub {
        my $params = $_[0]; 
        my $param = $params->meta->find_attribute_by_name($name);
        return $param->get_info($params->$name, $lookup_in_attachment)
      },
    );
  }
}

1;
