#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL','.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pl';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use Audio::DB::Reports;
use Getopt::Long;
use Pod::Usage;
use strict;

my ($adaptor,$dsn,$user,$pass,$host,$compressed);
GetOptions('adaptor=s' => \$adaptor,
	   'dsn=s'     => \$dsn,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'host=s'    => \$host,
           'compressed'=> \$compressed,
	  );

pod2usage(-verbose=>2) unless $dsn;

# Create a new Audio::DB::Reports object...
$adaptor ||= 'dbi::mysql';
my $mp3 = Audio::DB::Reports->new(-adaptor => $adaptor,
				  -user    => $user,
				  -pass    => $pass,
				  -host    => $host,
				  -dsn     => $dsn);

# Print out the number of songs, artists, albums, and genres...
print "Songs   : ",$mp3->count('songs'),"\n";
print "Artists : ",$mp3->count('artists'),"\n";
print "Albums  : ",$mp3->count('albums'),"\n";
print "Genres  : ",$mp3->count('genres'),"\n";

# Fetch all albums and print them out according to their artist
my $albums = $mp3->album_list(-sort_by => 'artist',
			      -include => ['songs']);

foreach my $album_obj (@$albums) {
  my $album   = $album_obj->album;
  my $artist  = $album_obj->artists;
  my $bitrate = $album_obj->bitrates;
  my $year    = $album_obj->years;
  if ($compressed) {
    printf "%-7s %-10s %-30s\n",$bitrate,$artist,$album;
  } else {
    printf "%-7s %-7s %-20s %-30s\n",$year,$bitrate,$artist,$album;
  }
}

__END__

=pod

=head1 NAME generate_album_list

=head1 SYNPOSIS

Create a simple list of your albums, sorted by artist and album. It
demonstrates some of the methods of the Audio::DB::Reports module.

 generate_album_list --user todd --pass password --dsn todds_music

=head1 OPTIONS

Options:
   adaptor  either dbi::sqlite or dbi::mysql
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   host     database host, if other than localhost

=head1 AUTHOR

 Todd Harris (harris@cshl.org);
 $Id: generate_album_list.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
