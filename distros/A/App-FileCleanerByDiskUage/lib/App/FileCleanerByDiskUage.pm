package App::FileCleanerByDiskUage;

use 5.006;
use strict;
use warnings;
use File::Find::Rule;
use Filesys::Df;

=head1 NAME

App::FileCleanerByDiskUage - Removes files based on disk space usage till it drops below the specified amount.

=head1 VERSION

Version 0.2.1

=cut

our $VERSION = '0.2.1';

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

	my @missing_paths;
	my @paths;

	my $du_path;
	# file paths should end with / or other wise if it is a symlink File::Find::Rule will skip it
	# so fix that up while we are doing the path check
	if ( !defined( $opts{path} ) ) {
		die('$opts{path} is not defined');
	} elsif ( ref( $opts{path} ) ne 'ARRAY' && !-d $opts{path} ) {
		push( @missing_paths, $opts{path} );
	} elsif ( ref( $opts{path} ) eq 'ARRAY' ) {
		if ( !defined( $opts{path}[0] ) ) {
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
		$du_path = $opts{path}[0];
	} else {
		$opts{path} = $opts{path} . '/';
		$opts{path} =~ s/\/+$/\//;
		$du_path = $opts{path};
		push( @paths, $opts{path} );
	}

	if ( !defined( $opts{du} ) ) {
		die('$opts{du} is not defined');
	} elsif ( $opts{du} !~ /^\d+$/ ) {
		die( '$opts{du} is set to "' . $opts{du} . '" whish is not numeric' );
	}

	# if we have a min_files specified, make sure the value is numeric
	if ( defined( $opts{min_files} ) && $opts{min_files} !~ /^\d+$/ ) {
		die( '$opts{min_files} is set to "' . $opts{min_files} . '" whish is not numeric matching /^\d+$/' );
	}

	if ( !$opts{dry_run} ) {
		$opts{dry_run} = 0,;
	} else {
		$opts{dry_run} = 1,;
	}

	my $df = df($du_path);

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
		return $results;
	}

	if ( $df->{per} < $opts{du} ) {
		return $results;
	}

	my @files;
	if ( defined( $opts{ignore} ) ) {
		my $ignore_rule = File::Find::Rule->new;
		$ignore_rule->name(qr/$opts{ignore}/);
		@files = File::Find::Rule->file()->not($ignore_rule)->in(@paths);
	} else {
		@files = File::Find::Rule->file()->in(@paths);
	}
	$results->{found_files_count} = $#files + 1;

	# if we have a min number of files specified, make sure have that many defined
	if ( $opts{min_files} && !defined( $files[ $opts{min_files} ] ) ) {
		$results->{min_files} = $opts{min_files};
		return $results;
	}

	# get the stats for all the files
	my @files_info;
	foreach my $file (@files) {
		my %file_info;
		(
			$file_info{dev},   $file_info{ino},     $file_info{mode}, $file_info{nlink}, $file_info{uid},
			$file_info{gid},   $file_info{rdev},    $file_info{size}, $file_info{atime}, $file_info{mtime},
			$file_info{ctime}, $file_info{blksize}, $file_info{blocks}
		) = stat($file);
		$file_info{name} = $file;
		push( @files_info, \%file_info );
	} ## end foreach my $file (@files)

	# sort files oldest to newest based on mtime
	@files_info = sort { $a->{mtime} cmp $b->{mtime} } @files_info;
	# set this here as we are saving it into the hashref as a array ref
	my @files_info_copy = @files_info;
	$results->{found_files} = \@files_info_copy;

	# remove the newest files if mins_files is greater than or equal to 1
	if ( defined( $opts{min_files} ) && $opts{min_files} > 0 ) {
		$results->{min_files} = $opts{min_files};
		my $min_files_int = 1;
		while ( $min_files_int <= $opts{min_files} ) {
			pop(@files_info);

			$min_files_int++;
		}
	}

	# go through files and remove the oldest till we
	my $int = 0;
	while ( $df->{per} >= $opts{du} && defined( $files_info[$int] ) ) {
		eval {
			if ( $opts{dry_run} && !-w $files_info[$int]{name} ) {
				die('file is not writable');
			} else {
				unlink( $files_info[$int]{name} ) or die($!);
			}

		};
		my %tmp_hash = %{ $files_info[$int] };
		if ($@) {
			push( @{ $results->{unlink_errors} }, 'Failed to remove "' . $files_info[$int]{name} . '"... ' . $@ );
			push( @{ $results->{unlink_failed} }, \%tmp_hash );
		} else {
			push( @{ $results->{unlinked} }, \%tmp_hash );
		}

		$int++;
		$df = df($du_path);
	} ## end while ( $df->{per} >= $opts{du} && defined( $files_info...))

	$results->{du_ending} = $df->{per};
	if ( defined( $results->{unlinked}[0] ) ) {
		$results->{unlinked_count} = $#{ $results->{unlinked} } + 1;
	}
	if ( defined( $results->{unlink_failed}[0] ) ) {
		$results->{unlink_failed_count} = $#{ $results->{unlink_failed} } + 1;
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
