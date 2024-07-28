package App::SimpleBackuper;

use strict;
use warnings;

sub _BlocksInfo($$;$$$$);
sub _BlocksInfo($$;$$$$) {
	my($options, $state, $block_info, $parent_id, $path, $priority) = @_;
	
	$block_info //= {};
	$parent_id //= 0;
	$path //= '/';
	$priority //= 0;
	
	my($oldest_backup_id) = $state->{db}->{backups}->unpack($state->{db}->{backups}->[0])->{id};
	
	my $subfiles = $state->{db}->{files}->find_all({parent_id => $parent_id});
	foreach my $file ( @$subfiles ) {
		
		my $full_path = ($path eq '/' ?  $path : "$path/").$file->{name};
		my $prio = $priority;
		while(my($mask, $p) = each %{ $options->{files} }) {
			$prio = $p if match_glob( $mask, $full_path );
		}
		
		_BlocksInfo($options, $state, $block_info, $file->{id}, $full_path, $prio);
		
		my %file_added2block;
		foreach my $version ( @{ $file->{versions} } ) {
			next if ! $version->{block_id};
			
			my $backup_id_score = $version->{backup_id_max} - $oldest_backup_id + 1;
			
			$block_info->{ $version->{block_id} } ||= [0, 0, [], 0, 0];
			if($block_info->{ $version->{block_id} }->[0] < $backup_id_score * $prio) {
				$block_info->{ $version->{block_id} }->[0] = $backup_id_score * $prio;
				$block_info->{ $version->{block_id} }->[3] = $backup_id_score;
				$block_info->{ $version->{block_id} }->[4] = $prio;
			}
			foreach my $part (@{ $version->{parts} }) {
				$block_info->{ $version->{block_id} }->[1] += $part->{size};
			}
			if(! $file_added2block{ $version->{block_id} }) {
				push @{ $block_info->{ $version->{block_id} }->[2] }, $file->{parent_id}, $file->{id}, $full_path;
			}
			
			$file_added2block{ $version->{block_id} } = 1;
		}
	}
	
	return $block_info;
}

1;
