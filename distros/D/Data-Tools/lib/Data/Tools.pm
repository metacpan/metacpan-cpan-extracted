##############################################################################
#
#  Data::Tools perl module
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade" 
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/  
#
#  GPL
#
##############################################################################
package Data::Tools;
use strict;
use Exporter;
use Carp;
use Storable;
use Digest;
use Digest::Whirlpool;
use Digest::MD5;
use Digest::SHA1;
use MIME::Base64;
use File::Glob;
use Hash::Util qw( lock_hashref unlock_hashref lock_ref_keys );
use Fcntl qw( :flock );

our $VERSION = '1.46';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

              data_tools_set_text_io_encoding
              data_tools_set_text_io_utf8
              data_tools_set_text_io_bin

              file_save
              file_load
              file_load_ar

              file_bin_save
              file_bin_load

              file_text_save
              file_text_append
              file_text_load
              file_text_load_ar

              cmd_read_from
              cmd_write_to

              file_mtime
              file_ctime
              file_atime
              file_size

              file_path
              file_name
              file_name_ext
              file_ext
              
              file_lock
              file_lock_nb
              file_lock_ex
              file_lock_ex_nb
              file_unlock

              dir_path_make
              dir_path_ensure
              
              str2hash 
              hash2str
              hash2str_keys

              str2hash_url
              hash2str_url
              url2hash
              
              hash_uc
              hash_lc
              hash_uc_ipl
              hash_lc_ipl
              
              hash_save
              hash_load
              hash_save_keys
              hash_save_url
              hash_load_url
              
              hash_validate
              
              hash_lock_recursive
              hash_unlock_recursive
              hash_keys_lock_recursive
              
              hr_traverse_vals
              ar_traverse_vals
              
              list_uniq

              str_escape 
              str_unescape 

              str_url_escape 
              str_url_unescape 
              
              str_html_escape 
              str_html_escape_text 
              str_html_escape_attr 
              str_html_unescape 
              
              str_hex 
              str_unhex

              str_num_comma
              str_pad
              str_pad_center
              str_countable

              str_kmg_to_num
              str_hms_to_secs
              
              str_password_strength

              perl_package_to_file

              wp_hex
              md5_hex
              sha1_hex

              wp_hex_file
              md5_hex_file
              sha1_hex_file
              
              create_random_id
              
              glob_tree
              read_dir_entries

              fftwalk
                  
                  FFT_FILES
                  FFT_DIRS
                  
                  FFT_SYMF
                  FFT_SYMD
                  
                  FFT_FOLLOW

                  FFT_ALL
                  FFT_ALL4
                  FFT_FULL
              
              ref_freeze
              ref_thaw

              int2hex
              hex2int
              
              bcd2int
              int2bcd
              bcd2str
              
              format_ascii_table
            );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );
            
##############################################################################

my $TEXT_IO_ENCODING;

sub data_tools_set_text_io_encoding
{
  $TEXT_IO_ENCODING = shift;
  die "invalid text files io encoding [$TEXT_IO_ENCODING]" unless $TEXT_IO_ENCODING =~ /^[a-z_0-9:\-]*$/i;
}

sub data_tools_set_text_io_utf8
{
  data_tools_set_text_io_encoding( 'UTF-8' );
}

sub data_tools_set_text_io_bin
{
  data_tools_set_text_io_encoding( undef );
}

##############################################################################
# the old interface, still works but will be removed!

sub file_load
{
  my $fn  = shift; # file name
  my $opt = shift || {};
  
  if( ref( $fn ) eq 'HASH' )
    {
    $opt = $fn;
    hash_uc_ipl( $opt );
    $fn = $opt->{ 'FNAME' } || $opt->{ 'FILE_NAME' };
    }
  else
    {  
    hash_uc_ipl( $opt );
    }
  
  my $i;
  my $encoding = $opt->{ 'ENCODING' };
  my $mopt;
  $mopt = ":encoding($encoding)" if $encoding;
  open( $i, "<" . $mopt, $fn ) or return undef;
  binmode( $i ) if $opt->{ ':RAW' };
  local $/ = undef;
  my $s = <$i>;
  close $i;
  return $s;
}

sub file_load_ar
{
  my $fn  = shift; # file name
  my $opt = shift || {};

  if( ref( $fn ) eq 'HASH' )
    {
    $opt = $fn;
    hash_uc_ipl( $opt );
    $fn = $opt->{ 'FNAME' } || $opt->{ 'FILE_NAME' };
    }
  else
    {  
    hash_uc_ipl( $opt );
    }
  
  my $i;
  my $encoding = $opt->{ 'ENCODING' };
  my $mopt;
  $mopt = ":encoding($encoding)" if $encoding;
  open( $i, "<" . $mopt, $fn ) or return undef;
  binmode( $i ) if $opt->{ ':RAW' };
  my @all = <$i>;
  close $i;
  return \@all;
}

sub file_save
{
  my $fn = shift; # file name
  
  my $opt = {};
  if( ref( $fn ) eq 'HASH' )
    {
    $opt = $fn;
    hash_uc_ipl( $opt );
    $fn = $opt->{ 'FNAME' } || $opt->{ 'FILE_NAME' };
    }

  my $encoding = $opt->{ 'ENCODING' };
  my $mopt;
  $mopt = ":encoding($encoding)" if $encoding;

  my $o;
  open( $o, ">" . $mopt, $fn ) or return 0;
  binmode( $o ) if $opt->{ ':RAW' };
  print $o @_;
  close $o;
  return 1;
}

##############################################################################
# binary files load/save

sub file_bin_load
{
  my $fn  = shift; # file name

  my $i;
  open( $i, "<", $fn ) or return undef;
  binmode( $i );
  local $/ = undef;
  my $s = <$i>;
  close $i;
  return $s;
}

sub file_bin_save
{
  my $fn = shift; # file name
  
  my $o;
  open( $o, ">", $fn ) or return 0;
  binmode( $o );
  print $o @_;
  close $o;
  return 1;
}

##############################################################################
# text files load/save

sub file_text_load
{
  my $fn  = shift; # file name

  my $i;
  my $enc = ":encoding($TEXT_IO_ENCODING)" if $TEXT_IO_ENCODING;
  open( $i, "<$enc", $fn ) or return undef;
  binmode( $i ) unless $TEXT_IO_ENCODING;
  local $/ = undef;
  my $s = <$i>;
  close $i;
  return $s;
}

sub file_text_load_ar
{
  my $fn  = shift; # file name

  my $i;
  my $enc = ":encoding($TEXT_IO_ENCODING)" if $TEXT_IO_ENCODING;
  open( $i, "<$enc", $fn ) or return undef;
  binmode( $i ) unless $TEXT_IO_ENCODING;
  my @a = <$i>;
  close $i;
  return \@a;
}

sub file_text_save
{
  my $fn = shift; # file name
  
  my $o;
  my $enc = ":encoding($TEXT_IO_ENCODING)" if $TEXT_IO_ENCODING;
  open( $o, ">$enc", $fn ) or return 0;
  binmode( $o ) unless $TEXT_IO_ENCODING;
  print $o @_;
  close $o;
  return 1;
}

sub file_text_append
{
  my $fn = shift; # file name
  
  my $o;
  my $enc = ":encoding($TEXT_IO_ENCODING)" if $TEXT_IO_ENCODING;
  open( $o, ">>$enc", $fn ) or return 0;
  binmode( $o ) unless $TEXT_IO_ENCODING;
  print $o @_;
  close $o;
  return 1;
}



##############################################################################

sub cmd_read_from
{
  my @args = ref( $_[0] ) ? @{ $_[0] } : @_;

  open( my $i, "-|", @args ) or return undef;
  local $/ = undef;
  my $s = <$i>;
  close $i;
  return $s;
}

sub cmd_write_to
{
  my @args = ref( $_[0] ) ? @{ $_[0] } : @_;
  
  open( my $o, "|-", @args ) or return undef;
  print $o @_;
  close $o;
  return 1;
}


##############################################################################

sub file_mtime
{
  return (stat(shift))[9];
}

sub file_ctime
{
  return (stat(shift))[10];
}

sub file_atime
{
  return (stat(shift))[8];
}

sub file_size
{
  return (stat(shift))[7];
}

##############################################################################

sub file_path
{
  return $_[0] =~ /((^|.*?)\/)([^\/]*)$/ ? $1 : undef;
}

sub file_name
{
  # return full name with leadeing dot for dot-files ( .filename )
  return $_[0] =~ /(^|\/)([^\/]+?)(\.([^\.\/]+))?$/ ? $2 : undef;
}

sub file_name_ext
{
  # return full name with leadeing dot for dot-files ( .filename )
  return $_[0] =~ /(^|\/)([^\/]+)$/ ? $2 : undef;
}

sub file_ext
{
  # return undef for dot-files ( .filename )
  return $_[0] =~ /[^\/]\.([^\.\/]+)$/ ? $1 : undef;
}

##############################################################################

sub file_lock
{
  my $fnh = shift; # file name or file handle
  my $nb  = shift; # non-blocking
  my $ex  = shift; # true if exclusive lock
  
  my $fh;
  if( ref $fnh )
    {
    # file handle
    $fh = $fnh;
    }
  else  
    {
    # filename
    open( $fh, ( -e $fnh ? ( $ex ? '+<' : '<' ) : ( $ex ? '+>' : '>' ) ), $fnh ) or return undef;
    }

  my $res = flock( $fh, ( $ex ? LOCK_EX : LOCK_SH ) | ( $nb ? LOCK_NB : 0 ) );
  return $res ? $fh : undef;
}

sub file_lock_nb
{
  return file_lock( shift(), 1 );
}

sub file_lock_ex
{
  return file_lock( shift(), shift(), 1 );
}

sub file_lock_ex_nb
{
  return file_lock( shift(), 1, 1 );
}

# needs first arg to be file handle returned from any file_lock* function above
sub file_unlock
{
  return flock( shift(), LOCK_UN );
}

##############################################################################

sub dir_path_make
{
  my $path = shift;
  my %opt = @_;

  my $mask = $opt{ 'MASK' } || oct('700');
  
  my $abs;

  $path =~ s/\/+$/\//o;
  $abs = '/' if $path =~ s/^\/+//o;

  my @path = split /\/+/, $path;

  $path = $abs;
  for my $p ( @path )
    {
    $path .= "$p/";
    mkdir( $path, $mask ); # should check if EEXISTS but still the same outcome
    return 0 unless -d $path;
    }
  return 1;
}

sub dir_path_ensure
{
  my $dir = shift;
  my %opt = @_;

  dir_path_make( $dir, @_ ) unless -d $dir;
  return undef unless -d $dir;
  return $dir;
}

##############################################################################

sub str_escape
{
  my $text = shift;
  
  $text =~ s/\\/\\\\/g;
  $text =~ s/\r/\\r/g;
  $text =~ s/\n/\\n/g;
  return $text;
}

sub str_unescape
{
  my $text = shift;

  $text =~ s/\\r/\r/g;
  $text =~ s/\\n/\n/g;
  $text =~ s/\\\\/\\/g;
  
  return $text;
}

##############################################################################
#   url-style escape & hex escape
##############################################################################

our $URL_ESCAPES_DONE;
our %URL_ESCAPES;

sub __url_escapes_init
{
  return if $URL_ESCAPES_DONE;
  for ( 0 .. 255 ) { $URL_ESCAPES{ chr( $_ )     } = sprintf("%%%02X", $_); }
  $URL_ESCAPES_DONE = 1;
}

sub str_url_escape
{
  my $text = shift;
  
  $text =~ s/([^ -\$\&-<>-~])/$URL_ESCAPES{$1}/gs;
  return $text;
}

sub str_url_unescape
{
  my $text = shift;
  
  $text =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
  return $text;
}

my %HTML_ESCAPES = (
                   '"'  => '&#34;',
                   "&"  => '&#38;',
                   "'"  => '&#39;',
                   '<'  => '&#60;',
                   '='  => '&#61;',
                   '>'  => '&#62;',
                   "`"  => '&#96;',
                   '\\' => '&#134;',
                   );

my %HTML_ESCAPES_TEXT = (
                   '<'  => '&#60;',
                   '>'  => '&#62;',
                   );

my %HTML_ESCAPES_ATTR = (
                   '"'  => '&#34;',
                   "'"  => '&#39;',
                   '<'  => '&#60;',
                   '='  => '&#61;',
                   '>'  => '&#62;',
                   "`"  => '&#96;',
                   );

sub str_html_escape
{
  my $text = shift;

  $text =~ s/([<>`'&"\\])/$HTML_ESCAPES{ $1 }/ge;
  
  return $text;
}

sub str_html_escape_text
{
  my $text = shift;

  $text =~ s/([<>`'&"\\])/$HTML_ESCAPES_TEXT{ $1 }/ge;
  
  return $text;
}

sub str_html_escape_attr
{
  my $text = shift;

  $text =~ s/([<>`'&"\\])/$HTML_ESCAPES_ATTR{ $1 }/ge;
  
  return $text;
}

sub str_html_unescape
{
  my $text = shift;

  confess "still not implemented";
  
  return $text;
}

sub str_hex
{
  return unpack( "H*",  shift() );
}

sub str_unhex
{
  return pack( "H*", shift() );
}

##############################################################################

sub str_num_comma
{
  my $data = shift;
  my $pad  = shift || '`';
  $data = reverse $data;
  $data =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1$pad/g;
  $data = reverse $data;
  return $data;
}

sub str_pad
{
  my $str = shift;
  my $len = shift;
  my $pad = shift;
  $pad = ' ' unless defined $pad;

  $str = reverse $str if $len < 0;
  $str = substr( $str . ($pad x abs($len)), 0, abs($len) );
  $str = reverse $str if $len < 0;

  return $str;
}

sub str_pad_center
{
  my $str = shift;
  my $len = shift;
  my $pad = shift;
  $pad = ' ' unless defined $pad;

  my $padlen = int((abs($len) - length($str))/2);
  my $padding = $pad x $padlen if $padlen > 0;
  
  $str = substr( $padding . $str . $padding . $pad, 0, abs($len) );

  return $str;
}

sub str_countable
{
  my $count = shift;
  my $one   = shift;
  my $many  = shift;

  return $count == 0 ? $many : $count == 1 ? $one : $many;
}

sub str_kmg_to_num
{
  my $s = uc shift;
  return undef unless $s =~ /^\s*(\d+(\.\d*)?)(\s*([KMGTP]))?/;
  return $1 unless $4;
  return $1 * ( 1024 ** ( index( 'KMGTP', $4 ) + 1 ) );
}

sub str_hms_to_secs
{
  my $s = uc shift;
  
  my $secs;
  $s .= 's' if $s =~ /^[\s\d]+$/;
  while( $s =~ /(\d+)\s*([WDHMS])/gi )
    {
    if   ( lc $2 eq 's' ) { $secs += $1; }
    elsif( lc $2 eq 'm' ) { $secs += $1 * 60; }
    elsif( lc $2 eq 'h' ) { $secs += $1 * 60 * 60; }
    elsif( lc $2 eq 'd' ) { $secs += $1 * 60 * 60 * 24; }
    elsif( lc $2 eq 'w' ) { $secs += $1 * 60 * 60 * 24 * 7; }
    }
  
  return $secs;
}

##############################################################################
# str_password_strength()
# returns a number representing password strength
# it is tuned to give password strength in a number close to percents:
# less than 50 weak, 50-75 good, 76-100 strong, more than 100 very strong

sub str_password_strength
{
  my $p  = shift;

  $p =~ s/(.)\1+/$1/g; # reduce repeating chars
  
  my $l  = length( $p ); # remaining string length 
  
  my $lc = $p =~ tr/[a-z]/[a-z]/; # lower case letters
  my $uc = $p =~ tr/[A-Z]/[A-Z]/; # upper case letters
  my $dc = $p =~ tr/[0-9]/[0-9]/; # digits
  my $sc = $l -  $lc - $uc - $dc; # special chars

  my $cc = ( $lc > 0 )      + ( $uc > 0 )      + ( $dc > 0 )      + ( $sc > 0 )     ; # used classes count
  my $as = ( $lc > 0 ) * 26 + ( $uc > 0 ) * 26 + ( $dc > 0 ) * 10 + ( $sc > 0 ) * 30; # alphabet size

  my $cp = $cc < 2 ? 2 : 1; # class count penalty
  my $res = log( $as ** $l ) / $cp;

  # print "<$p> l=$l   lc=$lc   uc=$uc   dc=$dc   sc=$sc   cc=$cc   as=$as   nb=$nb   ($res)\n";
  
  return $res;
}

##############################################################################

sub hash2str
{
   my $hr = shift;

   my $str;
   while( my ( $k, $v ) = each %$hr )
    {
    $k =~ s/=/\\=/g;
    $v =~ s/\\/\\\\/g;
    $v =~ s/\n/\\n/g;
    $str .= "$k=$v\n";
    }

  return $str;
}

sub str2hash
{
  my $str = shift;
  my %hr;

  for( split /\n/, $str )
    {
    my ( $k, $v ) = split /(?<!\\)=/, $_, 2;
    $k =~ s/\\=/=/g;
    $v =~ s/\\\\/\\/g;
    $v =~ s/\\n/\n/g;
    $hr{ $k } = $v;
    }

return \%hr;
}

sub hash2str_keys
{
  my $hr = shift;

  my $str;
  for my $k ( @_ )
    {
    my $v = $hr->{ $k };
    $k =~ s/=/\\=/g;
    $v =~ s/\\/\\\\/g;
    $v =~ s/\n/\\n/g;
    $str .= "$k=$v\n";
    }

  return $str;
}


sub str2hash_url
{
  my $str = shift;
  
  my %h;
  for( split( /\n/, $str ) )
    {
    $h{ str_url_unescape( $1 ) } = str_url_unescape( $2 ) if ( /^([^=]+)=(.*)$/ );
    }
  return \%h;
}

sub hash2str_url
{
  my $hr = shift; # hash reference

  my $s = "";
  while( my ( $k, $v ) = each %$hr )
    {
    $k = str_url_escape( $k );
    $v = str_url_escape( $v );
    $s .= "$k=$v\n";
    }
  return $s;
}

sub url2hash
{
  my $str = shift;
  my %hash;
  for( split( /&/, $str ) )
    {
    $hash{ uc str_url_unescape( $1 ) } = str_url_unescape( $2 ) if ( /^([^=]+)=(.*)$/ );
    }
  return \%hash;
}

##############################################################################

sub __hash_ulc
{
  my $hr  = shift;
  my $uc  = shift;
  my $ipl = shift;
  
  my $nr = $ipl ? $hr : {};
  for my $k ( keys %$hr )
    {
    my $v = $hr->{ $k };
    my $old_k = $k;
    $k = $uc ? uc( $k ) : lc( $k );
    $nr->{ $k } = $v;
    delete $nr->{ $old_k } if ($ipl and $k ne $old_k);
    }
  return $nr;  
}

sub hash_uc
{
  return __hash_ulc( shift(), 1, 0 );
}

sub hash_lc
{
  return __hash_ulc( shift(), 0, 0 );
}

sub hash_uc_ipl
{
  return __hash_ulc( shift(), 1, 1 );
}

sub hash_lc_ipl
{
  return __hash_ulc( shift(), 0, 1 );
}

##############################################################################

sub hash_save
{
  my $fn = shift;
  # @_ array of hash references
  my $data;
  $data .= hash2str( $_ ) for @_;
  return file_save( $fn, $data );
}

sub hash_load
{
  my $fn = shift;
  
  return str2hash( file_load( $fn ) );
}

sub hash_save_keys
{
  my $fn = shift;
  my $hr = shift;

  my $data;
  $data .= hash2str_keys( $hr, @_ );
  return file_save( $fn, $data );
}

sub hash_save_url
{
  my $fn = shift;
  # @_ array of hash references
  my $data;
  $data .= hash2str_url( $_ ) for @_;
  return file_save( $fn, $data );
}

sub hash_load_url
{
  my $fn = shift;
  
  return str2hash_url( file_load( $fn ) );
}

##############################################################################

sub hash_validate
{
  my $hr = shift; # hashref to validate
  my $vr = shift; # hashref with expectations
  
  my @err; # invalid keys
  
  while( my ( $k, $v ) = each %$hr )
    {
    if( ! exists $vr->{ $k } )
      {
      push @err, $k;
      next;
      }
    
    my $vv = $vr->{ $k };
    
    if( ref( $v ) eq 'HASH' )
      {
      my @e = hash_validate( $v, $vv );
      for my $e ( @e )
        {
        push @err, "$k/$e";
        }
      }
    elsif( $vv =~ /^\s*(int|real|float)\s*(\(\s*(\d+)\s*,\s*(\d+)\s*\))?\s*$/i )
      {
      my $y = uc $1;
      my $f = $3;
      my $t = $4;

      $v =~ s/[\s'`]+//g;
      
      my $re;
      $re = qr/^[-+]?\d+$/ if $y eq 'INT';
      $re = qr/^[-+]?\d+(\.\d*)?$/ if $y eq 'REAL' or $y eq 'FLOAT';

      #print STDERR Data::Dumper::Dumper( '=int=real='x5, $k, $v, $vv, $re  );

      if( $v =~ /$re/ )
        {
        push @err, $k if $f ne '' and $v < $f;
        push @err, $k if $t ne '' and $v > $t;
        }
      else
        {
        push @err, $k;
        }  
      }
    elsif( $vv =~ /^\s*RE(I)?:\s*(.*?)\s*$/i )
      {
      my $ic = $1; # ignore case
      my $re = $ic ? qr/$2/i : qr/$2/;
      # print Data::Dumper::Dumper( '=re=rei='x5, $k, $v, $vv, $re, $ic );
      push @err, $k unless $v =~ /$re/;
      }  
    elsif( $vv =~ /^\s*(-d|dir|directory)\s*$/i )
      {
      push @err, $k unless -d $v;
      }  
    elsif( $vv =~ /^\s*(-f|file)\s*$/i )
      {
      push @err, $k unless -f $v;
      }  
    }
    
  return wantarray() ? sort( @err ) : @err > 0 ? 0 : 1;
}

##############################################################################

# handle recursive hashes until perl 5.22 etc.
sub hash_lock_recursive
{
  my $hr = shift;
  
  lock_hashref( $hr );
  for my $vr ( values %$hr )
    {
    next unless ref( $vr ) eq 'HASH';
    hash_lock_recursive( $vr );
    }
  
  return $hr;  
}

sub hash_unlock_recursive
{
  my $hr = shift;
  
  unlock_hashref( $hr );
  for my $vr ( values %$hr )
    {
    next unless ref( $vr ) eq 'HASH';
    hash_unlock_recursive( $vr );
    }

  return $hr;  
}

sub hash_keys_lock_recursive
{
  my $hr = shift;
  
  lock_ref_keys( $hr );
  for my $vr ( values %$hr )
    {
    next unless ref( $vr ) eq 'HASH';
    hash_keys_lock_recursive( $vr );
    }

  return $hr;  
}

sub hr_traverse_vals
{
  my $hr  = shift;
  my $sub = shift;
  
  for( keys %$hr )
    {
    my $v = $hr->{ $_ };
    my $r = ref( $v );
    if( $r eq 'HASH' )
      {
      hr_traverse_vals( $v, $sub );
      }
    elsif( $r eq 'ARRAY' )
      {
      ar_traverse_vals( $v, $sub );
      }
    elsif( $r eq '' )
      {
      $hr->{ $_ } = $sub->( $v );
      }
    else
      {
      confess "unsupported VALUE TYPE";
      }  
    }
}

sub ar_traverse_vals
{
  my $ar = shift;
  my $sub = shift;
  
  for( @$ar )
    {
    my $r = ref( $_ );
    if( $r eq 'HASH' )
      {
      hr_traverse_vals( $_, $sub );
      }
    elsif( $r eq 'ARRAY' )
      {
      ar_traverse_vals( $_, $sub );
      }
    elsif( $r eq '' )
      {
      $_ = $sub->( $_ );
      }
    else
      {
      confess "unsupported VALUE TYPE";
      }  
    }
}

##############################################################################

sub list_uniq 
{
  my %z;
  return grep ! $z{ $_ }++, @_;
}

##############################################################################

sub perl_package_to_file
{
  my $s = shift;
  $s =~ s/::/\//g;
  $s .= '.pm';
  return $s;
}

##############################################################################

sub wp_hex
{
  my $s = shift;

  my $wp = Digest->new( 'Whirlpool' );
  $wp->add( $s );
  my $hex = $wp->hexdigest();

  return $hex;
}

sub md5_hex
{
  my $s = shift;

  my $hex = Digest::MD5::md5_hex( $s );

  return $hex;
}

sub sha1_hex
{
  my $s = shift;

  my $hex = Digest::SHA1::sha1_hex( $s );

  return $hex;
}

sub __digest_hex_file
{
  my $digest = shift;
  my $fn     = shift;
  
  open( my $fh, '<', $fn ) or return undef;
  binmode $fh;
  $digest->addfile( $fh );
  return $digest->hexdigest;
}

sub wp_hex_file
{
  return __digest_hex_file( Digest->new( 'Whirlpool' ), shift() );
}

sub md5_hex_file
{
  return __digest_hex_file( Digest::MD5->new, shift() );
}

sub sha1_hex_file
{
  return __digest_hex_file( Digest::SHA1->new, shift() );
}

##############################################################################

sub create_random_id
{
  my $len = shift() || 128;
  my $let = shift() || 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  my $l = length( $let );
  my $id;
  $id .= substr( $let, int(rand() * $l), 1 ) for ( 1 .. $len );
  return $id;
};

##############################################################################

sub __glob_tree_tree_walk
{
  my $p = shift; # path
  my $f = shift; # file mask
  my $r = shift; # result arr-ref

  #print STDERR "DEBUG: __glob_tree_tree_walk: $p -- $f [$p$f]\n";

  push @$r, grep { -e } sort ( File::Glob::bsd_glob( "$p$f" ) );

  my @dirs = grep { -d "$p$_" } read_dir_entries( "$p/." );
  
  #print STDERR "DEBUG: __glob_tree_tree_walk: $p -- $f [$p*] dirs: (@dirs)\n\n";

  __glob_tree_tree_walk( "$p$_/", $f, $r ) for @dirs;
  
  return 1;
}

sub glob_tree
{
  my @res;
  for( @_ )
    {
    die "glob_tree: invalid argument" unless /^(.*?\/)([^\/]+)$/;
    my $p = $1;
    my $f = $2;
    __glob_tree_tree_walk( $p, $f, \@res );
    }
  return @res;
}

sub read_dir_entries
{
  my $p = shift; # path
  
  opendir( my $dir, $p ) or return undef;
  my @e = sort grep { !/^\.\.?$/ } readdir $dir;
  closedir( $dir );
  
  return @e;
}

##############################################################################

use constant 
{
    FFT_FILES  => 0x01,
    FFT_DIRS   => 0x02,
    
    FFT_SYMF   => 0x04, # allow symlink files in result (requires FFT_FILES)
    FFT_SYMD   => 0x08, # allow symlink dirs in result  (requires FFT_DIRS )
    
    FFT_FOLLOW => 0x10,

    FFT_ALL    => 0x01 | 0x02,
    FFT_ALL4   => 0x01 | 0x02 | 0x04 | 0x08,
    FFT_FULL   => 0x01 | 0x02 | 0x04 | 0x08 | 0x10,
};

sub __fftwalk
{
  my $e  = shift;
  my $a  = shift;
  my $ty = shift; # typemap, see FFTs above
  
  opendir( my $dir, $e ) or return undef;
  my $ee;
  while( $ee = readdir $dir )
    {
    next if $ee eq '.' or $ee eq '..';
    my $eee = "$e/$ee";
    
    my $is_dir  = -d $eee;
    my $is_link = -l $eee;

    if( $is_dir )
      {
      push @$a, $eee if $is_link ? $ty & FFT_DIRS && $ty & FFT_SYMD : $ty & FFT_DIRS;
      __fftwalk( $eee, $a, $ty ) if ! $is_link or $ty & FFT_FOLLOW;
      }
    else
      {
      push @$a, $eee if $is_link ? $ty & FFT_FILES && $ty & FFT_SYMF : $ty & FFT_FILES;
      }  
    }
  closedir( $dir );
}

# fast file tree walk
# first argument traversal typemap scalar or hash with options
# rest of arguments are directory names to be walked
# options hash can have:
#   TYPE  => typemap
# this option tells which types of filesystem entries to be processed:
#   FFT_FILES  -- add found files
#   FFT_DIRS   -- add found directories
#   FFT_SYMF   -- add found file symlinks (needs FFT_FILES)
#   FFT_SYMD   -- add found dir  symlinks (needs FFT_DIRS )
#   FFT_FOLLOW -- follow/traverse symlink dirs
# there are few shortcut options:
#   FFT_ALL    -- all files and dirs but no symlinks
#   FFT_ALL4   -- all files and dirs including symlinks
#   FFT_FULL   -- all files, dirs, symlinks and follow symlink dirs
# if TYPE is zero, fftwalk will not do anything
#   ARRAY => hashref_for_result_list

sub fftwalk
{
  my $ty = shift;

  my $opt = {};
  if( ref( $ty ) eq 'HASH' )
    {
    $opt = $ty;
    $ty = $opt->{ 'TYPE' };
    }
  else
    {
    $opt = {};
    }  
  
  die "fftwalk() uses TYPE instead of MODE" if $opt->{ 'MODE' };

  my $e = $opt->{ 'ARRAY' } ? $opt->{ 'ARRAY' } : [];

  return $e unless $ty > 0; # do nothing if TYPE is zero

  __fftwalk( $_, $e, $ty ) for @_;
  return $e;
}

##############################################################################

sub ref_freeze
{
  my $ref = shift;

  die "error: ref_freeze(): requires data reference!\n" unless ref( $ref );

  my $fzd = encode_base64( Storable::nfreeze( $ref ) );                                                     
};                                                                                                                              
                                                                                                                                
sub ref_thaw
{
  my $fzd = shift;

  my ( $ref ) = Storable::thaw( decode_base64( $fzd ) );                                                      
                                                                                                                                
  return ref( $ref ) ? $ref : undef;                                                                                            
};                                                                                                                              

##############################################################################

sub int2hex
{
  return sprintf( "%X", shift );
}

*hex2int = *CORE::hex;

##############################################################################

sub bcd2int
{
  my $bcd = shift;
  
  my $int = 0;

  my @bcd = unpack 'C*', $bcd;
  my $p = @bcd * 2 - 1;
  for( @bcd )
    {
    $int += ( 10 ** $p-- ) * ( ( $_ & 0xF0 ) >> 4 );
    $int += ( 10 ** $p-- ) * ( ( $_ & 0x0F )      );
    }

  return $int;
}

sub int2bcd
{
  my $int = shift;
  my $len = shift; # in how many bytes to produce bcd
  
  die "int2bcd() is not yet implemented";
}

sub bcd2str
{
  my $bcd = shift;
  
  my $str;

  my @bcd = unpack 'C*', $bcd;
  for( @bcd )
    {
    $str .= ( ( $_ & 0xF0 ) >> 4 );
    $str .= ( ( $_ & 0x0F )      );
    }

  return $str;
}

##############################################################################

# sub format_ascii_table
# takes either arrayref-of-arraysrefs or arrayref-oh-hashrefs
# first row is heading

sub format_ascii_table
{
  my $data = shift;

  $data = format_ascii_convert_aoh_to_aoa( $data ) if ref( $data->[ 0 ] ) eq 'HASH';
  
  my @ws; # widths
  my $wt; # width total
  my $cs; # columns
  
  for my $row ( @$data )
    {
    my $c = 0;
    for my $d ( @$row )
      {
      my $l = length( $d );
      $ws[ $c ] = $l if $l > $ws[ $c ];
      $c++;
      }
    $cs = $c if $c > $cs;
    }
  
  $wt += $_ + 2 for @ws; # plus 2 for one char spacing around borders
  $wt += @ws + 1; # plus border chars

  my $sep = '+' . ( '-' x ( $wt - 2 ) ) . '+' . "\n";
  my $tx;
  
  my $r = 0;
  $tx .= $sep;
  for my $row ( @$data )
    {
    $tx .= '|';
    for my $c ( 0 .. $cs - 1 )
      {
      my $w = $ws[ $c ];
      $w = - $w if $row->[ $c ] =~ /^([\+\-])?[\d\.]+$/; # only plain number, no exp
      $tx .= ' ' . str_pad( $row->[ $c ], $w ) . ' |';
      }
    $tx .= "\n";
    $tx .= $sep if $r == 0;
    $r++;
    }
  $tx .= $sep;
  
  return $tx;
}

sub format_ascii_convert_aoh_to_aoa
{
  my $data = shift;
  my @out;
  
  my %keys;
  for my $row ( @$data )
    {
    $keys{ $_ }++ for keys %$row;
    }
  my @keys = sort keys %keys;
  
  push @out, \@keys;
  for my $row ( @$data )
    {
    push @out, [ map { $row->{ $_ } } @keys ];
    }
  
  return \@out;
}

##############################################################################

BEGIN { __url_escapes_init(); }
INIT  { __url_escapes_init(); }

##############################################################################

=pod


=head1 NAME

  Data::Tools provides set of basic functions for data manipulation.

=head1 SYNOPSIS

  use Data::Tools qw( :all );  # import all functions
  use Data::Tools;             # the same as :all :) 
  use Data::Tools qw( :none ); # do not import anything, use full package names

  # --------------------------------------------------------------------------

  data_tools_set_file_io_encoding( 'UTF-8' ); # all file IO will use UTF-8
  data_tools_set_file_io_encoding( ':RAW' );  # all file IO will use binary data

  my $res  = file_save( $file_name, 'file content here' );
  my $data = file_load( $file_name );

  my $data_arrayref = file_load_ar( $file_name );
  
  # for specific charset encoding and because of backward compatibility:

  my $res  = file_save( { FILE_NAME => $file_name, ENCODING => 'UTF-8' }, 'data' );
  my $data = file_load( { FILE_NAME => $file_name, ENCODING => 'UTF-8' } );

  my $data_arrayref = file_load_ar( { FILE_NAME => $fname, ENCODING => 'UTF-8' } );

  # --------------------------------------------------------------------------

  my $file_modification_time_in_seconds = file_mtime( $file_name );
  my $file_change_time_in_seconds       = file_ctime( $file_name );
  my $file_last_access_time_in_seconds  = file_atime( $file_name );
  my $file_size                         = file_size(  $file_name );

  # --------------------------------------------------------------------------
  
  my $res  = dir_path_make( '/path/to/somewhere' ); # create full path with 0700
  my $res  = dir_path_make( '/new/path', MASK => 0755 ); # ...with mask 0755
  my $path = dir_path_ensure( '/path/s/t/h' ); # ensure path exists, check+make

  # --------------------------------------------------------------------------

  my $path_with_trailing_slash = file_path( $full_path_or_file_name );

  # file_name() and file_name_ext() return full name with leadeing 
  # dot for dot-files ( .filename )
  my $file_name_including_ext  = file_name_ext( $full_path_or_file_name );
  my $file_name_only_no_ext    = file_name( $full_path_or_file_name );

  # file_ext() returns undef for dot-files ( .filename )
  my $file_ext_only            = file_ext( $full_path_or_file_name );

  # --------------------------------------------------------------------------
  
  # uses simple backslash escaping of \n, = and \ itself
  my $data_str = hash2str( $hash_ref ); # convert hash to string "key=value\n"
  my $hash_ref = str2hash( $hash_str ); # convert str "key-value\n" to hash

  # same as hash2str() but uses keys in certain order
  my $data_str = hash2str_keys( \%hash, sort keys %hash );
  my $data_str = hash2str_keys( \%hash, sort { $a <=> $b } keys %hash );

  # same as hash2str() and str2hash() but uses URL-style escaping
  my $data_str = hash2str_url( $hash_ref ); # convert hash to string "key=value\n"
  my $hash_ref = str2hash_url( $hash_str ); # convert str "key-value\n" to hash
  
  my $hash_ref = url2hash( 'key1=val1&key2=val2&testing=tralala);
  # $hash_ref will be { key1 => 'val1', key2 => 'val2', testing => 'tralala' }

  my $hash_ref_with_upper_case_keys = hash_uc( $hash_ref_with_lower_case_keys );
  my $hash_ref_with_lower_case_keys = hash_lc( $hash_ref_with_upper_case_keys );

  hash_uc_ipl( $hash_ref_to_be_converted_to_upper_case_keys );
  hash_lc_ipl( $hash_ref_to_be_converted_to_lower_case_keys );
  
  # save/load hash in str_url_escaped form to/from a file
  my $res      = hash_save( $file_name, $hash_ref );
  my $hash_ref = hash_load( $file_name );

  # save hash with certain keys order, uses hash2str_keys()
  my $res      = hash_save( $file_name, \%hash, sort keys %hash );
  
  # same as hash_save() and hash_load() but uses hash2str_url() and str2hash_url()
  my $res      = hash_save_url( $file_name, $hash_ref );
  my $hash_ref = hash_load_url( $file_name );

  # validate (nested) hash by example
  
  # validation example nested hash
  my $validate_hr = {
                    A => 'INT',
                    B => 'INT(-5,10)',
                    C => 'REAL',
                    D => {
                         E => 'RE:\d+[a-f]*',  # regexp match
                         F => 'REI:\d+[a-f]*', # case insensitive regexp match
                         },
                    DIR1  => '-d',   # must be existing directory
                    DIR2  => 'dir',  # must be existing directory
                    FILE1 => '-f',   # must be existing file  
                    FILE2 => 'file', # must be existing file  
                    };
  # actual nested hash to be verified if looks like the example
  my $data_hr     = {
                    A => '123',
                    B =>  '-1',
                    C =>  '1 234 567.89',
                    D => {
                         E => '123abc',
                         F => '456FFF',
                         },
                    }               
  
  my @invalid_keys = hash_validate( $data_hr, $validate_hr );
  print "YES!" if hash_validate( $data_hr, $validate_hr );

  # --------------------------------------------------------------------------
  
  my $escaped   = str_url_escape( $plain_str ); # URL-style %XX escaping
  my $plain_str = str_url_unescape( $escaped );

  my $escaped   = str_html_escape( $plain_str ); # HTML-style &name; escaping
  my $plain_str = str_html_unescape( $escaped );
  
  my $hex_str   = str_hex( $plain_str ); # HEX-style XX string escaping
  my $plain_str = str_unhex( $hex_str );

  # --------------------------------------------------------------------------
  
  # converts perl package names to file names, f.e: returns "Data/Tools.pm"
  my $perl_pkg_fn = perl_package_to_file( 'Data::Tools' );

  # --------------------------------------------------------------------------

  # calculating hex digests
  my $whirlpool_hex = wp_hex( $data );
  my $sha1_hex      = sha1_hex( $data );
  my $md5_hex       = md5_hex( $data );

  # --------------------------------------------------------------------------

  my $formatted_str = str_num_comma( 1234567.89 );   # returns "1'234'567.89"
  my $formatted_str = str_num_comma( 4325678, '_' ); # returns "4_325_678"
  my $padded_str    = str_pad( 'right', -12, '*' ); # returns "right*******"
  my $str_c         = str_countable( $dc, 'day', 'days' );
                      # returns 'days' for $dc == 0
                      # returns 'day'  for $dc == 1
                      # returns 'days' for $dc >  1

  my $num = str_kmg_to_num(   '1K' ); # returns 1024   
  my $num = str_kmg_to_num( '2.5M' ); # returns 2621440
  my $num = str_kmg_to_num(   '1T' ); # returns 1099511627776

  # --------------------------------------------------------------------------

  # find all *.txt files in all subdirectories starting from /usr/local
  # returned files are with full path names
  my @files = glob_tree( '/usr/local/*.txt' );

  # read directory entries names (without full paths)
  my @files_and_dirs = read_dir_entries( '/tmp/secret/dir' );

  # --------------------------------------------------------------------------

  my $int   = bcd2int( $bcd_bytes ); # convert BCD byte data to integer
  my $bytes = int2bcd( $int );       # convert integer to BCD bytes
  my $str   = bcd2str( $bcd_bytes ); # convert BCD byte data to string

=head1 FUNCTIONS

=head2 hash_validate( $data_hr, $validate_hr );

Return value can be either scalar or array context. In scalar context return
value is true (1) or false (0). In array context it returns list of the invalid
keys (possibly key paths like 'KEY1/KEY2/KEY3'):

  # array context
  my @invalid_keys = hash_validate( $data_hr, $validate_hr );
  
  # scalar context
  print "YES!" if hash_validate( $data_hr, $validate_hr );

=head1 TODO

  (more docs)

=head1 DATA::TOOLS SUB-MODULES

Data::Tools package includes several sub-modules:

  * Data::Tools::Socket (socket I/O processing, TODO: docs)
  * Data::Tools::Time   (time processing)

=head1 REQUIRED MODULES

Data::Tools is designed to be simple, compact and self sufficient. 
However it uses some 3rd party modules:

  * Digest::Whirlpool
  * Digest::MD5
  * Digest::SHA1

=head1 SEE ALSO

For more complex cases of nested hash validation, 
check Data::Validate::Struct module by Thomas Linden, cheers :)

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/  


=cut

##############################################################################
1;
