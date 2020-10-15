package App::SimpleBackuper::DB::UidsGidsTable;

use strict;
use warnings;
use parent qw(App::SimpleBackuper::DB::BaseTable);

sub pack {
	my($self, $data) = @_;
	
	my $p = $self->packer();
	$p->pack(J => 1	=> $data->{id});
	if(exists $data->{name}) {
		$p->pack(a => '*'	=> $data->{name});
	};
	
	return $p->data;
}

sub unpack {
	my($self, $data) = @_;
	
	my $p = $self->packer($data);
	
	return {
		id		=> $p->unpack( J => 1 ),
		name	=> $p->unpack( a => '*' ),
	};
}

1;
