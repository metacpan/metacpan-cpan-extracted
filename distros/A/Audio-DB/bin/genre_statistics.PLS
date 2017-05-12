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

my ($adaptor,$dsn,$user,$pass,$host);
GetOptions('adaptor=s' => \$adaptor,
	   'dsn=s'     => \$dsn,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'host=s'    => \$host,
	  );

pod2usage(-verbose => 2) unless ($dsn);

$adaptor ||= 'dbi::mysql';

# Create a new Audio::DB object...
my $report = Audio::DB::Reports->new(-adaptor => $adaptor,
				     -user    => $user,
				     -pass    => $pass,
				     -host    => $host,
				     -dsn     => $dsn);

my @genres = $report->genre_report(-include=>1);
print "TOTAL GENRES IN USE: " . scalar @genres,"\n";
printf "%-20s %-8s %-8s %-8s\n","Genre","songs","albums","artists";
foreach (sort { $a->genre cmp $b->genre } @genres) {
  printf "%-20s %-8s %-8s %-8s\n",$_->genre,@{$_->{stats}};
}

if (0) {
  # Song breakdown by genre
  print "SONG BREAKDOWN BY GENRE\n";
  foreach (sort { $a->genre cmp $b->genre } @genres) {
    print $_->genre,"\n";
    foreach ($_->{songs}) {
      print "\t",$_->title,"\n";
    }
  }
  
  # Album breakdown by genre
  print "ALBUM BREAKDOWN BY GENRE\n";
  foreach (sort { $a->genre cmp $b->genre } @genres) {
    print $_->genre,"\n";
    foreach (sort {$a->album cmp $b->album } @{$_->{albums}}) {
      print "\t",$_->album,"\n";
    }
  }
}


# Artist breakdown by genre
print "ARTIST BREAKDOWN BY GENRE\n";
foreach (sort { $a->genre cmp $b->genre } @genres) {
  print $_->genre,"\n";
  foreach (sort { $a->artist cmp $b->artist } @{$_->{artists}}) {
    print "\t",$_->artist,"\n";
  }
}

__END__

=pod

=head1 NAME

genre statistics - general statistics on the use of genres in your collection

=head1 SYNPOSIS

This script shows how to generate some basic statistics on your music
library. It returns the following statistics:

   - All genres
   - number of songs, albums, and artists in each genre

=head1 OPTIONS

Options [database]
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   adaptor  either dbi::sqlite or dbi::mysql (defaults to dbi::mysql)
   include  boolean. If true, all songs, albums, and artists will also be returned.

eg:

 genre_statistics [@options]

=head1 AUTHOR

Todd Harris (harris@cshl.org);
$Id: genre_statistics.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut


!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
