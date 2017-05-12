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

my ($adaptor,$dsn,$user,$pass,$host,$start,$end,$width,$height,$foreground,$background,$omit_totals);
GetOptions('adaptor=s' => \$adaptor,
	   'dsn=s'     => \$dsn,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'host=s'    => \$host,
	   'width=s'   => \$width,
	   'height=s'  => \$height,
	   'start=s'   => \$start,
	   'end=s'     => \$end,
	   'bground=s' => \$background,
	   'fground=s' => \$foreground,
	   'omit_totals=s' => \$omit_totals,
	  );

pod2usage(-verbose => 2) unless ($dsn && $start && $end);

$adaptor ||= 'dbi::mysql';

# Create a new Audio::DB object...
my $report = Audio::DB::Reports->new(-adaptor => $adaptor,
				     -user    => $user,
				     -pass    => $pass,
				     -host    => $host,
				     -dsn     => $dsn);

my @foreground = split(",",$foreground);
my @background = split(",",$background);
my $png = $report->distribution(-class       => 'albums',
				-range       => ($start && $end) ? [$start..$end] : '',
				-width       => $width,
				-height      => $height,
				-background  => \@background,
				-foreground  => \@foreground,
				-omit_totals => $omit_totals,
			       );
print $png;

__END__

=pod

=head1 NAME

album_distribution - create a histogram of song distribution by year

=head1 SYNPOSIS

This script demonstrates how to glean some information from your music
collection.  It generates a PNG image showing the distribution of
albums in your collection by year.  This is a simple way to show 1)
when your quest for acquiring new music waned or 2) times in your life
when you were in financial straits. It requires that the GD graphics
drawing library and perl module be installed on your system.

=head1 USAGE

 album_distribution(@options)

=head1 OPTIONS

Options [database]
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   adaptor  either dbi::sqlite or dbi::mysql (defaults to dbi::mysql)

Options [image]
   start    starting year to display
   end      ending year to display
   width    [optional] the width of the image in pixels
   height   [optional] the height of the image in pixels
   bground  [optional] background color for the image as an [r g b] array reference
   fground  [optional] foreground color for the boxes as an [r g b] array reference
   omit_totals  [optional] pass true to turn off display of year totals

You may need to tinker with start,end and width,height to get an
acceptable image depending on the range of years in your collection.

eg:

album_distribution --adaptor dbi::mysql --dsn music \
                   --width 800 --height 500 --start 1950 --end 2004 \
                   --bground 255,0,0


=head1 IMPORTANT NOTE

If running this script on a Windows system, you made need to modify
this script setting the output of STDERR to BINMODE prior to printing
the image.

=head1 AUTHOR

 Todd Harris (harris@cshl.org);
 $Id: album_distribution.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
