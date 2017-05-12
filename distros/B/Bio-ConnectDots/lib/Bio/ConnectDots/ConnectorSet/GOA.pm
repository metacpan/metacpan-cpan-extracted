package Bio::ConnectDots::ConnectorSet::GOA;

use strict;
use vars qw(@ISA);
use Bio::ConnectDots::ConnectorSet;
@ISA = qw(Bio::ConnectDots::ConnectorSet);

sub parse_entry {
	my ($self) = @_;
	my $input_fh = $self->input_fh;
	$_ = <$input_fh>;
	return undef unless $_;
	chomp;
	my @COLS = split /\t/;
	$self->put_dot('Database', $COLS[0]) if $COLS[0];
	$self->put_dot('DB_Object_ID', $COLS[1]) if $COLS[1];
	$self->put_dot('DB_Object_Symbol', $COLS[2]) if $COLS[2];
	$self->put_dot('GO_id', $COLS[4]) if $COLS[4];
	$self->put_dot('DB_Reference', $COLS[5]) if $COLS[5];
	$self->put_dot('Evidence', $COLS[6]) if $COLS[6];
	$self->put_dot('Aspect', $COLS[8]) if $COLS[8];
	$self->put_dot('DB_Object_Name', $COLS[9]) if $COLS[9];
	$self->put_dot('IPI_id', $COLS[10]) if $COLS[10];
	$self->put_dot('Taxon_ID', $COLS[12]) if $COLS[12];				
	return 1;
}

1;