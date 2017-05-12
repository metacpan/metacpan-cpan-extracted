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

package CDDB_get;

use Config;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $debug);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
  get_cddb
  get_discids
);
$VERSION = '2.28';

use Fcntl;
use IO::Socket;
use Data::Dumper qw(Dumper);
use MIME::Base64 qw(encode_base64);

$debug=1;

# setup for linux, solaris x86, solaris spark
# you freebsd guys give me input 

print STDERR "cddb: checking for os ... " if $debug;

my $os=`uname -s`;
my $machine=`uname -m`;
chomp $os;
chomp $machine;

print STDERR "$os ($machine) " if $debug;

# cdrom IOCTL magic (from c headers)
# linux x86 is default

# /usr/include/linux/cdrom.h
my $CDROMREADTOCHDR=0x5305;
my $CDROMREADTOCENTRY=0x5306;
my $CDROM_MSF=0x02;

# default config

my $CDDB_HOST = "freedb.freedb.org";
my $CDDB_PORT = 8880;
my $CDDB_MODE = "cddb";
my $CD_DEVICE = "/dev/cdrom";

my $HELLO_ID  = "root nowhere.com fastrip 0.77";
my $PROTO_VERSION = 5;

# endian check

my $BIG_ENDIAN = unpack("h*", pack("s", 1)) =~ /01/;

if($BIG_ENDIAN) { 
  print STDERR "[big endian] " if $debug;
} else {
  print STDERR "[little endian] " if $debug;
}

# 64bit pointer check

my $BITS_64 = $Config{ptrsize} == 8 ? 1 : 0;

if($BITS_64) {
  print STDERR "[64 bit]\n" if $debug;
} else {
  print STDERR "[32 bit]\n" if $debug;
}

if($os eq "SunOS") {
  # /usr/include/sys/cdio.h

  $CDROMREADTOCHDR=0x49b;	# 1179
  $CDROMREADTOCENTRY=0x49c;	# 1180

  if(-e "/vol/dev/aliases/cdrom0") {
    $CD_DEVICE="/vol/dev/aliases/cdrom0";
  } else {
    if($machine =~ /^sun/) {  
      # on sparc and old suns
      $CD_DEVICE="/dev/rdsk/c0t6d0s0";
    } else {
      # on intel 
      $CD_DEVICE="/dev/rdsk/c1t0d0p0";
    }
  }
} elsif($os =~ /BSD/i) {  # works for netbsd, infos for other bsds welcome
  # /usr/include/sys/cdio.h

  $CDROMREADTOCHDR=0x40046304;
  $CDROMREADTOCENTRY=0xc0086305;

  if($BITS_64) {
    $CDROMREADTOCENTRY=0xc0106305;
  }

  $CD_DEVICE="/dev/cd0a";

  if($os eq "OpenBSD") {
    $CD_DEVICE="/dev/cd0c";
  }
}

sub read_toc {
  my $device=shift;
  my $tochdr=chr(0) x 16;

  sysopen (CD,$device, O_RDONLY | O_NONBLOCK) or die "cannot open cdrom [$!] [$device]";
  ioctl(CD, $CDROMREADTOCHDR, $tochdr) or die "cannot read toc [$!] [$device]";
  my ($start,$end);
  if($os =~ /BSD/) {
    ($start,$end)=unpack "CC",(substr $tochdr,2,2);
  } else {
    ($start,$end)=unpack "CC",$tochdr;
  }
  print STDERR "start track: $start, end track: $end\n" if $debug;

  my @tracks=();

  for (my $i=$start; $i<=$end;$i++) {
    push @tracks,$i;
  }
  push @tracks,0xAA;

  my @r=();
  my $tocentry;
  my $toc="";
  my $size=0;
  for(@tracks) {
    $toc.="        ";
    $size+=8;
  }
 
  if($os =~ /BSD/) { 
    my $size_hi=int($size / 256);
    my $size_lo=$size & 255;      

    if($BIG_ENDIAN) {
      if($BITS_64) {
        # better but just perl >= 5.8.0
        # $tocentry=pack "CCCCx![P]P", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
        $tocentry=pack "CCCCxxxxP", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
      } else {
        $tocentry=pack "CCCCP8l", $CDROM_MSF,0,$size_hi,$size_lo,$toc; 
      }
    } else {
      if($BITS_64) {
        $tocentry=pack "CCCCxxxxP", $CDROM_MSF,0,$size_lo,$size_hi,$toc; 
      } else {
        $tocentry=pack "CCCCP8l", $CDROM_MSF,0,$size_lo,$size_hi,$toc; 
      }
    }
    ioctl(CD, $CDROMREADTOCENTRY, $tocentry) or die "cannot read track info [$!] [$device]";
  }

  my $count=0;
  foreach my $i (@tracks) {
    my ($min,$sec,$frame);
    unless($os =~ /BSD/) {
      $tocentry=pack "CCC", $i,0,$CDROM_MSF;
      $tocentry.=chr(0) x 16;
      ioctl(CD, $CDROMREADTOCENTRY, $tocentry) or die "cannot read track $i info [$!] [$device]";
      ($min,$sec,$frame)=unpack "CCCC", substr($tocentry,4,4);
    } else {
      ($min,$sec,$frame)=unpack "CCC", substr($toc,$count+5,3);
    } 
    $count+=8;

    my %cdtoc=();
 
    $cdtoc{min}=$min;
    $cdtoc{sec}=$sec;
    $cdtoc{frame}=$frame;
    $cdtoc{frames}=int($frame+$sec*75+$min*60*75);

    my $data = unpack("C",substr($tocentry,1,1)); 
    $cdtoc{data} = 0;
    if($data & 0x40) {
      $cdtoc{data} = 1;
    } 

    push @r,\%cdtoc;
  }   
  close(CD);
 
  return @r;
}                                      

sub cddb_sum {
  my $n=shift;
  my $ret=0;

  while ($n > 0) {
    $ret += ($n % 10);
    $n = int $n / 10;
  }
  return $ret;
}                       

sub cddb_discid {
  my $total=shift;
  my $toc=shift;

  my $i=0;
  my $t=0;
  my $n=0;
  
  while ($i < $total) {
    $n = $n + cddb_sum(($toc->[$i]->{min} * 60) + $toc->[$i]->{sec});
    $i++;
  }
  $t = (($toc->[$total]->{min} * 60) + $toc->[$total]->{sec}) -
      (($toc->[0]->{min} * 60) + $toc->[0]->{sec});
  return (($n % 0xff) << 24 | $t << 8 | $total);
}                                       

sub get_discids {
  my $cd=shift;
  $CD_DEVICE = $cd if (defined($cd));

  my @toc=read_toc($CD_DEVICE);
  my $total=$#toc;

  my $id=cddb_discid($total,\@toc);

  return [$id,$total,\@toc];
}

sub get_cddb {
  my $config=shift;
  my $diskid=shift;
  my $id;
  my $toc;
  my $total;
  my @r;

  my $input = $config->{input};
  my $multi = $config->{multi};
  $input = 0 if $multi;

  print STDERR Dumper($config) if $debug;

  $CDDB_HOST = $config->{CDDB_HOST} if (defined($config->{CDDB_HOST}));
  $CDDB_PORT = $config->{CDDB_PORT} if (defined($config->{CDDB_PORT}));
  $CDDB_MODE = $config->{CDDB_MODE} if (defined($config->{CDDB_MODE}));
  $CD_DEVICE = $config->{CD_DEVICE} if (defined($config->{CD_DEVICE}));
  $HELLO_ID  = $config->{HELLO_ID} if (defined($config->{HELLO_ID}));
  $PROTO_VERSION  = $config->{PROTO_VERSION} if (defined($config->{PROTO_VERSION}));
  my $HTTP_PROXY = $config->{HTTP_PROXY} if (defined($config->{HTTP_PROXY}));
  my $FW=1 if (defined($config->{FW}));
 
  if(defined($diskid)) {
    $id=$diskid->[0];
    $total=$diskid->[1];
    $toc=$diskid->[2];
  } else {
    my $diskid=get_discids($CD_DEVICE);
    $id=$diskid->[0];
    $total=$diskid->[1];
    $toc=$diskid->[2];
  }

  my @list=();
  my $return;
  my $socket;

  my $id2 = sprintf "%08x", $id;
  my $query = "cddb query $id2 $total";
  for (my $i=0; $i<$total ;$i++) {
      $query.=" $toc->[$i]->{frames}";
  }

  # this was to old total calculation, does not work too well, its included if new version makes problems
  # $query.=" ". int(($toc->[$total]->{frames}-$toc->[0]->{frames})/75);

  $query.=" ". int(($toc->[$total]->{frames})/75);

  print Dumper($toc) if $debug;

  if ($CDDB_MODE eq "cddb") {
    print STDERR "cddb: connecting to $CDDB_HOST:$CDDB_PORT\n" if $debug;

    $socket=IO::Socket::INET->new(PeerAddr=>$CDDB_HOST, PeerPort=>$CDDB_PORT,
        Proto=>"tcp",Type=>SOCK_STREAM) or die "cannot connect to cddb db: $CDDB_HOST:$CDDB_PORT [$!]";

    $return=<$socket>;
    unless ($return =~ /^2\d\d\s+/) {
      die "not welcome at cddb db";
    }

    print $socket "cddb hello $HELLO_ID\n";

    $return=<$socket>;
    print STDERR "hello return: $return" if $debug;
    unless ($return =~ /^2\d\d\s+/) {
      die "handshake error at cddb db: $CDDB_HOST:$CDDB_PORT";
    }

    print $socket "proto $PROTO_VERSION\n";

    $return=<$socket>;
    print STDERR "proto return: $return" if $debug;
    unless ($return =~ /^2\d\d\s+/) {
      die "protokoll mismatch error at cddb db: $CDDB_HOST:$CDDB_PORT";
    }
 
    print STDERR "cddb: sending: $query\n" if $debug;
    print $socket "$query\n";

    $return=<$socket>;
    chomp $return;

    print STDERR "cddb: result: $return\n" if $debug;
  } elsif ($CDDB_MODE eq "http") {
    my $query2=$query;
    $query2 =~ s/ /+/g;
    my $id=$HELLO_ID;
    $id =~ s/ /+/g;

    my $url = "/~cddb/cddb.cgi?cmd=$query2&hello=$id&proto=$PROTO_VERSION";

    my $host=$CDDB_HOST;
    my $port=80;

    my ($user,$pass);

    if($HTTP_PROXY) {
      if($HTTP_PROXY =~ /^(http:\/\/|)(.+?):(.+)\@(.+?):(.+)/) {
        $user=$2;
        $pass=$3;
        $host=$4;
        $port=$5;
      } elsif($HTTP_PROXY =~ /^(http:\/\/|)(.+?):(\d+)/) {
        $host=$2;
        $port=$3;
      }
      $url="http://$CDDB_HOST".$url." HTTP/1.0";
    }

    print STDERR "cddb: connecting to $host:$port\n" if $debug;

    $socket=IO::Socket::INET->new(PeerAddr=>$host, PeerPort=>$port,
        Proto=>"tcp",Type=>SOCK_STREAM) or die "cannot connect to cddb db: $host:$port [$!]";

    print STDERR "cddb: http send: GET $url\n" if $debug;
    print $socket "GET $url\n";

    if($user) {
      my $cred = encode_base64("$user:$pass");
      print $socket "Proxy-Authorization: Basic $cred\n";
    }

    print $socket "\n";
    print $socket "\n" if $FW;

    if($HTTP_PROXY) {
      while(<$socket> =~ /^\S+/){};
    }

    $return=<$socket>;
    chomp $return;

    print STDERR "cddb: http result: $return\n" if $debug;
  } else {
    die "unkown mode: $CDDB_MODE for querying cddb";
  }

  $return =~ s/\r//g;

  my ($err) = $return =~ /^(\d\d\d)\s+/;
  unless ($err =~ /^2/) {
    die "query error at cddb db: $CDDB_HOST:$CDDB_PORT";
  }

  if($err==202) {
    return undef;
  } elsif(($err==211) || ($err==210)) {
    while(<$socket>) {
      last if(/^\./);
      push @list,$_;
      s/\r//g;
      print STDERR "unexact: $_" if $debug;
    } 
  } elsif($err==200) {
    $return =~ s/^200 //;
    push @list,$return;
  } else {
    die "cddb: unknown: $return";
  }

  my @to_get;

  unless($multi) {
    if (@list) { 
      my $index;
      if($input==1) {
        print "This CD could be:\n\n";
        my $i=1;
        for(@list) {
          my ($tit) = $_ =~ /^\S+\s+\S+\s+(.*)/;
          print "$i: $tit\n";
          $i++
        }
        print "\n0: none of the above\n\nChoose: ";
        my $n=<STDIN>;
        $index=int($n);
      } else {
        $index=1;
      } 

      if ($index == 0) {
        return undef;
      } else {
        push @to_get,$list[$index-1];
      }
    }
  } else {
    push @to_get,@list;
  }

  my $i=0;
  for my $get (@to_get) {
    #200 misc 0a01e802 Meredith Brooks / Bitch Single 
    my ($cat,$id,$at) = $get =~ /^(\S+?)\s+(\S+?)\s+(.*)/;

    my $artist;
    my $title;

    if($at =~ /\//) {
      ($artist,$title)= $at =~ /^(.*?)\s\/\s(.*)/;
    } else {
      $artist=$at;
      $title=$at;
    }

    my %cd=();
    $cd{artist}=$artist;
    chomp $title;
    $title =~ s/\r//g;
    $cd{title}=$title;
    $cd{cat}=$cat;
    $cd{id}=$id;

    my @lines;

    $query="cddb read $cat $id";

    if ($CDDB_MODE eq "cddb") {
      print STDERR "cddb: getting: $query\n" if $debug;
      print $socket "$query\n";

      while(<$socket>) {
        last if(/^\./);
        push @lines,$_;
      }
      if(@to_get-1 == $i) {
        print $socket "quit\n";
        close $socket;
      }

    } elsif ($CDDB_MODE eq "http") {
      close $socket;

      my $query2=$query;
      $query2 =~ s/ /+/g;
      my $id=$HELLO_ID;
      $id =~ s/ /+/g;

      my $url = "/~cddb/cddb.cgi?cmd=$query2&hello=$id&proto=$PROTO_VERSION";

      my $host=$CDDB_HOST;
      my $port=80;

      my ($user,$pass);

      if($HTTP_PROXY) {
        if($HTTP_PROXY =~ /^(http:\/\/|)(.+?):(.+)\@(.+?):(.+)/) {
          $user=$2;
          $pass=$3;
          $host=$4;
          $port=$5;
        } elsif($HTTP_PROXY =~ /^(http:\/\/|)(.+?):(\d+)/) {
          $host=$2;
          $port=$3;
        }
        $url="http://$CDDB_HOST".$url." HTTP/1.0";
      }

      print STDERR "cddb: connecting to $host:$port\n" if $debug;

      $socket=IO::Socket::INET->new(PeerAddr=>$host, PeerPort=>$port,
        Proto=>"tcp",Type=>SOCK_STREAM) or die "cannot connect to cddb db: $host:$port [$!]";

      print STDERR "cddb: http send: GET $url\n" if $debug;
      print $socket "GET $url\n";

      if($user) {
        my $cred = encode_base64("$user:$pass");
        print $socket "Proxy-Authorization: Basic $cred\n";
      }

      print $socket "\n";
      print $socket "\n" if $FW;

      if($HTTP_PROXY) {
        while(<$socket> =~ /^\S+/){};
      }

      while(<$socket>) {
        last if(/^\./);
        push @lines,$_;
      }
      close $socket;
    } else {
      die "unkown mode: $CDDB_MODE for querying cddb";
    }

    # xmcd
    #
    # Track frame offsets:
    #	150
    # ...
    #	210627
    #
    # Disc length: 2952 seconds
    #
    # Revision: 1
    # Submitted via: xmcd 2.0
    #

    for(@lines) {
      last if(/^\./);
      next if(/^\d\d\d/);
      push @{$cd{raw}},$_;
      #TTITLE0=Bitch (Edit) 
      if(/^TTITLE(\d+)\=\s*(.*)/) {
        my $t= $2;
        chop $t;
        $cd{frames}[$1]=$toc->[$1]->{frames};
        $cd{data}[$1]=$toc->[$1]->{data};
        unless (defined $cd{track}[$1]) {
          $cd{track}[$1]=$t;
        } else {
          $cd{track}[$1]=$cd{track}[$1].$t;
        }
      } elsif(/^DYEAR=\s*(\d+)/) {
        $cd{'year'} = $1;
      } elsif(/^DGENRE=\s*(\S+.*)/) {
        my $t = $1;
        chop $t;
        $cd{'genre'} = $t;
      } elsif(/^\#\s+Revision:\s+(\d+)/) {
        $cd{'revision'} = $1;
      }
    }

    $cd{tno}=$#{$cd{track}}+1;
    $cd{frames}[$cd{tno}]=$toc->[$cd{tno}]->{frames};
    
    return %cd unless($multi);
    push @r,\%cd;
    $i++;
  }

  return @r;
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

CDDB - Read the CDDB entry for an audio CD in your drive

=head1 SYNOPSIS

 use CDDB_get qw( get_cddb );

 my %config;

 # following variables just need to be declared if different from defaults

 $config{CDDB_HOST}="freedb.freedb.org";	# set cddb host
 $config{CDDB_PORT}=8880;			# set cddb port
 $config{CDDB_MODE}="cddb";			# set cddb mode: cddb or http
 $config{CD_DEVICE}="/dev/cdrom";		# set cd device

 # user interaction welcome?

 $config{input}=1;   # 1: ask user if more than one possibility
               	     # 0: no user interaction

 # get it on

 my %cd=get_cddb(\%config);

 unless(defined $cd{title}) {
   die "no cddb entry found";
 }

 # do somthing with the results

 print "artist: $cd{artist}\n";
 print "title: $cd{title}\n";
 print "category: $cd{cat}\n";
 print "cddbid: $cd{id}\n";
 print "trackno: $cd{tno}\n";

 my $n=1;
 foreach my $i ( @{$cd{track}} ) {
   print "track $n: $i\n";
   $n++;
 }

=head1 DESCRIPTION

This module/script gets the CDDB info for an audio cd. You need
LINUX, SUNOS or *BSD, a cdrom drive and an active internet connection 
in order to do that.

=head1 INSTALLATION

Run "perl Makefile.pl" as usual. ("make", "make install" next)

=head1 LICENSE & DISCLAIMER

This library is released under the same conditions as Perl, that
is, either of the following:

a) the GNU General Public License Version 2 as published by the 
Free Software Foundation,

b) the Artistic License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

You should also have received a copy of the GNU General Public License
along with this program, in the file names "Copying"; if not, write to 
the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, 
MA 02111-1307, USA.

If you use this library in a commercial enterprise, you are invited,
but not required, to pay what you feel is a reasonable fee to the
author, who can be contacted at armin@xos.net

=head1 AUTHOR & COPYRIGHT

(c) 2003 Armin Obersteiner <armin(at)xos(dot)net>

=head1 SEE ALSO

perl(1), Linux: F</usr/include/linux/cdrom.h>, 
Solaris, *BSD: F</usr/include/sys/cdio.h>.

=cut

