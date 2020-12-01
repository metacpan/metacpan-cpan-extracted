package App::SimpleBackuper;

use strict;
use warnings;
use feature ':5.'.substr($], 3, 2);
use Carp;
use Try::Tiny;
use Time::HiRes qw(time);
use Const::Fast;
use App::SimpleBackuper::BackupDB;
use App::SimpleBackuper::_format;
use App::SimpleBackuper::_BlockDelete;
use App::SimpleBackuper::_BlocksInfo;

const my $SIZE_OF_TOP_FILES => 10;
const my $SAVE_DB_PERIOD => 10 * 60;
const my $PRINT_PROGRESS_PERIOD => 60;

sub _proc_uid_gid($$$) {
	my($uid, $gid, $uids_gids) = @_;
	
	my $last_uid_gid = @$uids_gids ? $uids_gids->unpack( $uids_gids->[-1] )->{id} : 0;
	
	my $user_name = getpwuid($uid);
	my($user) = grep { $_->{name} eq $user_name } map { $uids_gids->unpack($_) } @$uids_gids;
	if(! $user) {
		$user = {id => ++$last_uid_gid, name => $user_name};
		$uids_gids->upsert({ id => $user->{id} }, $user );
		#printf "new owner user added (unix uid %d, name %s, internal uid %d)\n", $uid, $user_name, $user->{id};
	}
	$uid = $user->{id};
	
	my $group_name = getgrgid($gid);
	my($group) = grep { $_->{name} eq $group_name } map { $uids_gids->unpack($_) } @$uids_gids;
	if(! $group) {
		$group = {id => ++$last_uid_gid, name => $group_name};
		$uids_gids->upsert({ id => $group->{id} }, $group );
		#printf "new owner group added (unix gid %d, name %s, internal gid %d)\n", $gid, $group_name, $group->{id};
	}
	$gid = $group->{id};
	
	return $uid, $gid;
}

sub Backup {
	my($options, $state) = @_;
	
	my($backups, $files, $parts, $blocks) = @{ $state->{db} }{qw(backups files parts blocks)};
	
	die "Backup '$options->{\"backup-name\"}' already exists" if grep { $backups->unpack($_)->{name} eq $options->{'backup-name'} } @$backups;
	
	$state->{$_} = 0 foreach qw(last_backup_id last_file_id last_block_id bytes_processed bytes_in_last_backup total_weight);
	
	print "Preparing to backup: " if $options->{verbose};
	$state->{profile}->{init_ids} = - time();
	foreach (@$backups) {
		my $id = $backups->unpack($_)->{id};
		$state->{last_backup_id} = $id if ! $state->{last_backup_id} or $state->{last_backup_id} < $id;
	}
	#print "last backup id $state->{last_backup_id}, ";
	foreach (@$files) {
		my $file = $files->unpack($_);
		$state->{last_file_id} = $file->{id} if ! $state->{last_file_id} or $state->{last_file_id} < $file->{id};
		if($file->{versions} and @{ $file->{versions} } and $file->{versions}->[-1]->{backup_id_max} == $state->{last_backup_id}) {
			$state->{bytes_in_last_backup} += $file->{versions}->[-1]->{size};
		}
	}
	#print "last file id $state->{last_file_id}, ";
	foreach (@$blocks) {
		my $id = $blocks->unpack($_)->{id};
		$state->{last_block_id} = $id if ! $state->{last_block_id} or $state->{last_block_id} < $id;
	}
	#print "last block id $state->{last_block_id}, ";
	$state->{profile}->{init_ids} += time;
	
	print "total weight " if $options->{verbose};
	for(my $q = 0; $q <= $#$parts; $q++) {
		$state->{total_weight} += $parts->unpack($parts->[ $q ])->{size};
	}
	print fmt_weight($state->{total_weight}).", " if $options->{verbose};
	
	my $cur_backup = {name => $options->{'backup-name'}, id => ++$state->{last_backup_id}, files_cnt => 0, max_files_cnt => 0};
	$backups->upsert({ id => $cur_backup->{id} }, $cur_backup);
	
	{
		#print "blocks stack to delete...";
		my $blocks_info = _BlocksInfo($options, $state);
		$state->{blocks_stack2delete} = [
			map {[ $_, @{ $blocks_info->{$_}->[2] } ]} sort {
				$blocks_info->{$a}->[0] <=> $blocks_info->{$b}->[0]
				or $blocks_info->{$b}->[1] <=> $blocks_info->{$a}->[1]
			} grep {$_} map { $blocks->unpack( $_ )->{id} } @$blocks
		];
		print " OK\n" if $options->{verbose};
	}
	
	_print_progress($state) if $options->{verbose};
	
	my(%files_queues_by_priority, %dirs2upd);
	while(my($mask, $priority) = each %{ $options->{files} }) {
		next if ! $priority;
		foreach my $path (glob $mask) {
			if(grep { ~index($path, $_ =~ s/(?!\/)$/\//r) } map {@$_} values %files_queues_by_priority) {
				next;
			}
			
			# Remove child paths
			foreach my $tasks (values %files_queues_by_priority) {
				my $tasks_cnt = @$tasks;
				@$tasks = grep { ! ~index($_->[0], $path =~ s/(?!\/)$/\//r) } @$tasks;
			}
			
			my $file_id = 0; {
				my @path = split(/\//, $path, -1);
				pop @path if @path and $path[-1] eq '';
				pop @path;
				
				my @cur_path;
				foreach my $path_node (@path) {
					push @cur_path, $path_node;
					
					my $file = $files->find_by_parent_id_name($file_id, $path_node);
					$file //= {
						parent_id	=> $file_id,
						id			=> ++$state->{last_file_id},
						name		=> $path_node,
						versions	=> [ {
							backup_id_min	=> $state->{last_backup_id},
							backup_id_max	=> 0,
							uid				=> 0,
							gid				=> 0,
							size			=> 0,
							mode			=> 0,
							mtime			=> 0,
							block_id		=> 0,
							symlink_to		=> undef,
							parts			=> [],
						} ],
					};
					
					$dirs2upd{join('/', @cur_path) || '/'} = {
						parent_id	=> $file_id,
						filename	=> $path_node,
					};
						
					$files->upsert({ id => $file->{id}, parent_id => $file->{parent_id} }, $file);
					
					$file_id = $file->{id};
				}
			}
			
			push @{ $files_queues_by_priority{$priority} }, [ $path, $priority, $file_id ];
		}
	}
	delete $files_queues_by_priority{ $_ } foreach grep {! @{ $files_queues_by_priority{ $_ } }} keys %files_queues_by_priority;
	
	my $last_db_save = time;
	my $last_print_progress = time;
	while(%files_queues_by_priority) {
		my($priority) = sort {$b <=> $a} keys %files_queues_by_priority;
		my $task = shift @{ $files_queues_by_priority{$priority} };
		delete $files_queues_by_priority{$priority} if ! @{ $files_queues_by_priority{$priority} };
		my @next = _file_proc( $task, $options, $state );
		unshift @{ $files_queues_by_priority{ $_->[1] } }, $_ foreach reverse @next;
		
		if($options->{verbose} and time - $last_print_progress > $PRINT_PROGRESS_PERIOD) {
			_print_progress($state);
			$last_print_progress = time;
		}
		
		if(time - $last_db_save > $SAVE_DB_PERIOD) {
			print "Saving database\n" if $options->{verbose};
			_save_db($options, $state, \%dirs2upd);
			$last_db_save = time;
		}
	}
	
	_save_db($options, $state, \%dirs2upd);
	
	_print_progress($state) if ! $options->{quiet};
}

sub _save_db {
	my($options, $state, $dirs2upd) = @_;
	while(my($full_path, $dir2upd) = each %$dirs2upd) {
		print "Updating dir $full_path..." if $options->{verbose};
		my $file = $state->{db}->{files}->find_by_parent_id_name($dir2upd->{parent_id}, $dir2upd->{filename});
		my @stat = lstat($full_path);
		next if ! @stat;
		my($uid, $gid) =_proc_uid_gid($stat[4], $stat[5], $state->{db}->{uids_gids});
		if($file->{versions}->[-1]->{backup_id_max} == $state->{last_backup_id} - 1) {
			$file->{versions}->[-1] = {
				%{ $file->{versions}->[-1] },
				backup_id_max	=> $state->{last_backup_id},
				uid				=> $uid,
				gid				=> $gid,
				size			=> $stat[7],
				mode			=> $stat[2],
				mtime			=> $stat[9],
				block_id		=> 0,
				symlink_to		=> undef,
				parts			=> [],
			};
		} else {
			push @{ $file->{versions} }, {
				backup_id_min	=> $state->{last_backup_id},
				backup_id_max	=> $state->{last_backup_id},
				uid				=> $uid,
				gid				=> $gid,
				size			=> $stat[7],
				mode			=> $stat[2],
				mtime			=> $stat[9],
				block_id		=> 0,
				symlink_to		=> undef,
				parts			=> [],
			}
		}
		$state->{db}->{files}->upsert({ id => $file->{id}, parent_id => $file->{parent_id} }, $file);
		print "OK\n" if $options->{verbose};
	}
	
	App::SimpleBackuper::BackupDB($options, $state);
}

sub _print_progress {
	print "Progress: ";
	if($_[0]->{bytes_in_last_backup}) {
		printf "processed %s of %s in last backup, ", fmt_weight($_[0]->{bytes_processed}), fmt_weight($_[0]->{bytes_in_last_backup});
	}
	printf "total backups weight %s.\n", fmt_weight($_[0]->{total_weight});
}

use Text::Glob qw(match_glob);
use Fcntl ':mode'; # For S_ISDIR & same
use App::SimpleBackuper::RegularFile;

sub _file_proc {
	my($task, $options, $state) = @_;
	
	confess "No task" if ! $task;
	confess "No filepath" if ! $task->[0];
	
	my @next;
	my $file_time_spent = 0;
	my $file_weight_spent = 0;
	
	print "$task->[0]\n" if $options->{verbose};
	print "\tparent #$task->[2], priority $task->[1]" if $options->{verbose};
	
	my $priority = $task->[1];
	while(my($mask, $p) = each %{ $options->{files} }) {
		if(match_glob( $mask, $task->[0] )) {
			$priority = $p;
			print ", priority $priority by rule '\"$mask\": $p'" if $options->{verbose};
		}
	}
	
	if(! $priority) { # Excluded by user
		print " -> skip\n" if $options->{verbose};
		return;
	}
	
	$state->{profile}->{fs} -= time;
	$state->{profile}->{fs_lstat} -= time;
	$file_time_spent -= time;
	my @stat = lstat($task->[0]);
	$file_time_spent += time;
	$state->{profile}->{fs} += time;
	$state->{profile}->{fs_lstat} += time;
	if(! @stat) {
		print ". Not exists\n" if $options->{verbose};
		return;
	}
	else {
		printf ", stat: %s:%s %o %s modified at %s", scalar getpwuid($stat[4]), scalar getgrgid($stat[5]), $stat[2], fmt_weight($stat[7]), fmt_datetime($stat[9]) if $options->{verbose};
	}
	
	
	my($backups, $blocks, $files, $parts, $uids_gids) = @{ $state->{db} }{qw(backups blocks files parts uids_gids)};
	
	
	my($uid, $gid) = _proc_uid_gid($stat[4], $stat[5], $uids_gids);
	
	
	my($file); {
		my($filename) = $task->[0] =~ /([^\/]+)\/?$/;
		$file = $files->find_by_parent_id_name($task->[2], $filename);
		if($file) {
			print ", is old file #$file->{id}" if $options->{verbose};
			if($file->{versions}->[-1]->{backup_id_max} == $state->{last_backup_id}) {
				print ", is already backuped.\n" if $options->{verbose};
				return;
			}
		} else {
			$file = {
				parent_id	=> $task->[2],
				id			=> ++$state->{last_file_id},
				name		=> $filename,
				versions	=> [],
			};
			print ", is new file #$file->{id}" if $options->{verbose};
		}
	}
	
	$state->{bytes_processed} += $file->{versions}->[-1]->{size} if @{ $file->{versions} };
	
	my %version = (
		backup_id_min	=> $state->{last_backup_id},
		backup_id_max	=> $state->{last_backup_id},
		uid				=> $uid,
		gid				=> $gid,
		size			=> $stat[7],
		mode			=> $stat[2],
		mtime			=> $stat[9],
		block_id		=> undef,
		symlink_to		=> undef,
		parts			=> [],
	);
	
	if(S_ISDIR $stat[2]) {
		print ", is directory.\n" if $options->{verbose};
		my $dh;
		
		$state->{profile}->{fs} -= time;
		$state->{profile}->{fs_read_dir} -= time;
		$file_time_spent -= time;
		if(! opendir($dh, $task->[0])) {
			$state->{profile}->{fs} += time;
			$state->{profile}->{fs_read_dir} += time;
			push @{ $state->{fails}->{$!} }, $task->[0];
			print ", can't read: $!\n" if $options->{verbose};
			return;
		}
		my @files;
		while(my $f = readdir($dh)) {
			next if $f eq '.' or $f eq '..';
			push @files, $f;
		}
		closedir($dh);
		$file_time_spent += time;
		$state->{profile}->{fs} += time;
		$state->{profile}->{fs_read_dir} += time;
		
		$version{block_id} = 0;
		
		push @next, map { [$task->[0].($task->[0] =~ /\/$/ ? '' : '/').$_, $priority, $file->{id}] } sort @files;
	}
	elsif(S_ISLNK $stat[2]) {
		$state->{profile}->{fs} -= time;
		$state->{profile}->{fs_read_symlink} -= time;
		$file_time_spent -= time;
		$version{symlink_to} = readlink($task->[0]);
		$file_time_spent += time;
		$state->{profile}->{fs} += time;
		$state->{profile}->{fs_read_symlink} += time;
		if(defined $version{symlink_to}) {
			print ", is symlink to $version{symlink_to}.\n" if $options->{verbose};
			$version{block_id} = 0;
		} else {
			push @{ $state->{fails}->{$!} }, $task->[0];
			print ", can't read: $!\n" if $options->{verbose};
			return;
		}
	}
	elsif(S_ISREG $stat[2]) {
		
		print ", is regular file" if $options->{verbose};
		
		$state->{profile}->{fs} -= time;
		$state->{profile}->{fs_read} -= time;
		$file_time_spent -= time;
		my $reg_file = try {
			App::SimpleBackuper::RegularFile->new($task->[0], $options, $state);
		} catch {
			1 while chomp;
			push @{ $state->{fails}->{$_} }, $task->[0];
			print ", can't read: '$_'\n" if $options->{verbose};
			0;
		};
		$file_time_spent += time;
		$state->{profile}->{fs} += time;
		$state->{profile}->{fs_read} += time;
		return if ! $reg_file;
		
		if(@{ $file->{versions} } and $file->{versions}->[-1]->{mtime} == $version{mtime}) {
			$version{parts} = $file->{versions}->[-1]->{parts}; # If mtime not changed then file not changed
			
			$version{block_id} = $file->{versions}->[-1]->{block_id};
			
			my $block = $blocks->find_row({ id => $version{block_id} });
			confess "File has lost block #$version{block_id} in backup "
				.$backups->find_row({ id => $version{backup_id_min} })->{name}
				."..".$backups->find_row({ id => $version{backup_id_max} })->{name}
				if ! $block;
			$block->{last_backup_id} = $state->{last_backup_id};
			$blocks->upsert({ id => $block->{id} }, $block);
			
			print ", mtime is not changed.\n" if $options->{verbose};
		} else {
			print @{ $file->{versions} } ? ", mtime changed.\n" : "\n" if $options->{verbose};
			my $part_number = 0;
			my %block_ids;
			while(1) {
				$state->{profile}->{fs} -= time;
				$state->{profile}->{fs_read} -= time;
				my $read_failed;
				my $read = try {
					$reg_file->read($part_number);
				} catch {
					1 while chomp;
					push @{ $state->{fails}->{$_} }, $task->[0];
					print ", can't read: $_\n" if $options->{verbose};
					$read_failed = 1;
				};
				$state->{profile}->{fs} += time;
				$state->{profile}->{fs_read} += time;
				return if $read_failed;
				last if ! $read;
				
				print "\tpart #$part_number: " if $options->{verbose};
				
				my %part = (
					hash	=> undef,
					size	=> undef,
					aes_key	=> undef,
				);
				$state->{profile}->{math} -= time;
				$state->{profile}->{math_hash} -= time;
				$file_time_spent -= time;
				$part{hash} = $reg_file->hash();
				$file_time_spent += time;
				$state->{profile}->{math} += time;
				$state->{profile}->{math_hash} += time;
				print "hash ".fmt_hex2base64($part{hash}).", " if $options->{verbose};
				
				
				# Search for part with this hash
				if(my $part = $parts->find_row({ hash => $part{hash} })) {
					if($part->{block_id}) {
						$block_ids{ $part->{block_id} }++;
					}
					$part{size} = $part->{size};
					$part{aes_key} = $part->{aes_key};
					$part{aes_iv} = $part->{aes_iv};
					print "backuped earlier (".fmt_weight($read)." -> ".fmt_weight($part->{size}).");\n" if $options->{verbose};
				} else {
					
					print fmt_weight($read) if $options->{verbose};
					
					$state->{profile}->{math} -= time;
					$state->{profile}->{math_compress} -= time;
					$file_time_spent -= time;
					my $ratio = $reg_file->compress();
					$file_time_spent += time;
					$state->{profile}->{math} += time;
					$state->{profile}->{math_compress} += time;
					print ' compressed to '.fmt_weight($reg_file->size) if $options->{verbose};
					
					($part{aes_key}, $part{aes_iv}) = $reg_file->gen_keys();
					$state->{profile}->{math} -= time;
					$state->{profile}->{math_encrypt} -= time;
					$file_time_spent -= time;
					$reg_file->encrypt($part{aes_key}, $part{aes_iv});
					$file_time_spent += time;
					$state->{profile}->{math} += time;
					$state->{profile}->{math_encrypt} += time;
					print ', encrypted' if $options->{verbose};
					
					$state->{total_weight} += $part{size} = $reg_file->size;
					$file_weight_spent += $reg_file->size;
					
					if($state->{total_weight} > $options->{space_limit}) {
						print "freeing up space by ".fmt_weight($state->{total_weight} - $options->{space_limit})."\n" if $options->{verbose};
						$file_time_spent += time;
						while($state->{total_weight} > $options->{space_limit}) {
							_free_up_space($options, $state, \%block_ids);
						}
						$file_time_spent -= time;
						print "\t... " if $options->{verbose};
					}
					
					$state->{profile}->{storage} -= time;
					$file_time_spent -= time;
					$state->{storage}->put(fmt_hex2base64($part{hash}), $reg_file->data_ref);
					$file_time_spent += time;
					$state->{profile}->{storage} += time;
					
					print " and stored;\n" if $options->{verbose};
					
					$parts->upsert({ hash => $part{hash} }, \%part);
				}
				
				push @{ $version{parts} }, \%part;
				
				$part_number++;
				
				last if $read < 1;
			}
			
			
			my $block;
			if(1 == %block_ids) {
				$block = $blocks->find_row({ id => keys %block_ids });
				die "Block #".join(', ', keys %block_ids)." wasn't found" if ! $block;
			}
			elsif(%block_ids) {
				# Search for block with highest parts count
				my $block_parts_cnt = 0;
				foreach my $bi ( keys %block_ids ) {
					my $b = $blocks->find_row({ id => $bi });
					if(! $block_parts_cnt or $block_parts_cnt < $b->{parts_cnt}) {
						$block_parts_cnt = $b->{parts_cnt};
						$block = $b;
					}
				}
				
				# Merge blocks to highest one
				foreach my $bi ( keys %block_ids ) {
					next if $bi == $block->{id};
					$state->{profile}->{db_find_version_by_block} -= time;
					for my $block_file_index ( 0 .. $#$files ) {
						my $block_file = $files->unpack( $files->[ $block_file_index ] );
						foreach my $version ( @{ $block_file->{versions} } ) {
							next if $version->{block_id} != $bi;
							$version->{block_id} = $block->{id};
							$block->{parts_cnt} += @{ $version->{parts} };
							foreach my $vpart (@{ $version->{parts} }) {
								my $part = $parts->find_row({ hash => $vpart->{hash} });
								next if $part->{block_id} == $block->{id};
								$part->{block_id} = $block->{id};
								$parts->upsert({ hash => $part->{hash} }, $part);
							}
						}
						$files->[ $block_file_index ] = $files->pack( $block_file );
					}
					$state->{profile}->{db_find_version_by_block} += time;
					$blocks->delete({ id => $bi });
				}
			} else {
				$block = {
					id				=> ++$state->{last_block_id},
					parts_cnt		=> scalar @{ $version{parts} },
				};
			}
			
			foreach my $part (@{ $version{parts} }) {
				$part->{block_id} //= $block->{id};
				$parts->upsert({ hash => $part->{hash} }, $part);
			}
				
			
			$block->{last_backup_id} = $state->{last_backup_id};
			$blocks->upsert({ id => $block->{id} }, $block);
			
			$version{block_id} = $block->{id};
		}
	}
	else {
		print ", skip not supported file type\n" if $options->{verbose};
		return;
	}
	
	
	# If file version not changed, use old version with wider backup ids range
	if(	@{ $file->{versions} }
		and (
			$file->{versions}->[-1]->{backup_id_max} + 1 == $state->{last_backup_id}
			or $file->{versions}->[-1]->{backup_id_max} == $state->{last_backup_id}
		)
		and $file->{versions}->[-1]->{uid}	== $version{uid}
		and $file->{versions}->[-1]->{gid}	== $version{gid}
		and $file->{versions}->[-1]->{size}	== $version{size}
		and $file->{versions}->[-1]->{mode}	== $version{mode}
		and $file->{versions}->[-1]->{mtime}== $version{mtime}
		and ( defined $file->{versions}->[-1]->{symlink_to} == defined $version{symlink_to} or ( defined $version{symlink_to} and $file->{versions}->[-1]->{symlink_to} eq $version{symlink_to} ) )
		and join(' ', map { $_->{hash} } @{ $file->{versions}->[-1]->{parts} }) eq join(' ', map { $_->{hash} } @{ $version{parts} })
	) {
		$file->{versions}->[-1]->{backup_id_max} = $state->{last_backup_id};
	} else {
		push @{ $file->{versions} }, \%version;
	}
	
	$files->upsert({ parent_id => $file->{parent_id}, id => $file->{id} }, $file );
	
	my $backup = $backups->find_row({ id => $state->{last_backup_id} });
	$backup->{files_cnt}++;
	$backup->{max_files_cnt}++;
	$backups->upsert({ id => $backup->{id} }, $backup );

	
	$state->{longest_files} ||= [];
	if(	@{ $state->{longest_files} } < $SIZE_OF_TOP_FILES
		or $state->{longest_files}->[-1]->{time} < $file_time_spent
	) {
		@{ $state->{longest_files} } = sort {$b->{time} <=> $a->{time}} (@{ $state->{longest_files} }, {time => $file_time_spent, path => $task->[0]});
		splice @{ $state->{longest_files} }, $SIZE_OF_TOP_FILES;
	}
	
	if($file_weight_spent) {
		$state->{heaviweightest_files} ||= [];
		if(	@{ $state->{heaviweightest_files} } < $SIZE_OF_TOP_FILES
			or $state->{heaviweightest_files}->[-1]->{weight} < $file_weight_spent
		) {
			@{ $state->{heaviweightest_files} } = sort {$b->{weight} <=> $a->{weight}}
				(@{ $state->{heaviweightest_files} }, {weight => $file_weight_spent, path => $task->[0]});
			splice @{ $state->{heaviweightest_files} }, $SIZE_OF_TOP_FILES;
		}
	}
	
	return @next;
}

sub _free_up_space {
	my($options, $state, $protected_block_ids) = @_;
	
	my($backups, $files, $blocks, $parts) = @{ $state->{db} }{qw(backups files blocks parts)};
	
	my $deleted = 0;
	while ( @{ $state->{blocks_stack2delete} } ) {
		my($block_id, @files) = @{ shift @{ $state->{blocks_stack2delete} } };
		next if exists $protected_block_ids->{$block_id};
		my $block = $blocks->find_row({ id => $block_id });
		next if ! $block;
		next if $block->{last_backup_id} == $state->{last_backup_id};
		
		$deleted += App::SimpleBackuper::_BlockDelete($options, $state, $block, \@files);
		last if $deleted;
	}
	
	die "Nothing to delete from storage for free space" if ! $deleted;
}

1;
