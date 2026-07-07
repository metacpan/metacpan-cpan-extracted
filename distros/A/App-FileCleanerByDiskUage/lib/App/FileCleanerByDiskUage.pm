package App::FileCleanerByDiskUage;

use 5.006;
use strict;
use warnings;
use File::Find             ();
use Filesys::Df            qw( df );
use Net::Server::Daemonize qw(check_pid_file create_pid_file unlink_pid_file);

=head1 NAME

App::FileCleanerByDiskUage - Removes files based on disk space usage till it drops below the specified amount.

=head1 VERSION

Version 0.5.0

=cut

our $VERSION = '0.5.0';

=head1 SYNOPSIS

    use App::FileCleanerByDiskUage;

    # remove files under /var/log/suricata/pcap when disk usage is over 90%
    # If over 90% make sure there are atleast 32 files and if there are atleast 32, remove them based
    # on age till we drop below 90%. The newest 32 will be ignored regardless of disk usage.
    my $removed=App::FileCleanerByDiskUage->clean(path=>'/var/log/suricata/pcap/', du=>90, min_files=>32);
    if (defined( $removed->{errors}[0] )){
        die('One or more file could not be removed... '.join('  ', @{ $removed->{errors} }));
    }
    my $int=0;
    while (defined( $removed->{unlined}[$int] )){
        print 'Removed ' . $removed->{unlinked}[$int]{name} . "\n";

        $int++;
    }

This works via doing the following.

1: Check if disk usage is above the specified threshold. If not it ends here.

2: Search for files under the specified path.

3: If the number of found files is less than the number of files to keep regardless
of disk size it ends here. So if min_files is set to 32 and there are only 3 files,
then it would just return.

4: Get the stats for all the found files.

5: If min_files is specified, remove that many of the files from the list, starting
with the newest.

6: Removes the oldest file.

7: Check disk usage again and if it is less it ends here.

8: Go back to 6.

=head1 Functions

=head2 clean

This performs the cleaning actions. As long as the path exists and .path and .du
are defined this will not die. But if any of those are undef or do not exist it will
die.

The following hash values are taken by it.

    Minimum Required Vars: path, du

    - path :: The path to look for files under. May be a array of paths. Only the first is used
              for getting the disk usage though, so this should not have paths in it that are on
              a different partition.
        Default :: undef

    - du :: Disk usage to remove files down till.
        Default :: undef

    - min_files :: Minimum number of files to keep, regardless of disk usage.
        Default :: undef

    - ignore :: A regexp to use for ignoring files. So lets say you want to ignore,
                files matching /\.pcap$/, it would be '\.pcap$'.
        Default :: undef

    - dry_run :: Do not actually remove anything. Just check to see if the file writable by the
                 current user.

    -use_pid :: Create a PID to make sure multiple instances can't run at once.
        Default :: undef

    -pid_dir :: Create a PID to make sure multiple instances can't run at once.
        Default :: /var/run

    - pid_name :: Append this to the the name of the pid file created. If specified with a
            value of 'foo' then the file would be 'file_cleaner_by_du-foo.pid'.
        Default :: undef

The returned value is a hash ref.

    - dry_run :: Boolean for fir it was a dry run or not.

    - found_files :: Array of hashes of data for all files found. This will only be defined if du is above
                     threshold for removing files. If it is below it, the function will return instead of taking
                     the time required to run a search.

    - found_files_count :: A count of files found.

    - path :: The value of path that it was called with. This will always be a array, regardless of if a array or
              scalar was passed as internally converts a scalars into a array containing just a single item.

    - missing_paths :: Paths that were passed to it, but don't exist.

    - unlinked :: Array of hashes of data for files that have been removed.

    - unlinked_count :: A count of how many files were unlinked

    - unlink_errors :: Array of strings containing error descriptions.

    - unlink_failed :: Array of hashes of data for files that could not removed. The corresponding
                       index in .errors will be the error in question. So $results->{unlink_failed}[0]
                       would be $results->{unlink_errors}[0]

    - unlink_fialed_count :: A count of how many files unlinking failed for.

The files hash is composed as below.

    - name :: Name of the file, including it's path.

    # following are provided via the Perl function stat
    - dev
    - ino
    - mode
    - nlink
    - uid
    - gid
    - rdev
    - size
    - atime
    - mtime
    - ctime
    - blksize
    - blocks

=cut

sub clean {
	my ( $empty, %opts ) = @_;

	my $pid_file;
	if ( $opts{use_pid} ) {
		if ( !defined( $opts{pid_dir} ) ) {
			$opts{pid_dir} = '/var/run';
		} else {
			if ( !-d $opts{pid_dir} ) {
				die( $opts{pid_dir} . ' does not exist or is not a dir' );
			}
		}

		if ( !defined( $opts{pid_name} ) ) {
			$pid_file = $opts{pid_dir} . '/file_cleaner_by_du.pid';
		} else {
			if ( $opts{pid_name} =~ /\// || $opts{pid_name} =~ /\\/ ) {
				die( 'PID name of "' . $opts{pid_name} . '" can not contain either / or \\' );
			}
			$pid_file = $opts{pid_dir} . '/file_cleaner_by_du-' . $opts{pid_name} . '.pid';
		}

		check_pid_file($pid_file);
		create_pid_file($pid_file);
	} ## end if ( $opts{use_pid} )

	my @missing_paths;
	my @paths;

	my $du_path;
	# file paths should end with / or otherwise if the path is a symlink File::Find will not descend into it
	# so fix that up while we are doing the path check
	if ( !defined( $opts{path} ) ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		die('$opts{path} is not defined');
	} elsif ( ref( $opts{path} ) ne 'ARRAY' && !-d $opts{path} ) {
		push( @missing_paths, $opts{path} );
	} elsif ( ref( $opts{path} ) eq 'ARRAY' ) {
		if ( !defined( $opts{path}[0] ) ) {
			if ( $opts{use_pid} ) {
				unlink_pid_file($pid_file);
			}
			die('$opts{path}[0] is not defined');
		}
		my $int = 0;
		while ( defined( $opts{path}[$int] ) ) {
			$opts{path}[$int] = $opts{path}[$int] . '/';
			$opts{path}[$int] =~ s/\/+$/\//;
			if ( !-d $opts{path}[$int] ) {
				push( @missing_paths, $opts{path}[$int] );
			} else {
				push( @paths, $opts{path}[$int] );
			}
			$int++;
		} ## end while ( defined( $opts{path}[$int] ) )
		$du_path = $paths[0];
	} else {
		$opts{path} = $opts{path} . '/';
		$opts{path} =~ s/\/+$/\//;
		$du_path = $opts{path};
		push( @paths, $opts{path} );
	}

	if ( !defined( $paths[0] ) ) {
		die('All specified paths are missing or not a directory');
	}

	if ( !defined( $opts{du} ) ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		die('$opts{du} is not defined');
	} elsif ( $opts{du} !~ /^\d+$/ ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		die( '$opts{du} is set to "' . $opts{du} . '" whish is not numeric' );
	}

	# if we have a min_files specified, make sure the value is numeric
	if ( defined( $opts{min_files} ) && $opts{min_files} !~ /^\d+$/ ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		die( '$opts{min_files} is set to "' . $opts{min_files} . '" whish is not numeric matching /^\d+$/' );
	}

	if ( !$opts{dry_run} ) {
		$opts{dry_run} = 0,;
	} else {
		$opts{dry_run} = 1,;
	}

	# df() is normally Filesys::Df::df, but may be overridden internally via the
	# _df option so the removal loop's disk-usage logic can be tested without a
	# real filesystem. _resync bounds how many files may be removed between real
	# df() checks (see the removal loop below).
	my $df_func = ( ref( $opts{_df} ) eq 'CODE' ) ? $opts{_df} : \&df;
	my $resync = ( defined( $opts{_resync} ) && $opts{_resync} =~ /^\d+$/ && $opts{_resync} > 0 ) ? $opts{_resync} : 64;

	my $df = $df_func->($du_path);

	# the results to be returned
	my $results = {
		unlinked            => [],
		unlink_failed       => [],
		unlink_errors       => [],
		found_files         => [],
		found_files_count   => 0,
		unlinked_count      => 0,
		unlink_failed_count => 0,
		du_target           => $opts{du},
		du_starting         => $df->{per},
		du_ending           => $df->{per},
		min_files           => 0,
		dry_run             => $opts{dry_run},
		path                => \@paths,
		missing_paths       => \@missing_paths,
	};

	if ( !defined( $paths[0] ) ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		return $results;
	}

	if ( $df->{per} < $opts{du} ) {
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		return $results;
	}

	# compile the ignore regexp once, if specified, and reuse it below
	my $ignore_re = defined( $opts{ignore} ) ? qr/$opts{ignore}/ : undef;

	# Recursively find regular files under the requested paths, statting each
	# one inline during the traversal. Doing the stat here means a single stat
	# syscall per file (the traversal and the mtime lookup share it) and avoids
	# building a separate array of path strings alongside the file info.
	my @files_info;
	File::Find::find(
		sub {
			# $_ is the basename (we are chdir'd into the containing dir),
			# $File::Find::name is the full path. stat($_) populates the "_"
			# handle so the -f test below reuses it rather than statting again.
			my @stat = stat($_);
			return unless @stat;    # skip on stat failure (races, broken symlinks)
			return unless -f _;     # regular files only, matching the old ->file rule
			return if defined($ignore_re) && $_ =~ $ignore_re;    # ignore by basename
			# blocks ($stat[12], 512-byte units) is the space actually freed by
			# unlinking, used by the removal loop to estimate disk usage between
			# df() calls. apparent size would over-count sparse/small files.
			push( @files_info, { name => $File::Find::name, mtime => $stat[9], blocks => $stat[12] } );
		},
		@paths
	);
	$results->{found_files_count} = scalar(@files_info);

	# if we have a min number of files specified, make sure we found more than
	# that many. min_files elements at indexes 0 .. min_files-1, so index
	# min_files existing means there is at least one file eligible for removal.
	if ( $opts{min_files} && !defined( $files_info[ $opts{min_files} ] ) ) {
		$results->{min_files} = $opts{min_files};
		if ( $opts{use_pid} ) {
			unlink_pid_file($pid_file);
		}
		return $results;
	}

	# sort files oldest to newest based on mtime, numerically
	@files_info = sort { $a->{mtime} <=> $b->{mtime} } @files_info;
	# save the full, sorted list into the results; the unlink loop below is
	# bounded by an index so it never touches this array, meaning we don't
	# need a defensive copy here
	$results->{found_files} = \@files_info;

	# the newest min_files files are kept regardless of disk usage. As the list
	# is sorted oldest to newest, those are the last min_files entries, so we
	# simply stop the removal loop before reaching them rather than removing
	# them from the array.
	my $min_files = 0;
	if ( defined( $opts{min_files} ) && $opts{min_files} > 0 ) {
		$min_files            = $opts{min_files};
		$results->{min_files} = $min_files;
	}
	# index of the last (oldest end) file eligible for removal
	my $last_removable = $#files_info - $min_files;

	# go through files and remove the oldest till we drop below the threshold.
	#
	# Rather than calling df() after every single unlink (a statvfs syscall each
	# time, which dominates the loop on high latency filesystems), we estimate
	# how much space we still need to free from the block counts we already have
	# and only consult the real df() when the estimate says we should be close.
	# The real df() remains the authoritative stop condition, so this never
	# under removes; the $resync cap bounds how far a bad estimate (concurrent
	# writers, files held open elsewhere) can run us past the target.
	my $per = $df->{per};

	# bytes the user may occupy, used to translate a percentage into bytes. The
	# byte mode df() (block size of 1) reports used/bavail in bytes.
	my $df_bytes = $df_func->( $du_path, 1 );
	my $user_total = ( $df_bytes->{used} || 0 ) + ( $df_bytes->{bavail} || 0 );
	# estimated bytes still to free to reach the target, and bytes freed since
	# the last real df() check
	my $need  = ( ( $per - $opts{du} ) / 100 ) * $user_total;
	my $freed = 0;

	my $int             = 0;
	my $since_resync    = 0;
	while ( $per >= $opts{du} && $int <= $last_removable ) {
		my $file = $files_info[$int];
		eval {
			if ( $opts{dry_run} ) {
				# dry run: never remove anything, just verify the file would be
				# removable by checking it is writable by the current user
				if ( !-w $file->{name} ) {
					die('file is not writable');
				}
			} else {
				unlink( $file->{name} ) or die($!);
			}

		};
		if ($@) {
			push( @{ $results->{unlink_errors} }, 'Failed to remove "' . $file->{name} . '"... ' . $@ );
			push( @{ $results->{unlink_failed} }, $file );
		} else {
			push( @{ $results->{unlinked} }, $file );
			# a failed unlink frees nothing, so only count successful removals
			$freed += ( $file->{blocks} || 0 ) * 512 unless $opts{dry_run};
		}

		$int++;
		$since_resync++;

		# a dry run never changes disk usage, so re-checking df() would loop
		# forever on the same $per; the index bound above is what stops it.
		next if $opts{dry_run};

		# consult the real df() only once we estimate we have freed enough, or
		# once $resync files have gone by, whichever comes first
		if ( $freed >= $need || $since_resync >= $resync ) {
			$df           = $df_func->($du_path);
			$per          = $df->{per};
			$need         = ( ( $per - $opts{du} ) / 100 ) * $user_total;
			$freed        = 0;
			$since_resync = 0;
		}
	} ## end while ( $per >= $opts{du} && $int <= $last_removable )

	# make sure du_ending reflects real disk usage, not the last estimate
	$df = $df_func->($du_path);
	$results->{du_ending} = $df->{per};
	if ( defined( $results->{unlinked}[0] ) ) {
		$results->{unlinked_count} = $#{ $results->{unlinked} } + 1;
	}
	if ( defined( $results->{unlink_failed}[0] ) ) {
		$results->{unlink_failed_count} = $#{ $results->{unlink_failed} } + 1;
	}

	if ( $opts{use_pid} ) {
		unlink_pid_file($pid_file);
	}
	return $results;
} ## end sub clean

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-filecleanerbydiskuage at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-FileCleanerByDiskUage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FileCleanerByDiskUage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-FileCleanerByDiskUage>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-FileCleanerByDiskUage>

=item * Search CPAN

L<https://metacpan.org/release/App-FileCleanerByDiskUage>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 3, June 2007


=cut

1;    # End of App::FileCleanerByDiskUage
