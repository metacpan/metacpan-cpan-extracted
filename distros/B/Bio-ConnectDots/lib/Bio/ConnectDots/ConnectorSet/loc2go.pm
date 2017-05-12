package Bio::ConnectDots::ConnectorSet::loc2go;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;

	while (<$input_fh>) {
		chomp;
			my ($LocusLink, $go, $evidence) = split /\s+/;
			$self->put_dot('LocusLink',$LocusLink);
			$self->put_dot('GO', $go);
			$self->put_dot('GO_evidence', $evidence);
			return 1;
	}    #end of while
	return undef;
}

1;
