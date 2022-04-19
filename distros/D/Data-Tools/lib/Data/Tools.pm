##############################################################################
#
#  Data::Tools perl module
#  Copyright (c) 2013-2022 Vladi Belperchinov-Shabanski "Cade" 
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

our $VERSION = '1.29';

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
              file_text_load
              file_text_load_ar

              file_mtime
              file_ctime
              file_atime
              file_size

              file_path
              file_name
              file_name_ext
              file_ext

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
              
              list_uniq

              str_escape 
              str_unescape 

              str_url_escape 
              str_url_unescape 
              
              str_html_escape 
              str_html_unescape 
              
              str_hex 
              str_unhex

              str_num_comma
              str_pad
              str_pad_center
              str_countable
              
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
              
              ref_freeze
              ref_thaw

              fork_exec_cmd
              
              parse_csv
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
    next if -d $path;
    mkdir( $path, $mask ) or return 0;
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
                   '>'  => '&gt;',
                   '<'  => '&lt;',
                   "'"  => '&rsquo;',
                   "`"  => '&lsquo;',
                   "&"  => '&amp;',
                   '"'  => '&quot;',
                   '\\' => '&#134;',
                   );

sub str_html_escape
{
  my $text = shift;

  $text =~ s/([<>`'])/$HTML_ESCAPES{ $1 }/ge;
  
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

sub __fftwalk
{
  my $e = shift;
  my $a = shift;
  my $f = shift; # filter: 0 all, 1 files, 2 dirs
  
  opendir( my $dir, $e ) or return undef;
  my $ee;
  while( $ee = readdir $dir )
    {
    next if $ee eq '.' or $ee eq '..';
    my $eee = "$e/$ee";
    
    next if -l $eee; # FIXME: TODO: OPTION!!!!!!!!!
    
    if( -d $eee )
      {
      push @$a, $eee if $f != 1;
      __fftwalk( $eee, $a, $f );
      }
    else
      {
      push @$a, $eee if $f != 2;
      }  
    }
  closedir( $dir );
}

# fast file tree walk
# first argument can be options hash and is optional
# rest of arguments are directory names to be walked
# options hash can have:
# ARRAY => hashref_for_result_list
# MODE  => ALL   or 0 to scan all files and dirs
# MODE  => FILES or 1 to scan files only
# MODE  => DIRS  or 2 to scan directories only
sub fftwalk
{
  my $opt = hash_uc( ref( $_[0] ) eq 'HASH' ? shift : {} );
  
  my $f;
  $f = 0 if $opt->{ 'MODE' } =~ /^(A(LL)?|0|\*|FD|DF)$/i;
  $f = 1 if $opt->{ 'MODE' } =~ /^(F(ILES)?|1)$/i;
  $f = 2 if $opt->{ 'MODE' } =~ /^(D(IRS)?|2)$/i;

  my $e = $opt->{ 'ARRAY' } ? $opt->{ 'ARRAY' } : [];

  __fftwalk( $_, $e, $f ) for @_;
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

sub fork_exec_cmd
{
  my $cmd = shift;
  
  my $pid = fork();
  return undef if ! defined $pid; # fork failed
  return $pid if $pid;            # master process here
  exec $cmd;                      # sub process here  
  exit;                           # if sub exec fails...
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

  # --------------------------------------------------------------------------

  # find all *.txt files in all subdirectories starting from /usr/local
  # returned files are with full path names
  my @files = glob_tree( '/usr/local/*.txt' );

  # read directory entries names (without full paths)
  my @files_and_dirs = read_dir_entries( '/tmp/secret/dir' );

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
