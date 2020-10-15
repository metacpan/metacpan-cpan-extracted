package App::SimpleBackuper::DB::BackupsTable;

use strict;
use warnings;
use parent qw(App::SimpleBackuper::DB::BaseTable);
use Carp;

sub pack {
	my($self, $data) = @_;
	
	my $p = $self->packer();
	
	$p->pack(J => 1		=> $data->{id} // confess "No id");
	if(exists $data->{files_cnt}) {
		$p->pack(J => 1		=> $data->{files_cnt});
		if(exists $data->{max_files_cnt}) {
			$p->pack(J => 1		=> $data->{max_files_cnt});
			if(exists $data->{name}) {
				$p->pack(a => '*' => $data->{name});
			}
		}
	}
	
	return $p->data;
}

sub unpack {
	my($self, $data) = @_;
	
	my $p = $self->packer($data);
	
	return {
		id				=> $p->unpack(J => 1),
		files_cnt		=> $p->unpack(J => 1),
		max_files_cnt	=> $p->unpack(J => 1),
		name			=> $p->unpack(a => '*'),
	};		
}

1;
