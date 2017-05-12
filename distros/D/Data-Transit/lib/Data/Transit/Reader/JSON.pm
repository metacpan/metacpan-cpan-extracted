package Data::Transit::Reader::JSON;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use parent 'Data::Transit::Reader';

use JSON;

sub _decode {
	my ($self, $data) = @_;
	return decode_json($data);
}

1;
