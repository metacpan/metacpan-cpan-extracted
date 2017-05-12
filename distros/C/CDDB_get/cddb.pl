#!/usr/bin/perl -I.
#
#  CDDB - Read the CDDB entry for an audio CD in your drive
#
#  This module/script gets the CDDB info for an audio cd. You need
#  LINUX, a cdrom drive and an active internet connection in order
#  to do that.
#
#  (c) 2004 Armin Obersteiner <armin@xos.net>
#
#  LICENSE
#
#  This library is released under the same conditions as Perl, that
#  is, either of the following:
#
#  a) the GNU General Public License Version 2 as published by the
#  Free Software Foundation,
#
#  b) the Artistic License.
#

#use CDDB_get qw( get_cddb get_discids );

use Data::Dumper;
use Getopt::Std;

use strict;

my %option = ();
getopts("oghdtsi:SfDlOFc:H:CIRGP", \%option); 

if($option{h}) {
  print "$0: gets CDDB info of a CD\n";
  print "  no argument - gets CDDB info of CD in your drive\n";
  print "  -c  device (other than default device)\n";
  print "  -o  offline mode - just stores CD info\n";
  print "  -d  output in xmcd format\n";
  print "  -s  save in xmcd format\n";
  print "  -i  db. one of: mysql, pg, oracle, sqlite\n";
  print "  -O  overwrite file or db\n";
  print "  -t  output toc\n";
  print "  -l  output lame command\n";
  print "  -f  http mode (e.g. through firewalls)\n";
  print "  -F  some stateful firewalls/http proxies need additional newlines\n";
  print "  -g  get CDDB info for stored CDs\n";
  print "  -I  non interactive mode\n";
  print "  -H  CDDB hostname\n";
  print "  -C  use local cache\n";
  print "  -R  readonly cache\n";
  print "  -G  cache has not the diskid as filenames (much slower)\n";
  print "  -P  cache path (default: /tmp/xmcd)\n";
  print "  -D  put CDDB_get in debug mode\n";
  exit;
}

my %config;

my $diskid;
my $total;
my $toc;
my $savedir="/tmp/cddb";
my $xmcddir="/tmp/xmcd";

if($option{C}) {
  # use CDDB_cache qw( get_cddb get_discids );
  require CDDB_cache;
  CDDB_cache->import( qw( get_cddb get_discids ) );

  $CDDB_cache::debug=1 if($option{D});
  $CDDB_cache::readonly=1 if($option{R});
  $CDDB_cache::grep=1 if($option{G});

  $CDDB_cache::dir="/tmp/xmcd"; # default
  # $CDDB_cache::dir="/opt/kde2/share/apps/kscd/cddb";
  $CDDB_cache::dir=$option{P} if($option{P});

} else {
  # use CDDB_get qw( get_cddb get_discids );
  require CDDB_get;
  CDDB_get->import( qw( get_cddb get_discids ) );
}

$CDDB_get::debug=1 if($option{D});

# following variables just need to be declared if different from defaults
# defaults are listed below (cdrom default is os specific)

# $config{CDDB_HOST}="freedb.freedb.org";	# set cddb host
if($option{H}) {
  $config{CDDB_HOST}=$option{H};
}
# $config{CDDB_PORT}=8880; 			# set cddb port
# $config{CDDB_MODE}="cddb";			# set cddb mode: cddb or http, this is switched with -f
# $config{CD_DEVICE}="/dev/cdrom";		# set cd device

# $config{HELLO_ID} ="root nowhere.com fastrip 0.77"; # hello string: username hostname clientname version
# $config{PROTO_VERSION} = 5; # cddb protokol version


# get proxy settings for cddb mode

$config{HTTP_PROXY}=$ENV{http_proxy} if $ENV{http_proxy}; # maybe wanna use a proxy ?

$config{CDDB_MODE}="http" if($option{f}); 
if($option{F}) {
  $config{CDDB_MODE}="http";
  $config{FW}=1;
}

$config{CD_DEVICE}=$option{c} if $option{c};

# user interaction welcome?

$config{input}=1;   # 1: ask user if more than one possibility
                    # 0: no user interaction
$config{multi}=0;   # 1: do not ask user and get all of them
                    # 0: just the first one

$config{input}=0 if($option{I});

my %db;

if($option{i}) {
  require DBI;

  $db{table_cds} = "cds";
  $db{table_tracks} = "tracks";

  # not needed for sqlite
  $db{host} = "localhost";
  $db{port} = "3306";

  # not needed for oracle/sqlite
  $db{name} = "mp3-test";

  # just for oracle
  $db{sid} = "xxx";
  $db{home} = "xxx";

  # just for sqlite
  $db{file} = "xxx";

  # not needed for sqlite
  $db{user} = "root";
  $db{passwd} = "xxx";


  if($option{i} eq "mysql") {
    $db{connect} = sub { "dbi:mysql:database=$db{name};host=$db{host};port=$db{port}", $db{user}, $db{passwd} };
  } elsif($option{i} eq "pg") {
    $db{connect} = sub { "dbi:Pg:dbname=$db{dbname};host=$db{host};port=$db{port}", $db{user}, $db{passwd} };
  } elsif($option{i} eq "oracle") {
    $db{connect} = sub { "dbi:Oracle:host=$db{host};sid=$db{sid};port=$db{port}", $db{user}, $db{passwd} };
    $ENV{ORACLE_HOME} = $db{home};
  } elsif($option{i} eq "sqlite") {
    $db{connect} = sub { "dbi:SQLite:dbname=$db{file}","","" };
  } else {
    die "unkown database: $option{i}";
  }
}
  
if($option{o}) {
  my $ids=get_discids($config{CD_DEVICE});

  unless(-e $savedir) {
    mkdir $savedir,0755 or die "cannot create $savedir";
  }

  open OUT,">$savedir/$ids->[0]\_$$" or die "cannot open outfile";
  print OUT Data::Dumper->Dump($ids,["diskid","total","toc"]);
  close OUT;

  print STDERR "saved in: $savedir/$ids->[0]\_$$\n";
  exit;
}

if($option{g}) {
  print STDERR "retrieving stored cds ...\n";

  opendir(DIR, $savedir) or die "cannot opendir $savedir";
  while (defined(my $file = readdir(DIR))) {
    next if($file =~ /^\./);
    print "\n";

    my $in=`/bin/cat $savedir/$file`;
    my $exit  = $? >> 8; 

    if($exit>0) {
      die "error reading file";
    }

    unless($in=~ m/^\$diskid\s+=\s+('\d+'|\d+);\s+         # $diskid
                    \$total\s+=\s+('\d+'|\d+);\s+          # $total
                    \$toc\s+=\s+\[\s+                      # $toc
                      (\{\s+
                        ('(frame|frames|min|sec|data)'\s+=\>\s+('\d+'|\d+)(,|)\s+){5}
                      \}(,|)\s+)+
                    \];\s+$/xs) {
      print "not a save file: $savedir/$file\n";
      next;                 
    }

    eval $in;

    if($@) {
      print "not a save file (eval error): $savedir/$file\n";
      next;
    }

    my %cd=get_cddb(\%config,[$diskid,$total,$toc]);

    unless(defined $cd{title}) {
      print "no cddb entry found: $savedir/$file\n";
    }

    unlink "$savedir/$file";

    next unless defined $cd{title};

    if($option{d} || $option{s}) {
      print_xmcd(\%cd,$option{s});
    } elsif($option{i}) {
      insert_db(\%cd,\%db);
    } elsif($option{l}) {
      print_lame(\%cd);
    } else {
      print_cd(\%cd);
    }
  }
  closedir(DIR);
  exit;
}

# get it on

unless($config{multi}) {
  my %cd;

  # for those who don't like 'die' in modules ;-)
  eval { 
    %cd = get_cddb(\%config);
  };
  if ($@) {
    print "fatal error: $!\n";
    exit;
  }

  print Dumper(\%cd) if $option{D};

  unless(defined $cd{title}) {
    die "no cddb entry found";
  }

  # do somthing with the results

  if($option{d} || $option{s}) {
    print_xmcd(\%cd,$option{s});
  } elsif($option{i}) {
    insert_db(\%cd,\%db);
  } elsif($option{l}) {
    print_lame(\%cd);
  } else {
    print_cd(\%cd);
  }
} else { 
  my @cd;

  # for those who don't like 'die' in modules ;-)
  eval { 
    @cd=get_cddb(\%config);
  };
  if ($@) {
    print "fatal error: $!\n";
    exit;
  }

  print Dumper(\@cd) if $option{D};

  for my $c (@cd) {
    unless(defined $c->{title}) {
      die "no cddb entry found";
    }

    # do somthing with the results

    if($option{d} || $option{s}) {
      print_xmcd($c,$option{s});
    } elsif($option{i}) {
      insert_db($c,\%db);
    } elsif($option{l}) {
      print_lame($c);
      print "\n";
    } else {
      print_cd($c);
      print "\n";
    }
  }
}

exit;


# subroutines

sub print_cd {
  my $cd=shift;

  print "artist: $cd->{artist}\n";
  print "title: $cd->{title}\n";
  print "category: $cd->{cat}\n";
  print "genre: $cd->{genre}\n" if($cd->{genre});
  print "year: $cd->{year}\n" if($cd->{year});
  print "cddbid: $cd->{id}\n";
  print "trackno: $cd->{tno}\n";

  my $n=1;
  foreach my $i ( @{$cd->{track}} ) {
    if($option{t}) {
      my $from=$cd->{frames}[$n-1];
      my $to=$cd->{frames}[$n]-1;
      my $dur=$to-$from;
      my $min=int($dur/75/60);
      my $sec=int($dur/75)-$min*60;
      my $frm=($dur-$sec*75-$min*75*60)*100/75;
      my $out=sprintf "track %2d: %8d - %8d  [%2d:%.2d.%.2d]: $i\n",$n,$from,$to,$min,$sec,$frm;
      print "$out"; 
    } else {
      print "track $n: $i\n";
    }
    $n++;
  }  
}

sub print_xmcd {
  my $cd=shift;
  my $save=shift;

  *OUT=*STDOUT;

  if($save) {
    unless(-e $xmcddir) {
      mkdir $xmcddir,0755 or die "cannot create $savedir";
    }

    unless($option{O}) {
      if(-e "$xmcddir/$cd->{id}") {
        print "XMCD file exists\n";
        exit;
      }
    }

    open XMCD,">$xmcddir/$cd->{id}" or die "cannot open outfile";
    *OUT=*XMCD;
  }

  for(@{$cd->{raw}}) {
    print OUT "$_";
  }

  if($save) {
    print STDERR "saved in: $xmcddir/$cd->{id}\n";
    close OUT;
  }
}  

sub insert_db {
  my $cd=shift;
  my $db=shift;

  my ($artist, $title, $category, $cddbid, $trackno) =
    ($cd->{artist}, $cd->{title}, $cd->{cat}, $cd->{id}, $cd->{tno});

  my $sql = "SELECT cddbid FROM $db->{table_cds} WHERE CDDBID = \'$cddbid\'";
  my $dbh = DBI->connect($db->{connect}->()) or die "cannot connect to db: $DBI::errstr";
  my $sth = $dbh->prepare($sql);
  my $r = $sth->execute or die "cannot check for cd: $DBI::errstr";
  if ($r == 1) {
    print "cd already in db\n";
    if($option{O}) {
      my $sql = "DELETE FROM $db->{table_cds} WHERE CDDBID = \'$cddbid\'";
      my $sth = $dbh->prepare($sql);
      my $r = $sth->execute or die "cannot delete from $db->{table_cds}: $DBI::errstr";
      $sql = "DELETE FROM $db->{table_tracks} WHERE CDDBID = \'$cddbid\'";
      $sth = $dbh->prepare($sql);
      $r = $sth->execute or die "cannot delete from $db->{table_tracks}: $DBI::errstr";
    } else {
      exit;
    }
  }

  $title =~ s/'/\\'/g;
  $artist =~ s/'/\\'/g;
  $category =~ s/'/\\'/g;

  $sql = "INSERT INTO $db->{table_cds} (cddbid, artist, title, category, tracks) VALUES (\'$cddbid\', \'$artist\', \'$title\', \'$category\' , \'$trackno\')";
  $sth = $dbh->prepare($sql);
  $r = $sth->execute or die "failed to insert cd: $DBI::errstr";

  my $n=1;

  print "titel: $title\n";
  print "artist: $artist\n";
  print "category: $category\n\n";

  for my $t ( @{$cd->{track}} ) {
    $t =~ s/'/\\'/g;
    my $dur=($cd->{frames}[$n]-1-$cd->{frames}[$n-1])/75;
    my $hour=int($dur/3600);
    my $min=int($dur/60-$hour*60);
    my $sec=$dur-$hour*3600-$min*60;
    my $fr=substr(sprintf("%5.2f",$sec-int($sec)),2,3);
    my $time=sprintf "%.2d:%.2d:%.2d%s",$hour,$min,int($sec),$fr;

    print "track $n: $t  [$time]\n";
    
    my $sql = "INSERT INTO $db->{table_tracks} (cddbid, title, trackno, time) 
               VALUES (\'$cddbid\',\'$t\', \'$n\', \'$time\')";
    my $sth = $dbh->prepare($sql);
    my $r = $sth->execute or die "failed to insert track $n: $DBI::errstr";
    $n++;
  }

  $dbh->disconnect();
} 

sub print_lame {
  my $cd=shift;

  print_cd($cd);
  print "\n";

  my $n=1;
  for my $i ( @{$cd->{track}} ) {
    $i =~ s/"/'/g;
    print 'lame --tl "'.$cd->{title}.'" --ta "'.$cd->{artist}.'" --tt "'.$i.'" ';
    printf "audio_%02d.wav ",$n;
    $i =~ s/[^\S]|['"\/]/_/g;
    $i =~ s/_+-_+/-/g;
    print " $i.mp3\n";
    $n++;
  }
}
