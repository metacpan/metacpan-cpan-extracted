package App::SimpleBackuper::DB::BlocksTable;

use strict;
use warnings;
use feature ':5.'.substr($], 3, 2);
use parent qw(App::SimpleBackuper::DB::BaseTable);

sub pack {
	my($self, $data) = @_;
	
	my $p = $self->packer();
	
	$p->pack(J => 1	=> $data->{id});
	if(exists $data->{last_backup_id}) {
		$p->pack(J => 1	=> $data->{last_backup_id});
		if(exists $data->{parts_cnt}) {
			$p->pack(J => 1	=> $data->{parts_cnt});
		}
	}
	
	return $p->data;
}

sub unpack {
	my($self, $data) = @_;
	
	my $p = $self->packer($data);
	
	return {
		id				=> $p->unpack(J => 1),
		last_backup_id	=> $p->unpack(J => 1),
		parts_cnt		=> $p->unpack(J => 1),
	};
}

1;
