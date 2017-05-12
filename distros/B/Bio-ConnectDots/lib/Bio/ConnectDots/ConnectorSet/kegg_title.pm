package Bio::ConnectDots::ConnectorSet::kegg_title;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;

	while (<$input_fh>) {
		chomp;
	 	my ($id, $name) = split('\t', $line);
		$name =~ s/\'/\'\'/g;
		$self->put_dot('Kegg_Pathway_ID',$id);
		$self->put_dot('Kegg_Pathway_Name',$name);
		return 1;
	}    #end of while
	return undef;
}

1;
