use v5.12;
use strict;
use warnings;

package Data::Validate::CSV::SingleValueCell;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo;
use B ();
use namespace::autoclean;
with 'Data::Validate::CSV::Cell';

sub _chunk_for_key_string {
	B::perlstring( shift->value );
}

1;
