package App::SimpleBackuper::DB::PartsTable;

use strict;
use warnings;
use parent qw(App::SimpleBackuper::DB::BaseTable);
use Try::Tiny;
use Data::Dumper;

sub pack {
	my($self, $data) = @_;
	
	my $p = $self->packer();
	
	$p->pack(H => 128	=> $data->{hash});
	if(exists $data->{size}) {
		$p->pack(J => 1	=> $data->{size});
		$p->pack(J => 1	=> $data->{block_id} // 0);
		$p->pack(a => 32=> $data->{aes_key});
		$p->pack(a => 16=> $data->{aes_iv});
	}
	
	return $p->data;
}

sub unpack {
	my($self, $data) = @_;
	
	my $p = $self->packer($data);
	
	return {
		hash		=> $p->unpack( H => 128 ),
		size		=> $p->unpack( J => 1 ),
		block_id	=> $p->unpack( J => 1 ),
		aes_key		=> $p->unpack( a => 32 ),
		aes_iv		=> $p->unpack( a => 16 ),
	};
}

1;
