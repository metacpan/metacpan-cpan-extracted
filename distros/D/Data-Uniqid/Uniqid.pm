package Data::Uniqid;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  suniqid  
  uniqid  
  luniqid  
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  
);
our $VERSION = '0.12';

use Math::BigInt;
use Sys::Hostname;
use Time::HiRes qw( gettimeofday usleep );

sub base62() { ################################################### Base62 #####
  my($s)=@_;
  my(@c)=('0'..'9','a'..'z','A'..'Z');
  my(@p,$u,$v,$i,$n);
  my($m)=20;
  $p[0]=1;  
  for $i (1..$m) {
    $p[$i]=Math::BigInt->new($p[$i-1]);
    $p[$i]=$p[$i]->bmul(62);
  }

  $v=Math::BigInt->new($s);
  for ($i=$m;$i>=0;$i--) {
    $v=Math::BigInt->new($v);
    ($n,$v)=$v->bdiv($p[$i]);
    $u.=$c[$n];
  }
  $u=~s/^0+//;
  
  return($u);
}

sub suniqid { ########################################### get unique id #####
  my($s,$us)=gettimeofday();usleep(1);
  my($v)=sprintf("%06d%05d%06d",$us,substr($s,-5),$$);
  return(&base62($v));
}

sub uniqid { ########################################### get unique id #####
  my($s,$us)=gettimeofday();usleep(1);
  my($v)=sprintf("%06d%010d%06d",$us,$s,$$);
  return(&base62($v));
}

sub luniqid { ############################################ get unique id #####
  my($s,$us)=gettimeofday();usleep(1);
  my($ia,$ib,$ic,$id)=unpack("C4", (gethostbyname(hostname()))[4]);
  my($v)=sprintf("%06d%10d%06d%03d%03d%03d%03d",$us,$s,$$,$ia,$ib,$ic,$id);
	return(&base62($v));
}

1;
__END__

=head1 NAME

Data::Uniqid - Perl extension for simple genrating of unique id's

=head1 SYNOPSIS

  use Data::Uniqid qw ( suniqid uniqid luniqid );
  
  $id = suniqid;
  $id = uniqid;
  $id = luniqid;

=head1 DESCRIPTION

Data::Uniqid provides three simple routines for generating unique ids.
These ids are coded with a Base62 systen to make them short and handy
(e.g. to use it as part of a URL).

  suinqid
    genrates a very short id valid only for the localhost and with a 
    liftime of 1 day
  
  uniqid
    generates a short id valid on the local host 

  luniqid 
    generates a long id valid everywhere and ever


=head1 AUTHOR

Mike Wesemann, &lt;mwx@gmx.de&gt;

=head1 SEE ALSO

L<perl>.

=cut
