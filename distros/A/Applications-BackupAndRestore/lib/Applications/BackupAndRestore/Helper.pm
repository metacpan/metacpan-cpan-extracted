package Applications::BackupAndRestore::Helper;
use strict;
use warnings;

# maybe bad style, but makes life a lot easier
use base Exporter::;

our @EXPORT = qw(
  __
  sum
  format_date
  get_files
  get_all_sub_folders
  folder_size
  strtime
  estimated_time
);

use POSIX qw(strftime mktime);
#use Locale::TextDomain ('backup-and-restore');

sub __ { shift @_ }

=functions 		 																						
				print sum(1,2,3); 						# 6										
				print format_date('2007-01-30'); 	# Heute, Gestern, Montag	..		
				print get_files('/');  				   # ('a.txt', 'bin') nicht rekursiv
				print folder_size('/');  				# 2345, (in Bytes) nicht rekursiv
				print strtime(1234);  				  	# 00:11:08	  				  			
				my ($elapsed_time, $estimated_time, $total_time) =							
					estimated_time( $startTime, $dx, $total);			  						
=cut																										

sub sum {
	my $sum = 0;
	$sum += $_ foreach @_;
	return $sum;
}

sub format_date {
	my ($date) = @_;

	my ( $y, $m, $d ) = split /-/, $date;
	$date = mktime( 0, 0, 0, $d, $m - 1, $y - 1900 );

	my @today = localtime;
	my $today = mktime( 0, 0, 0, @today[ 3, 4, 5 ] );

	#printf "$today: %s, %s,%s,%s\n", $date, @today[ 3, 4, 5 ];

	my $one_day = 3600 * 24;

	return __ "Today"     if $today - $date < $one_day;
	return __ "Yesterday" if $today - $date < 2 * $one_day;
	return strftime( "%A", 0, 0, 0, $d, $m - 1, $y - 1900 ) if $today - $date < 7 * $one_day;
	return strftime( "%x", 0, 0, 0, $d, $m - 1, $y - 1900 );
}

sub get_files {
	my ($folder) = @_;
	return () unless -d $folder;
	my @files = grep { !-d $_ } map { "$folder/$_" } grep { chomp } qx{ ls -aC1 "$folder" };
	return wantarray ? @files : scalar @files;
}

sub get_all_sub_folders {
	my ($folder) = @_;
	#printf "%s\n", $folder;

	my @folders = get_sub_folders($folder);
	push @folders, map { get_all_sub_folders($_) } @folders;

	return @folders;
}

sub get_sub_folders {
	my ($folder) = @_;
	return () unless -d $folder;

	opendir( DIR, $folder ) || return ();
	my @files =
	  grep { -d $_ and not -l $_ and not /\/\.\.?$/o }
	  map { "$folder/$_" }
	  readdir(DIR);
	closedir DIR;

	#my @files = grep { -d $_ } map { "$folder/$_" } grep { chomp } qx{ ls -aC1 "$folder" };

	return wantarray ? sort @files : scalar @files;
}

sub folder_size {
	my ($folder) = @_;
	my $size = sum map { ( -s $_ ) or 0 } get_files($folder);
	#print "folder_size: $size $folder\n";
	return $size;
}

sub strtime {
	strftime( "%T", shift, 0, 0, 1, 0, 1900 );
}

sub estimated_time {
	my ( $startTime, $dx, $total ) = @_;

	return ( 0, 0, 0 ) unless $dx;

	my $elapsed_time   = time - $startTime;
	my $total_time     = $elapsed_time * $total / $dx;
	my $estimated_time = $total_time - $elapsed_time;

	return ( $elapsed_time, $estimated_time, $total_time );
}

1;
__END__
