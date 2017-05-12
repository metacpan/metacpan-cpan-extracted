package Data::Translate;

use vars qw($VERSION);
$VERSION = '0.3';

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(a2b a2d a2h b2a b2d b2h d2a d2b d2h h2a h2b h2d new);
@EXPORT_OK = qw(a2b a2d a2h b2a b2d b2h d2a d2b d2h h2a h2b h2d new);

sub new {
    my    $obj = {};
    bless $obj;
    return $obj;
}

sub a2b {
  shift;
  local ($str)=@_;
  my $ss=unpack("B*",$str);
  return 1,$ss;
}

sub a2d {
  shift;
  local ($str)=@_;
  my @c=unpack("C" x length($str),$str);
  return 1,@c;
}

sub a2h {
  shift;
  local ($str)=@_;
  my @h=unpack("H2" x length($str), pack("A*",$str));
  return 1,@h;
}

sub b2a {
  shift;
  local ($binstr)= @_;
  if ($binstr=~/^[01]+$/) {
      $as=unpack("A*", pack("B*", $binstr));
      return 1,$as;
  } else {
      return -1,0;
  }
}

sub b2d {
  shift;
  local($v)=@_;my $a=$b=0;
  $a=unpack("N", pack( "B32", "0" x 24 . $v));
  return 1,$a;
}

sub b2h {
  shift;
  local($v)=@_;
  my $r=unpack("H8", pack("B8", $v));
  return 1,$r;
}

sub d2b {
  shift;
  local (@dec)=@_;
  for ($i=0;$i<=$#dec;$i++) {
     $dec[$i]=unpack("B*",pack("N",$dec[$i]));
     $dec[$i]=~s/^0+(?=\d{8})//;
  }
  return 1,@dec;
}

sub d2a {
  shift;
  local (@dec)=@_;
  for ($i=0;$i<=$#dec;$i++) {
    $dec[$i]=unpack("A*", pack("N", $dec[$i]));
  }
  return 1,@dec;
}

sub d2h {
  shift;
  local $t=join("",@_);
  local $tt=sprintf("%lx", $t);
  return 1,$tt;
}


#HEX
sub h2b {
  shift;
  local (@hex)=@_;my $i;
  for ($i=0;$i<=$#hex;$i++) {
      $hex[$i]=unpack("B8", pack("H*", $hex[$i]));
  }
  return 1,@hex;
}

sub h2d {
  shift;
  local (@hex)=@_;my $i;
  for ($i=0;$i<=$#hex;$i++) {
    $hex[$i]=ord(pack("H*", $hex[$i]));
  }
  return 1,@hex;
}

sub h2a {
  shift;
  local (@hex)=@_;my $i;
  for ($i=0;$i<=$#hex;$i++) {
    $hex[$i]=unpack("A",pack("H8",$hex[$i]));
  }
  return 1,@hex;
}
1;
__END__

=head1 NAME

  Data::Translate - Translate string data between a few patterns (binary,decimal,ascii,hex)

=head1 SYNOPSIS

  use Data::Translate;
  $data=new Translate;

  # Example, translating from hex to Ascii
  # $s receives the status of the operation

  @hh=qw(64 65 6e 61 6f);
  ($s,@ha)=$data->h2a(@hh);
  print join('',@ha),"\n"; ## will output "denao"
 
=head1 DESCRIPTION
 
 This module is intended to translate data between a few patterns.
 Basicly, it is a ease mode to pack/unpack stuff.

 Imagine, you have a script that treats hex data, and you 
 need to see the values, in other format, like decimal, 
 binary or even ascii.

 This module implements a symplistic way to Translate values 
 smoothly returning the status of operation and values always 
 on a string.
 
 You may translate at this point:
   - ascii to binary
   - ascii to decimal
   - ascii to hex
   - decimal to ascii
   - decimal to binary
   - decimal to hex
   - binary to ascii
   - binary to decimal
   - binary to hex
   - hex to binary
   - hex to decimal
   - hex to ascii

 Please, head to test.pl for additional examples.
 The functions you'll call, are defined as the first
 byte of each data type.
 If you want to translate from binary to hex, you'll
 use the function b2h, and if you want to translate 
 from ascii to decimal, you'll use a2d, and so on.

=over

=item C<-E<gt>new>

 Creates a new instance of Translation. 

 eg.: $data=new Translate;

=item C<-E<gt>a2b>
 Translate from ascii to binary
  Ex.:

   ($s,$bin)=$data->a2b($str);

=item C<-E<gt>a2d>
 Translate from ascii to decimal
  Ex.:

   ($s,@dec)=$data->a2d($str);

=item C<-E<gt>a2h>
 Translate from ascii to hexadecimal
  Ex.:

   ($s,$hh)=$data->a2h($str);

=item C<-E<gt>b2a>
 Translate from binary to ascii
  Ex.:

   ($s,$asc)=$data->b2a($bin);

=item C<-E<gt>b2d>
 Translate from binary to decimal
  Ex.:

   @t=unpack("A8" x (length($bin)/8),$bin);
   foreach $binary (@t) {
      ($s,$d)=$data->b2d($binary);
      print "--> $d\n";
   }

=item C<-E<gt>b2h>
 Translate from binary to hexadecimal
  Ex.:

   foreach $binary (@t) {
      ($s,$hx)=$data->b2h($binary);
      print "--> $hx\n";
   }

=item C<-E<gt>d2a>
 Translate from decimal to ascii
  Ex.:
   ($s,@a)=$data->d2a(@dec);

=item C<-E<gt>d2b> 
 Translate from decimal to binary
  Ex.:
   ($s,@b)=$data->d2b(@dec);

=item C<-E<gt>d2h>
 Translate from decimal to hexadecimal
  Ex.:
   ($s,@bh)=$data->d2h(@dec);

=item C<-E<gt>h2a>
 Translate from hexadecimal to ascii
  Ex.:
   ($s,@ha)=$data->h2a(@hh);

=item C<-E<gt>h2b>
 Translate from hexadecimal to binary
  Ex.:

   ($s,@hd)=$data->h2d(@hh);

=item C<-E<gt>h2d>
 Translate from hexadecimal to decimal
  Ex.:

   ($s,@hb)=$data->h2b(@hh);

=back

=head1 INSTALLATION
   perl Makefile.PL  # build the Makefile
   make              # build the package
   make test         # test package
   make install      # Install package
=over

=head1 AUTHOR
 Denis Almeida Vieira Junior <davieira@uol.com.br>.

=head1 SEE ALSO

 perl(1)

=cut
