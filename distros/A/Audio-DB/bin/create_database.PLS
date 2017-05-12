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

use Audio::DB::Build;
use Pod::Usage;
use Getopt::Long;
use strict;

my ($adaptor,$dsn,$library,$user,$pass,$host,@files,@dirs,@cols);
GetOptions('adaptor=s' => \$adaptor,
	   'dsn=s'     => \$dsn,
	   'library=s' => \$library,
	   'user=s'    => \$user,
	   'pass=s'    => \$pass,
	   'host=s'    => \$host,
	   'dirs=s'    => \@dirs,
	   'files=s'   => \@files,
	   'cols=s'    => \@cols,
	  );

pod2usage( -verbose=> 2 ) unless ($adaptor && ($library || @files || @dirs));

# Create a new MP3::DB object...
my $build = Audio::DB::Build->new(-adaptor => $adaptor,
				-user    => $user,
				-pass    => $pass,
				-host    => $host,
				-dsn     => $dsn,
				-create  => 1 # We want to create a new DB
			       );

# Initialize the database with the default schema
$build->initialize(1);

# Load up the database
my $stats;
if ($library) {
  $stats = $build->load_database(-library  => $library,
			       -tmp      => '/tmp',
			       -verbose  => 100);
} elsif (@dirs > 0) {
  $stats = $build->load_database(-dirs     => \@dirs,
			       -tmp      =>'/tmp',
			       -verbose  => 100);
} elsif (@files > 0) {
  $stats = $build->load_database(-files    => \@files,
			       -columns  => \@cols,
			       -tmp      =>'/tmp',
			       -verbose  => 100);
}

# Print out some stats:
print "Statistics:\n";
print "Succesfully added...\n";
foreach (keys %$stats) {
  print "\t",ucfirst($_),"\t: \t$stats->{$_}\n";
}
print "...to the database\n\n";

if (@files || @dirs) {
  my $problem_files = $build->get_couldnt_read();
  if (@$problem_files > 0) {
    print scalar @$problem_files . " files could not be read...\n";
    foreach (@$problem_files) {
      print "\t$_\n",
    }
  } else {
    print "All files succesfully read\n\n.";
  }
}

__END__

=pod

=head1 create_database

=head1 SYNPOSIS

This is a simple demonstration script that quickly build a relational
database of your music collection from flat files, XML dumps, or from
MP3 tags themselves.  It illustrates the primary functions of the
Audio::DB::Build module.

 create_database --user todd --pass password --dsn todds_music \
                 --library /Users/todd/Music/iTunes/iTunes\ Music\ Library.xml

=head1 OPTIONS

Options:
   adaptor  either dbi::sqlite or dbi::mysql
   dsn      the name of your database
   user     database username, if required
   pass     database password if required
   host     database host, if other than localhost

In addition, you should supply one of the following options:

   library  full path to your iTunes Music Library.xml file
   dirs     full path to directories containing MP3s to read
   files    full path to directories containing flat files of information
   cols     (if the files option is provided, pass an ordered list of column names)

To create a database using an itunes XML file and mysql:
  create_database -adaptor dbi::mysql -dsn new_library -library Music/Library.xml

To create a database by reading the ID3 tags directly (MP3s ONLY!):
   create_database -adaptor dbi::mysql -dsn new_library -dirs /Music/ /temp/

To create a database from a flatfile of information:
   create_database -adaptor dbi::mysql -dsn new_library -files Documents/music_info.txt \
                   -cols album artist track title total_tracks

Columns should correspond to those found in in the data hash.  See the
section describing the load_database method of Audio::DB::Build.

=head1 AUTHOR

 Todd Harris (harris@cshl.org);
 $Id: create_database.PLS,v 1.1 2005/02/27 16:56:25 todd Exp $

=cut

!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
