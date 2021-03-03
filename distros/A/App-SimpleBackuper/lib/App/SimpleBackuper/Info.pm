package App::SimpleBackuper;

use strict;
use warnings;
use Time::HiRes qw(time);
use App::SimpleBackuper::_print_table;
use App::SimpleBackuper::_format;

sub Info {
	my($options, $state) = @_;
	
	my($backups, $files, $uids_gids) = @{ $state->{db} }{qw(backups files uids_gids)};
	
	my $parent_file;
	my @path = split(/\//, $options->{path} // '/', -1);
	pop @path if @path and $path[-1] eq '';
	
	my $file_id = 0;
	$state->{profile}->{walk2path} -= time;
	foreach my $path_node (@path) {
		my $file = $files->find_by_parent_id_name($file_id, $path_node);
		return {error => 'NOT_FOUND'} if ! $file;
		$file_id = $file->{id};
		$parent_file = $file;
	}
	$state->{profile}->{walk2path} += time;
	
	my @versions;
	foreach my $version (@{ $parent_file->{versions} }) {
		my @backups = map {$backups->find_row({id => $_})} $version->{backup_id_min} .. $version->{backup_id_max};
		@backups = map {$_->{name}} @backups;
		my $user = $uids_gids->find_row({id => $version->{uid}});
		$user = $user->{name};
		my $group = $uids_gids->find_row({id => $version->{gid}});
		$group = $group->{name};
		push @versions, {
			backups	=> \@backups,
			user	=> $user,
			group	=> $group,
			size	=> fmt_weight($version->{size}),
			mode	=> $version->{mode},
			mtime	=> fmt_datetime($version->{mtime}),
		};
	}
	
	my @files = map {@$_} $files->find_all({ parent_id => $parent_file->{id} });
	@files = sort {$a->{name} cmp $b->{name}} @files;
	my @subfiles;
	foreach my $file (@files) {
		my $oldest_backup = $backups->find_row({id => $file->{versions}->[-1]->{backup_id_max} });
		$oldest_backup = $oldest_backup->{name};
		my $newest_backup = $backups->find_row({id => $file->{versions}->[0]->{backup_id_max} });
		$newest_backup = $newest_backup->{name};
		push @subfiles, {
			name			=> ($file->{name} eq '' ? '/' : $file->{name}),
			oldest_backup	=> $oldest_backup // '-',
			newest_backup	=> $newest_backup // '-',
		};
	}
	
	return {versions => \@versions, subfiles => \@subfiles};
}

1;
