package Data::HTML::Element::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo::utils 0.06 qw(check_array);
use Readonly;

Readonly::Array our @DATA_TYPES => qw(cb plain tags);
Readonly::Array our @EXPORT_OK => qw(check_data check_data_type);

our $VERSION = 0.16;

sub check_data {
	my $self = shift;

	# Check data based on type.
	check_array($self, 'data');
	foreach my $data_item (@{$self->{'data'}}) {
		# Plain mode
		if ($self->{'data_type'} eq 'plain') {
			if (ref $data_item ne '') {
				err "Parameter 'data' in 'plain' mode must contain ".
					'reference to array with scalars.';
			}

		# Tags mode.
		} elsif ($self->{'data_type'} eq 'tags') {
			if (ref $data_item ne 'ARRAY') {
				err "Parameter 'data' in 'tags' mode must contain ".
					"reference to array with references ".
					'to array with Tags structure.';
			}

		# Callback.
		} else {
			if (ref $data_item ne 'CODE') {
				err "Parameter 'data' in 'cb' mode must contain ".
					"reference to code with callback.";
			}
		}
	}

	return;
}

sub check_data_type {
	my $self = shift;

	# Check data type.
	if (! defined $self->{'data_type'}) {
		$self->{'data_type'} = 'plain';
	}
	if (none { $self->{'data_type'} eq $_ } @DATA_TYPES) {
		err "Parameter 'data_type' has bad value.",
			'Value', $self->{'data_type'},
		;
	}

	return;
}


1;

__END__
