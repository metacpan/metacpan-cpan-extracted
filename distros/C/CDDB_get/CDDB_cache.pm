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

package CDDB_cache;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $debug $dir $readonly $grep);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
  get_cddb
  get_discids
);
$VERSION = '1.0';

use CDDB_get;
use File::Find;
use Data::Dumper qw(Dumper);

#$debug=1;
$dir="/tmp/xmcd";

my $CD_DEVICE = "/dev/cdrom";

sub get_discids {
  my $cd=shift;

  return CDDB_get::get_discids($cd);
}

my @files;

sub get_cddb {
  my $config=shift;
  my $diskid=shift;

  if($debug) {
    print STDERR "dir: [$dir]  readonly [$readonly]  grep [$grep]\n";
  }

  $config->{multi}=0;
  $CD_DEVICE = $config->{CD_DEVICE} if (defined($config->{CD_DEVICE}));

  my $did=$diskid;
  $did=CDDB_get::get_discids($CD_DEVICE) unless($did);
  #print Dumper($did);
 
  printf STDERR "%08x %08lx\n", $did->[0],  $did->[0] if($debug);
 
  my $sid = sprintf "%08x", $did->[0];
  my $id = sprintf "%08x %d", $did->[0], $did->[1];
  for(0..$did->[1]-1) {
    $id.=" ".$did->[2]->[$_]->{frames};
  }
  $id.=" ".int($did->[2]->[$did->[1]]->{frames}/75);
  print STDERR "id: $id\n" if $debug;

  @files=();
  if($grep) {
    find({ wanted => sub {
      next unless -f $File::Find::name;
      my $tid=`grep -H $sid $File::Find::name`;
      if($tid =~ /\S+/) {
        push @files, $File::Find::name;
      } 
    }, follow=>1}, $dir);
  } else {
    find({ wanted => sub {
      if($_ eq $sid) {
        push @files, $File::Find::name;
      } 
    }, follow=>1}, $dir);
  }
  print STDERR Dumper(\@files) if $debug;

  my $file;
  my $found;

  for(@files) {
    open IN,$_;
    undef $/;
    $file=<IN>;
    close IN;

    my ($fid)=$file =~ /DISCID=(\S+)/i;
    my ($len)=$file =~ /Disc length: (\d+) seconds/i;
    my ($s)=$file =~ /Track frame offsets:\s+(.*)\s+Disc length/si;
    my $t="";
    my @tr=split /#/,$s;
    my $c=0;
    for(@tr) {
      next unless /(\d+)/;
      $c++;
      $t.=" $1";
      last if($c>=$did->[1]);
    }
    my $tid="$fid $c$t $len";

    if($tid eq $id) {
      $found=$_;
      last;
    }
  }

  my $toc=$did->[2];

  my %cd;
  if($found) {
    print STDERR "CDDB_cache: reading from file: $found\n";

    my @lines=split /\n/,$file;
    for(@lines) {
      push @{$cd{raw}},$_."\n";
      #TTITLE0=Bitch (Edit)
      if(/^TTITLE(\d+)\=\s*(.*)/) {
        my $t= $2;
        chomp $t;
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
        chomp $t;
        $cd{'genre'} = $t;
      }
    }

    $cd{tno}=$#{$cd{track}}+1;
    $cd{frames}[$cd{tno}]=$toc->[$cd{tno}]->{frames};

    $cd{id}=$sid;

    my ($at)=$file=~/DTITLE=(.*?)\n/;
    my ($artist,$title);
    #chop $at if($at =~ /\r/);
    chomp $at;

    if($at =~ /\//) {
      ($artist,$title)= $at =~ /^(.*?)\s\/\s(.*)/;
    } else {
      $artist=$at;
      $title=$at;
    }

    $cd{artist}=$artist;
    $cd{title}=$title;

    my ($cat) = $found =~ /$dir\/(\S+?)\/$sid/;
    $cd{cat}=$cat;

  } else {
    print STDERR "CDDB_cache: reading from network\n";

    %cd=CDDB_get::get_cddb($config,$diskid);
  }

  print STDERR Dumper(\%cd) if $debug;

  unless($readonly || $found) {
    my $file=$dir."/$cd{cat}/$cd{id}";
    my $ddir=$dir."/$cd{cat}";
    mkdir $ddir,0755;   

    open OUT,">$file";
    for(@{$cd{raw}}) {
      print OUT $_;
    }
    close OUT;
  }

  return %cd;
}

1;
__END__
