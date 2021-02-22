package App::SimpleBackuper::DB;

use strict;
use warnings;
use Const::Fast;
use App::SimpleBackuper::DB::BackupsTable;
use App::SimpleBackuper::DB::FilesTable;
use App::SimpleBackuper::DB::PartsTable;
use App::SimpleBackuper::DB::BlocksTable;
use App::SimpleBackuper::DB::UidsGidsTable;

const my $FORMAT_VERSION => 2;

sub _unpack_tmpl {
	my($self, $tmpl) = @_;
	my $length = length pack $tmpl;
	my $buf = substr $self->{dump}, $self->{offset}, $length;
	$self->{offset} += $length;
	return unpack $tmpl, $buf;
}

sub _unpack_record {
	my($self) = @_;
	my $length = $self->_unpack_tmpl("J");
	return $self->_unpack_tmpl("a$length");
}

sub new {
	my($class, $dump_ref) = @_;
	
	my $self = bless {
		backups 	=> App::SimpleBackuper::DB::BackupsTable->new(),
		files		=> App::SimpleBackuper::DB::FilesTable->new(),
		parts		=> App::SimpleBackuper::DB::PartsTable->new(),
		blocks		=> App::SimpleBackuper::DB::BlocksTable->new(),
		uids_gids	=> App::SimpleBackuper::DB::UidsGidsTable->new(),
	} => $class;
	
	if($dump_ref) {
		$self->{dump} = $$dump_ref;
		$self->{offset} = 0;
		
		my $format_version = $self->_unpack_tmpl('J');
		my $parse_method = "parse_format_v$format_version";
		die "Unsupported database format version $format_version" if ! $self->can($parse_method);
		$self->$parse_method();
		delete $self->{ $_ } foreach qw(dump offset);
	}
	
	return $self;
}

sub dump {
	my($self) = @_;
	my $dump_method = "dump_format_v$FORMAT_VERSION";
	return $self->$dump_method();
}

sub parse_format_v2 {
	my($self) = @_;
	
	my($backups_cnt, $files_cnt, $parts_cnt, $blocks_cnt, $uids_gids_cnt) = $self->_unpack_tmpl("JJJJJ");
	
	$self->{backups}	= App::SimpleBackuper::DB::BackupsTable->new($backups_cnt);
	$self->{backups}	->[$_ - 1] = $self->_unpack_record() for 1 .. $backups_cnt;
	$self->{files}		= App::SimpleBackuper::DB::FilesTable->new($files_cnt);
	$self->{files}		->[$_ - 1] = $self->_unpack_record() for 1 .. $files_cnt;
	$self->{parts}		= App::SimpleBackuper::DB::PartsTable->new($parts_cnt);
	$self->{parts}		->[$_ - 1] = $self->_unpack_record() for 1 .. $parts_cnt;
	$self->{blocks}		= App::SimpleBackuper::DB::BlocksTable->new($blocks_cnt);
	$self->{blocks}		->[$_ - 1] = $self->_unpack_record() for 1 .. $blocks_cnt;
	$self->{uids_gids}	= App::SimpleBackuper::DB::UidsGidsTable->new($uids_gids_cnt);
	$self->{uids_gids}	->[$_ - 1] = $self->_unpack_record() for 1 .. $uids_gids_cnt;
}

sub dump_format_v2 {
	my($self) = @_;
	
	return \ join('',
		pack("JJJJJJ", $FORMAT_VERSION, map {scalar @{ $self->{$_} }} qw(backups files parts blocks uids_gids)),
		map { pack("Ja".length($_), length($_), $_) } map {@{ $self->{$_} }} qw(backups files parts blocks uids_gids)
	);
}

sub parse_format_v1 {
	my($self) = @_;
	
	my($backups_cnt, $files_cnt, $uids_gids_cnt) = $self->_unpack_tmpl("JJJ");
	
	$self->{backups}	= App::SimpleBackuper::DB::BackupsTable->new($backups_cnt);
	foreach(my $q = 0; $q < $backups_cnt; $q++) {
		# upgrade backups format
		my $record = $self->_unpack_record();
		$record = $self->{backups}->unpack_format_v1($record);
		$record = $self->{backups}->pack($record);
		$self->{backups}->[ $q ] = $record;
	}
	$self->{files}		= App::SimpleBackuper::DB::FilesTable->new($files_cnt);
	$self->{files}		->[$_ - 1] = $self->_unpack_record() for 1 .. $files_cnt;
	$self->{uids_gids}	= App::SimpleBackuper::DB::UidsGidsTable->new($uids_gids_cnt);
	$self->{uids_gids}	->[$_ - 1] = $self->_unpack_record() for 1 .. $uids_gids_cnt;
	
	delete $self->{ $_ } foreach qw(dump offset);
	
	my %backups_files_cnt = map {$self->{backups}->unpack($_)->{id} => 0} @{ $self->{backups} };
	for my $q (0 .. $#{ $self->{files} }) {
		my $file = $self->{files}->unpack( $self->{files}->[ $q ] );
		
		foreach my $version (@{ $file->{versions} }) {
			foreach my $backup_id ( $version->{backup_id_min} .. $version->{backup_id_max} ) {
				$backups_files_cnt{ $backup_id }++;
			}
			
			foreach my $part ( @{ $version->{parts} } ) {
				$self->{parts}->upsert({hash => $part->{hash}}, {%$part, block_id => $version->{block_id}});
			}
			
			my $block = $self->{blocks}->find_row({ id => $version->{block_id} });
			if(! $block) {
				$self->{blocks}->upsert(
					{id	=> $version->{block_id}},
					{
						id				=> $version->{block_id},
						last_backup_id	=> $version->{backup_id_max},
						parts_cnt		=> scalar @{ $version->{parts} },
					}
				);
			} else {
				$block->{last_backup_id} = $version->{backup_id_max} if $block->{last_backup_id} < $version->{backup_id_max};
				$block->{parts_cnt} += @{ $version->{parts} };
				$self->{blocks}->upsert({ id => $version->{block_id} }, $block);
			}
		}
	}
	
	while(my($backup_id, $files_cnt) = each %backups_files_cnt) {
		my $backup = $self->{backups}->find_row({ id => $backup_id });
		$backup->{files_cnt} = $files_cnt;
		$self->{backups}->upsert({ id => $backup_id }, $backup );
	}
}

sub dump_format_v1 {
	my $self = shift;
	
	return \ join('',
		pack("JJJJ", $FORMAT_VERSION, scalar @{ $self->{backups} }, scalar @{ $self->{files} }, scalar @{ $self->{uids_gids} }),
		map { pack("Ja".length($_), length($_), $_) } @{ $self->{backups} }, @{ $self->{files} }, @{ $self->{uids_gids} }
	);
}

1;
