use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::MultiValueCell;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use B ();
use Data::Validate::CSV::Types -types;
use namespace::autoclean;

with 'Data::Validate::CSV::Cell';

use overload '@{}' => sub { shift->value }, fallback => 1;

has '+value' => (isa => ArrayRef);

sub _chunk_for_key_string {
	join ';', map B::perlstring($_), @{shift->value};
}

1;