package Azure::Storage::Blob::Client::Exception;
use Moose;
extends 'Throwable::Error';

has code => (is => 'ro', isa => 'Str', required => 1);

__PACKAGE__->meta->make_immutable();

1;
