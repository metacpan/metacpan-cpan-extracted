use strict;
use warnings;
use LWP::Simple;

#======================================================================
# data: sample databases
#======================================================================
my $chinook_zip = "ChinookDatabase1.4_Sqlite.zip";
my %databases = (

  sakila  => {
    source => "http://sakila-sample-database-ports.googlecode.com/svn/trunk/ sakila-sample-database-ports/sqlite-sakila-db/sqlite-sakila.sq",
    dest   => "Sakila/sakila.sqlite",
  },

  chinook => {
    source => "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=chinookdatabase&DownloadId=557773&FileTime=129989782797830000&Build=20907",
    dest   => $chinook_zip,
    hook   => sub {
      use Archive::Zip;
      my $member  = "Chinook_Sqlite_AutoIncrementPKs.sqlite";
      my $zip = Archive::Zip->new($chinook_zip);
      $zip->extractMember($member, "Chinook/$member");
      undef $zip;
      unlink $chinook_zip;
    },
  },

 );


#======================================================================
# download
#======================================================================

# choose databases to download
my @to_download = @ARGV ? @ARGV : keys %databases;

# download each database
foreach my $db_name (@to_download) {
  my $db = $databases{$db_name}
    or die "unknown database : $db_name";
  print STDERR "downloading $db_name ...";
  mirror($db->{source}, $db->{dest});
  $db->{hook}->() if $db->{hook};
  print STDERR "done\n";
}



