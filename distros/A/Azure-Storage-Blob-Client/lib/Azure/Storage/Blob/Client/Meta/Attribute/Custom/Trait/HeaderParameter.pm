package Azure::Storage::Blob::Client::Meta::Attribute::Custom::Trait::HeaderParameter;
use Moose::Role;

Moose::Util::meta_attribute_alias('HeaderParameter');

has header_name => (is => 'ro', isa => 'Str', required => 1);

1;
