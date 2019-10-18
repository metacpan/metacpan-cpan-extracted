package Azure::Storage::Blob::Client::Call;
use Moose::Role;

requires 'endpoint';
requires 'method';
requires 'operation';

sub serialize_uri_parameters {
  my $self = shift;
  return {
    map { $_ => $self->$_ }
    grep { $self->meta->get_attribute($_)->does('URIParameter') }
    $self->meta->get_attribute_list()
  };
}

sub serialize_header_parameters {
  my $self = shift;
  return {
    map { $self->meta->get_attribute($_)->header_name => $self->$_ }
    grep { $self->meta->get_attribute($_)->does('HeaderParameter') }
    $self->meta->get_attribute_list()
  };
}

sub serialize_body_parameters {
  my $self = shift;
  return {
    map { $_ => $self->$_ }
    grep { $self->meta->get_attribute($_)->does('BodyParameter') }
    $self->meta->get_attribute_list()
  };
}

1;
