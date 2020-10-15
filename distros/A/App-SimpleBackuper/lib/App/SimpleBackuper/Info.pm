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
	
	return {
		versions => [ map { {
			backups			=> [ map {$backups->find_row({id => $_})->{name}} $_->{backup_id_min} .. $_->{backup_id_max} ],
			user			=> $uids_gids->find_row({id => $_->{uid}})->{name},
			group			=> $uids_gids->find_row({id => $_->{gid}})->{name},
			size			=> fmt_weight($_->{size}),
			mode			=> $_->{mode},
			mtime			=> fmt_datetime($_->{mtime}),
		} } @{ $parent_file->{versions} } ],
		subfiles => [ map { {
			name			=> ($_->{name} eq '' ? '/' : $_->{name}),
			newest_backup	=> $backups->find_row({id => $_->{versions}->[-1]->{backup_id_max} })->{name},
			oldest_backup	=> $backups->find_row({id => $_->{versions}->[0]->{backup_id_min} })->{name},
		} } sort {$a->{name} cmp $b->{name}} map {@$_} $files->find_all({ parent_id => $parent_file->{id} })],
	};
}

1;
