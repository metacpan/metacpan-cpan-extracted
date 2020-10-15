package App::SimpleBackuper::DB::FilesTable;

use strict;
use warnings;
use parent qw(App::SimpleBackuper::DB::BaseTable);
use Try::Tiny;
use Data::Dumper;
use App::SimpleBackuper::DB::PartsTable;

sub _pack_version {
	my($version) = @_;
	
	my $p = __PACKAGE__->packer()
		->pack(J => 1	=> $version->{backup_id_min})
		->pack(J => 1	=> $version->{backup_id_max})
		->pack(J => 1	=> $version->{uid})
		->pack(J => 1	=> $version->{gid})
		->pack(J => 1	=> $version->{size})
		->pack(J => 1	=> $version->{mode})
		->pack(J => 1	=> $version->{mtime})
		->pack(J => 1	=> $version->{block_id})
		->pack(J => 1	=> length($version->{symlink_to} // ''))
		;
	
	$p->pack(a => length($version->{symlink_to})	=> $version->{symlink_to} // '') if $version->{symlink_to};
	
	foreach my $part ( @{ $version->{parts} } ) {
		$p	->pack(H => 128 => $part->{hash})
			->pack(J => 1	=> $part->{size})
			->pack(a => 32	=> $part->{aes_key})
			->pack(a => 16	=> $part->{aes_iv})
			;
	}
	
	return $p->data;
}

sub _unpack_version {
	my($version) = @_;
	
	my $p = __PACKAGE__->packer($version);
	
	my %version = (
		backup_id_min	=> $p->unpack(J => 1),
		backup_id_max	=> $p->unpack(J => 1),
		uid				=> $p->unpack(J => 1),
		gid				=> $p->unpack(J => 1),
		size			=> $p->unpack(J => 1),
		mode			=> $p->unpack(J => 1),
		mtime			=> $p->unpack(J => 1),
		block_id		=> $p->unpack(J => 1),
		parts			=> [],
	);
	
	my $symlink_to_length = $p->unpack(J => 1);
	$version{symlink_to} = $symlink_to_length ? $p->unpack(a => $symlink_to_length) : undef;
	
	while(! $p->at_end) {
		push @{ $version{parts} }, {
			hash	=> $p->unpack(H => 128),
			size	=> $p->unpack(J => 1),
			block_id=> $version{block_id},
			aes_key	=> $p->unpack(a => 32),
			aes_iv	=> $p->unpack(a => 16),
		};
	}
	
	return \%version;
}

sub pack {
	my($self, $data) = @_;
	
	my $p = $self->packer();
	
	$p->pack(J => 1	=> $data->{parent_id});
	if(exists $data->{id}) {
		$p->pack(J => 1	=> $data->{id});
		if(exists $data->{name}) {
			$p->pack(J => 1	=> length($data->{name}));
			$p->pack(a => length($data->{name})	=> $data->{name});
			if(exists $data->{versions}) {
				my @versions = map { _pack_version($_) } @{ $data->{versions} };
				$p->pack(J => 1					=> scalar(@versions));
				$p->pack(J => scalar(@versions) => map { length($_) } @versions);
				$p->pack(a => '*'				=> $_) foreach @versions;
			}
		}
	}
	return $p->data;
}

sub unpack {
	my($self, $data) = @_;
	
	my $p = $self->packer($data);
	
	return {
		parent_id	=> $p->unpack(J => 1),
		id			=> $p->unpack(J => 1),
		name		=> $p->unpack(a => $p->unpack(J => 1)),
		versions	=> [ map {_unpack_version $_} map { $p->unpack(a => $_) } map { $p->unpack(J => 1) } 1 .. $p->unpack(J => 1) ],
	};
}

my $find_by_parent_id_name_cache_parent_id = 0;
my %find_by_parent_id_name_cache;
sub find_by_parent_id_name {
	my($self, $parent_id, $name) = @_;
	
	if(! $find_by_parent_id_name_cache_parent_id or $find_by_parent_id_name_cache_parent_id != $parent_id) {
		%find_by_parent_id_name_cache = map {$_->{name} => $_} map {@$_} $self->find_all({parent_id => $parent_id});
		$find_by_parent_id_name_cache_parent_id = $parent_id;
	}
	
	return $find_by_parent_id_name_cache{ $name };
}

sub delete {
	my $self = shift;
	%find_by_parent_id_name_cache = ();
	$find_by_parent_id_name_cache_parent_id = 0;
	return $self->SUPER::delete(@_);
}

1;
