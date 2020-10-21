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

sub debug {
	my($self, $id, $data) = @_;
	state %debug;
	if($data) {
		$debug{$id} .= $data;
	} else {
		return $debug{$id};
	}
}

sub upsert {
	my($self, $search_row, $data) = @_;
	
	$self->debug($data->{id} => 'u');
	
	return $self->SUPER::upsert($search_row, $data);
}

sub delete {
	my($self, $row) = @_;
	
	$self->debug($row->{id} => 'd');
	
	return $self->SUPER::delete($row);
}

1;
