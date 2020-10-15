package App::SimpleBackuper;

use strict;
use warnings;

sub _BlockDelete {
	my($options, $state, $block, $block_files) = @_;
	
	my($backups, $files, $blocks, $parts) = @{ $state->{db} }{qw(backups files blocks parts)};
	
	my %parts2delete;
		
	# Delete all from block
	$state->{profile}->{db_delete_all_from_block} -= time;
	
	while(@$block_files) {
		my $parent_id = shift @$block_files;
		my $id = shift @$block_files;
		my $full_path = shift @$block_files;
		my $file = $files->find_all({parent_id => $parent_id, id => $id})->[0];
		
		foreach my $version ( @{ $file->{versions} } ) {
			next if $version->{block_id} != $block->{id};
			
			if($options->{verbose}) {
				print "\t\t\tDeleting $full_path from ".
					(
						$version->{backup_id_min} == $version->{backup_id_max}
						? "backup ".$backups->find_row({ id => $version->{backup_id_max} })->{name}
						: "backups ".$backups->find_row({ id => $version->{backup_id_min} })->{name}
							."..".$backups->find_row({ id => $version->{backup_id_max} })->{name}
					)."\n";
			}
			
			$parts2delete{ $_->{hash} } = $_ foreach @{ $version->{parts} };
			
			
			foreach my $backup_id ( $version->{backup_id_min} .. $version->{backup_id_max} ) {
				my $backup = $backups->find_row({ id => $backup_id });
				next if ! $backup;
				$backup->{files_cnt}--;
				if( $backup->{files_cnt} ) {
					$backups->upsert({ id => $backup_id }, $backup);
				} else {
					$backups->delete({ id => $backup_id });
				}
			}
		}
		
		# Delete version
		@{ $file->{versions} } = grep {$_->{block_id} != $block->{id}} @{ $file->{versions} };
		
		if( @{ $file->{versions} } ) {
			$files->upsert({parent_id => $parent_id, id => $id}, $file);
		} else {
			$files->delete({parent_id => $parent_id, id => $id});
		}
	}
	$state->{profile}->{db_delete_all_from_block} += time;
	
	$blocks->delete({ id => $block->{id} });
	
	my $deleted;
	foreach my $part (values %parts2delete) {
		$state->{storage}->remove(fmt_hex2base64($part->{hash}));
		$parts->delete({hash => $part->{hash}});
		$state->{total_weight} -= $part->{size};
		$deleted++;
		if($options->{verbose}) {
			print "\t\t\tpart ".fmt_hex2base64($part->{hash})." deleted (".fmt_weight($part->{size})." of space freed)\n";
		}
	}
	
	return $deleted;
}

1;
