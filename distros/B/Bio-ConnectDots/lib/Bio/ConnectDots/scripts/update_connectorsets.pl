# Updates the current connectorsets by 
# downloading the new version of a database, unloading the old version and
# loading in the new version.

use Data::Dumper;

use Carp;
use lib qw( ../lib ../../..);
use Getopt::Long;
use File::Path;
use Bio::ConnectDots::Config;
use Bio::ConnectDots::DB;
use Net::FTP::Common;
use File::stat;
use strict;

my($HELP,$VERBOSE,$ECHO_CMD,$DATABASE,$HOST,$USER,$PASSWORD,$LOADDIR,$LOADSAVE,$CONNECTORSET,$REMOVEDOTS,$VERSION,$REMOVEOLD,$CONNECTORSET);

GetOptions ('help' => \$HELP,
	    'verbose' => \$VERBOSE,
	    'X|echo' => \$ECHO_CMD,
	    'database=s'=>\$DATABASE,
            'db=s'=>\$DATABASE,
            'host=s'=>\$HOST,
            'user=s'=>\$USER,
            'password=s'=>\$PASSWORD,
	    'loaddir=s'=>\$LOADDIR,
	    'loadsave=s'=>\$LOADSAVE,
		'removeold=s'=>\$REMOVEOLD,
		'connectorset=s'=>\$CONNECTORSET
	   ) and !$HELP or die <<USAGE;
Usage: $0 [options] 

Options
-------
   --help		Print this message
   --verbose		(for testing)
   -X or --echo		Echo command line (for testing and use in scripts)
  --database            Postgres database (default: --user)
  --db                  Synonym for --database
  --host                Postgres database (default: socks)
  --user                Postgres user (default: ngoodman)
  --password            Postgres password (default: undef)
  --loaddir             Directory for load files (default: /usr/tmp/user_name)
  --loadsave            Specifies whether to save load files
                        Options: 'none', 'last', 'all'. Default: 'none'
  --connectorset		Specifies the name of the ConnectorSet to update (default is all)
  --removeold			automatically remove old connectorset version. Default is to retain.

Options  may be abbreviated.  Values are case insenstive.

USAGE
;

my $dbinfo = Bio::ConnectDots::Config::db('production');
$HOST or $HOST=$dbinfo->{host};
$USER or $USER=$dbinfo->{user};
$PASSWORD or $PASSWORD=$dbinfo->{password};
$DATABASE or die "Must provide a database to update: --database name";

# locals
my ($current_year) = localtime() =~ /(....)$/;
my %month2num = ('jan',1,'feb',2,'mar',3,'apr',4,'may',5,'jun',6,'jul',7,'aug',8,'sep',9,'oct',10,'nov',11,'dec',12);

print "### Checking for new versions of installed ConnectorSets\n";

my $db=new Bio::ConnectDots::DB
  (-database=>$DATABASE,-host=>$HOST,-user=>$USER,-password=>$PASSWORD,-ext_directory=>$LOADDIR);
my $dbh = $db->{dbh};


### process list of connectorsets
my $iterator = $dbh->prepare("SELECT name,file_name,version,ftp,ftp_files FROM connectorset");
$iterator->execute();
while( my ($cs_name,$localfile,$version,$ftpsite,$ftp_files) = $iterator->fetchrow_array() ) {
	if($ftpsite && $ftp_files) {
		if($CONNECTORSET) { next unless $cs_name eq $CONNECTORSET; } # limit to one CS
		print "### Checking for new version of $cs_name from $ftpsite\n";
		my $directories = parse_files($ftp_files); # hash on directory of a list of files to get.
		
		# determine version of local file
		my $local_version = get_file_date($localfile);
		
		# initialize the ftp server
		my %netftp_cfg = (Debug => 0, Timeout => 120);
		my %common_cfg = (   User => 'anonymous',           
						     Pass => 'anonymous@here.net',      
						     Host => $ftpsite,
						     RemoteDir  => '/',              # automatic CD on remote machine to RemoteDir
						     Type => 'A'                     # overwrite I (binary) TYPE default
					     );
		my $ftp = Net::FTP::Common->new(\%common_cfg, %netftp_cfg);

		# check files exist and if new
		my $existnew=0; # true if any files are newer than local file
		my $errorCs=0; # true if can't file all files
		my $newversion; 
		foreach my $dir (keys %$directories) {
			my %ls = $ftp->dir(RemoteDir=>$dir);
			# check if files exist and if newer
			foreach my $file (@{$directories->{$dir}}) {	
				if ($ftp->exists(RemoteDir=>$dir, RemoteFile=>$file)) {
					my %remote_version;
					$remote_version{month} = $month2num{ lc($ls{$file}->{month}) };
					$remote_version{day} = $ls{$file}->{day};
					$remote_version{year} = $ls{$file}->{yearOrTime};
					$remote_version{year} = $current_year if $remote_version{year} =~ /:/;
					$newversion .= '_' if $newversion;
					$newversion .= cat_date(\%remote_version);
					$existnew=1 if is_new($local_version, \%remote_version);
				} else {
					print "### ERROR ($cs_name): File ". $ftpsite.$dir.$file ." does not exist! Can NOT update $cs_name\n";
					$errorCs=1;
				}				
			}
		}
		next if $errorCs; # can not download all the required files so skip
		
		# download files if needed
		if($existnew) {
			print "### Downloading $cs_name from $ftpsite: $ftp_files\n";
			my @cat_files;
			foreach my $dir (keys %$directories) {
				foreach my $file (@{$directories->{$dir}}) {	
					my $localdir = "/tmp";
					print "# Downloading file: $file\n";
					$ftp->get(RemoteDir=>$dir, RemoteFile=>$file, LocalDir=>$localdir);
					
					# unzip if needed
					if($file =~ /\.gz$/) {
						system "gunzip $localdir/$file";
						$file =~ s/\.gz$//i;	
					} elsif ($file =~ /\.z$/i || $file =~ /\.zip$/i) {
						system "unzip $localdir/$file";	
						$file =~ s/\.z(.{2})*$//i;	
					}
					push @cat_files, "$localdir/$file";
				}
			}
			
			# concatenate multiple downloaded files into db file if needed
			if(@cat_files > 1) {
				my $catcmd = "cat ". join(' ', @cat_files) ." > $localfile";
				my $rmcmd = "rm ". join(' ', @cat_files);
				system "$catcmd";
				system "$rmcmd";
			} elsif(@cat_files == 1) {
				system "mv ". $cat_files[0] ." $localfile";
			} else {
				print "### ERROR ($cs_name): Problem with downloaded files\n";
			}			
			
			# reload the connectorset into connect the dots database
			system "perl unload.pl --connectorset $cs_name" if $REMOVEOLD;
			modify_cnf_version($cs_name,$newversion);
			my $loadcmd = "perl load.pl --database $DATABASE --user $USER ";
			$loadcmd .= " --password ". $PASSWORD if $PASSWORD;
			$loadcmd .= " ../ConnectorSet/$cs_name.cnf $localfile";
			system "$loadcmd";
			
		} # end exist new		
	} # end if ftp attributes exist
} # end fetchrow loop 



# recieves a comma seperated list of files with their direct paths
# returns a hashref keyed on directory, value is filename
sub parse_files {
	my ($ftp_files) = @_;
	my %files;
	my @entries = split(/,/, $ftp_files);
	foreach (@entries) {
		my ($dir,$file) = /(.*\/)(.+)$/;
		push @{$files{$dir}}, $file;
	}	
	return \%files;
}

# recieves a file and returns hashref of day,month,year it was last modified in the local file system
sub get_file_date {
	my ($filename) = @_;
	my %out;
	open(FILE,$filename) or die "Can not open $filename\n";
	my $stat = stat($filename);
	my $lastmodified = $stat->mtime;
	my @times = localtime($lastmodified);
	$out{day} = $times[3];
	$out{month} = $times[4];
	$out{year} = $times[5]+1900;
	return \%out;
}

# returns true when remote(year,month,day) is newer than local
sub is_new {
	my ($local, $remote) = @_;
	return 0 unless $local && $remote;
	my $ldate = cat_date($local);
	my $rdate = cat_date($remote);
	return 1 if $rdate > $ldate;
	return 0;
}

# returns concatentated data
sub cat_date {
	my $remote = shift;
	my $return = $remote->{year};
	if($remote->{month} < 10) {
		$return .= 	'0'. $remote->{month};
	} else {
		$return .= 	$remote->{month};
	}
	if($remote->{day} < 10) {
		$return .= 	'0'. $remote->{day};
	} else {
		$return .= 	$remote->{day};
	}
	return $return;	
}

sub modify_cnf_version {
	my ($cs_name, $newversion) = @_;
	my $filename = "../ConnectorSet/$cs_name.cnf";
	my @lines;
	open(IN, "$filename")  or die "Can not open $filename\n";
	while(<IN>) {
		if(/^version/) {
			push @lines, "version=$newversion\n";
		} else {
			push @lines, $_;	
		}
	}
	close(IN);
	open(OUT, ">$filename") or die "Can not open $filename for writing\n";
	foreach (@lines) {
		print OUT $_;	
	}
	close(OUT);
}





