package Bio::ConnectDots::ConnectorSet::DoTS;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;

	while (<$input_fh>) {
		chomp;
		if (/^DT/) {
			my ($DoTS_ID, $LocusLink) = split /\s+/;
			$self->put_dot('DoTS_ID',$DoTS_ID);
			$self->put_dot('LocusLink',$LocusLink);
			return 1;
		}
	}    #end of while
	return undef;
}

1;
