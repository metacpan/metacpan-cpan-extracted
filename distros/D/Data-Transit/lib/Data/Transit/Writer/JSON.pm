package Data::Transit::Writer::JSON;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use parent 'Data::Transit::Writer';

use JSON;

sub _encode {
	my ($self, $data) = @_;
	return encode_json($data);
}

1;
