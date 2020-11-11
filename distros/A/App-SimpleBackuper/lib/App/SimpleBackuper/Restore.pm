package App::SimpleBackuper;

use strict;
use warnings;
use Fcntl ':mode'; # For S_ISDIR & same
use App::SimpleBackuper::_format;

sub Restore {
	my($options, $state) = @_;
	
	my($backup) = grep {$_->{name} eq $options->{'backup-name'}}
		map {$state->{db}->{backups}->unpack($_)}
		@{ $state->{db}->{backups} }
		;
	die qq|Backup $options->{'backup-name'} was not found in database| if ! $backup;
	$state->{backup_id} = $backup->{id};
	
	my @path = split(/\//, $options->{path}, -1);
	pop @path if @path and $path[-1] eq '';

	my $file = {id => 0};
	my @cur_path;
	foreach my $path_node (@path) {
		push @cur_path, $path_node;
		$file = $state->{db}->{files}->find_by_parent_id_name($file->{id}, $path_node);
		return {error => 'NOT_FOUND'} if ! $file;
	}
	
	$options->{destination} =~ s/\/$//g;
	
	_proc_file($options, $state, $file, join('/', @cur_path) || '/', $options->{destination});
	
	print "Backup '$options->{'backup-name'}' was successful restored.\n" if ! $options->{quiet};
	
	return {};
}

sub _restore_part {
	my($options, $reg_file, $storage, $part, $number) = @_;
	
	$reg_file->data_ref(\$storage->get(fmt_hex2base64($part->{hash}))->[0]);
	print "fetched, " if $options->{verbose};
	$reg_file->decrypt($part->{aes_key}, $part->{aes_iv});
	print "decrypted, " if $options->{verbose};
	my $ratio = $reg_file->decompress();
	printf "decompressed (x%d)", $ratio if $options->{verbose};
	$reg_file->write($number);
	print " and restored.\n" if $options->{verbose};
}

sub _proc_file {
	my($options, $state, $file, $backup_path, $fs_path) = @_;
	
	print "$backup_path -> $fs_path\n" if $options->{verbose};
	
	
	my($version) = grep {$_->{backup_id_min} <= $state->{backup_id} and $_->{backup_id_max} >= $state->{backup_id}}
		@{ $file->{versions} };
	if(! $version) {
		print "\tnot exists in this backup.\n" if $options->{verbose};
		return;
	}
	
	my @stat = lstat($fs_path);
	my($fs_user, $fs_group);
	if(@stat) {
		$fs_user = getpwuid($stat[4]);
		$fs_group = getpwuid($stat[5]);
	}
	
	if(S_ISDIR $version->{mode}) {
		my $need2mkdir;
		if(@stat) {
			if(! S_ISDIR $stat[2]) {
				print "\tin backup it's dir but on FS it's not.\n" if $options->{verbose};
				unlink $fs_path if $options->{write};
				$need2mkdir = 1;
			}
		} else {
			$need2mkdir = 1;
		}
		
		if($need2mkdir) {
			mkdir($fs_path, $version->{mode}) or die "Can't mkdir $fs_path: $!" if $options->{write};
			$fs_user = scalar getpwuid $<;
			$fs_group = scalar getgrgid $(;
			$stat[2] = $version->{mode};
		}
	}
	elsif(S_ISLNK $version->{mode}) {
		my $need2link;
		if(@stat) {
			if(S_ISLNK $stat[2]) {
				my $symlink_to = readlink($fs_path) // die "Can't read symlink $fs_path: $!";
				if($symlink_to ne $version->{symlink_to}) {
					print "\tin backup this symlink refers to $version->{symlink_to} but on FS - to $symlink_to.\n" if $options->{verbose};
					unlink $fs_path if $options->{write};
					$need2link = 1;
				}
			} else {
				print "\tin backup it's a symlink but on FS it's not.\n" if $options->{verbose};
				unlink $fs_path if $options->{write};
				$need2link = 1;
			}
		} else {
			$need2link = 1;
		}
		
		if($need2link) {
			if($options->{write}) {
				symlink($version->{symlink_to}, $fs_path) or die "Can't make symlink $fs_path -> $version->{symlink_to}: $!";
			}
			$fs_user = scalar getpwuid $<;
			$fs_group = scalar getgrgid $(;
		}
	}
	elsif(S_ISREG $version->{mode}) {
		my $need2rewrite_whole_file;
		if(@stat) {
			if(S_ISREG $stat[2]) {
				my $reg_file = App::SimpleBackuper::RegularFile->new($fs_path, $options);
				my $file_writer;
				if($stat[7] != $version->{size}) {
					print "\tin backup it's file with size ".fmt_weight($version->{size}).", but on FS - ".fmt_weight($version->{size}).".\n" if $options->{verbose};
					$reg_file->truncate($version->{size}) if $options->{write};
				}
				for my $part_number (0 .. $#{ $version->{parts} }) {
					$reg_file->read($part_number);
					my $fs_hash = $reg_file->hash;
					if($fs_hash eq $version->{parts}->[ $part_number ]->{hash}) {
						print "\tpart #$part_number hash is ".fmt_hex2base64($fs_hash)." (OK)\n" if $options->{verbose};
					}
					else {
						print "\tpart#$part_number in backup has hash ".fmt_hex2base64($version->{parts}->[ $part_number ]->{hash}).", but on FS - ".fmt_hex2base64($fs_hash).": " if $options->{verbose};
						if($options->{write}) {
							_restore_part($options, $reg_file, $state->{storage}, $version->{parts}->[ $part_number ], $part_number);
						} else {
							print "\twill be restored\n" if $options->{verbose};
						}
					}
				}
			} else {
				print "\tin backup it's a regular file, but on FS it's not.\n" if $options->{verbose};
				$need2rewrite_whole_file = 1;
				unlink $fs_path if $options->{write};
			}
		} else {
			$need2rewrite_whole_file = 1;
		}
		
		if($need2rewrite_whole_file) {
			if($options->{write}) {
				my $reg_file = App::SimpleBackuper::RegularFile->new($fs_path, $options, $state);
				if(@{ $version->{parts} }) {
					for my $part_number (0 .. $#{ $version->{parts} }) {
						print "\tpart #$part_number hash is ".fmt_hex2base64($version->{parts}->[ $part_number ]->{hash}).": " if $options->{verbose};
						_restore_part($options, $reg_file, $state->{storage}, $version->{parts}->[ $part_number ], $part_number);
					}
				} else {
					$reg_file->set_write_mode();
				}
			} else {
				print "\tfile will be restored.\n" if $options->{verbose};
			}
			$fs_user = scalar getpwuid $<;
			$fs_group = scalar getgrgid $(;
		}
	}
	
	
	if((! @stat or $stat[2] != $version->{mode}) and ! S_ISLNK $version->{mode}) {
		printf "\tin backup it has mode %o but on FS - %o.\n", $version->{mode}, $stat[2] // 0 if $options->{verbose};
		if($options->{write}) {
			chmod($version->{mode}, $fs_path) or die sprintf("Can't chmod %s to %o: %s", $fs_path, $version->{mode}, $!);
		}
	}
			
	my($db_user) = map {$_->{name}}
		grep {$_->{id} == $version->{uid}}
		map { $state->{db}->{uids_gids}->unpack($_) }
		@{ $state->{db}->{uids_gids} }
		;
	my($db_group) = map {$_->{name}}
		grep {$_->{id} == $version->{gid}}
		map { $state->{db}->{uids_gids}->unpack($_) }
		@{ $state->{db}->{uids_gids} }
		;
	if(($fs_user ne $db_user or $fs_group ne $db_group) and ! S_ISLNK $version->{mode}) {
		print "\tin backup it owned by $db_user:$db_group but on FS - by $fs_user:$fs_group.\n" if $options->{verbose};
		chown scalar(getpwnam $db_user), scalar getgrnam($db_group), $fs_path if $options->{write};
	}
	
	
	if(S_ISDIR $version->{mode}) {
		foreach my $subfile (sort {$a->{name} cmp $b->{name}} map {@$_} $state->{db}->{files}->find_all({parent_id => $file->{id}})) {
			_proc_file($options, $state, $subfile, $backup_path.'/'.$subfile->{name}, $fs_path.'/'.$subfile->{name});
		}
	}
}

1;
