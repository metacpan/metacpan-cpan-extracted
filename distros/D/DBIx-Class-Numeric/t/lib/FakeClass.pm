use strict;
use warnings;

package FakeClass;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Numeric/);

__PACKAGE__->numeric_columns(qw/foo bar/);

# A little trickery to pretend we're a real DBIx::Class module
my %fake_cols;

sub get_column {
	my $self = shift;
	my $col = shift;
	
	return $fake_cols{$col};
}

sub set_column {
	my $self = shift;
	my $col = shift;
	
	$fake_cols{$col} = shift;	
}

sub _set_fake_cols {
	%fake_cols = @_;	
}

1;