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

my $duration = $report->library_duration();
my $size     = $report->library_size();
my $counts   = $report->counts();

print "Library duration: " . $duration->{total_time},"\n";
print "Library size    : " . $size->{GB}," GB\n\n";

print "Total songs     : " . $counts->{songs},"\n";
print "Total artists   : " . $counts->{artists},"\n";
print "Total albums    : " . $counts->{albums},"\n";
print "Total genres    : " . $counts->{genres},"\n";

__END__

=pod

=head1 NAME

library_statistics - generate some general statistics on your library

=head1 SYNPOSIS

This script shows how to generate some basic statistics on your music
library. It returns the following statistics:

   - total songs, albums, artists, and genres
   - total duration of all songs
   - total size of all songs

=head1 OPTIONS

Options [database]
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   adaptor  either dbi::sqlite or dbi::mysql (defaults to dbi::mysql)

eg:

 library_statistics --dsn music

=head1 AUTHOR

 Todd Harris (harris@cshl.org);
 $Id: library_statistics.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
