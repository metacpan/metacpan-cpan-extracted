package Class::Usul::Functions;

use strict;
use warnings;
use parent 'Exporter::Tiny';

use Class::Inspector;
use Class::Null;
use Class::Usul::Constants     qw( ASSERT DEFAULT_CONFHOME DEFAULT_ENVDIR
                                   DIGEST_ALGORITHMS EXCEPTION_CLASS
                                   PERL_EXTNS PREFIX UNTAINT_CMDLINE
                                   UNTAINT_IDENTIFIER UNTAINT_PATH UUID_PATH );
use Cwd                        qw( );
use Data::Printer      alias => q(_data_dumper), colored => 1, indent => 3,
    filters => { 'DateTime'            => sub { $_[ 0 ].q()           },
                 'File::DataClass::IO' => sub { $_[ 0 ]->pathname     },
                 'JSON::XS::Boolean'   => sub { $_[ 0 ].q()           },
                 'Type::Tiny'          => sub { $_[ 0 ]->display_name },
                 'Type::Tiny::Enum'    => sub { $_[ 0 ]->display_name },
                 'Type::Tiny::Union'   => sub { $_[ 0 ]->display_name }, };
use Digest                     qw( );
use Digest::MD5                qw( md5 );
use English                    qw( -no_match_vars );
use Fcntl                      qw( F_SETFL O_NONBLOCK );
use File::Basename             qw( basename dirname );
use File::DataClass::Functions qw( supported_extensions );
use File::DataClass::IO        qw( );
use File::HomeDir              qw( );
use File::Spec::Functions      qw( canonpath catdir catfile curdir );
use List::Util                 qw( first );
use Module::Runtime            qw( is_module_name require_module );
use Scalar::Util               qw( blessed openhandle );
use Socket                     qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Symbol;
use Sys::Hostname              qw( hostname );
use Unexpected::Functions      qw( is_class_loaded PathAlreadyExists
                                   PathNotFound Tainted Unspecified );
use User::pwent;

our @EXPORT_OK =   qw( abs_path app_prefix arg_list assert assert_directory
                       base64_decode_ns base64_encode_ns bsonid bsonid_time
                       bson64id bson64id_time canonicalise class2appdir
                       classdir classfile create_token create_token64 cwdp
                       dash2under data_dumper digest distname elapsed emit
                       emit_err emit_to ensure_class_loaded env_prefix
                       escape_TT exception find_apphome find_source first_char
                       fqdn fullname get_cfgfiles get_user hex2str home2appldir
                       io is_arrayref is_coderef is_hashref is_member is_win32
                       list_attr_of loginid logname merge_attributes my_prefix
                       nonblocking_write_pipe_pair ns_environment pad
                       prefix2class socket_pair split_on__ split_on_dash
                       squeeze strip_leader sub_name symlink thread_id throw
                       throw_on_error trim unescape_TT untaint_cmdline
                       untaint_identifier untaint_path untaint_string urandom
                       uuid whiten zip chain compose curry fold Y factorial
                       fibonacci product sum );

our %EXPORT_REFS =   ( assert => sub { ASSERT }, );
our %EXPORT_TAGS =   ( all    => [ @EXPORT_OK ], );

# Package variables
my $bson_id_count : shared = 0;
my $bson2_id_count  = 0;
my $bson2_prev_time = 0;
my $digest_cache;
my $host_id = substr md5( hostname ), 0, 3;

# Private functions
my $_base64_char_set = sub {
   return [ 0 .. 9, 'A' .. 'Z', '_', 'a' .. 'z', '~', '+' ];
};

my $_bsonid_inc = sub {
   my ($now, $version) = @_;

   $version or return substr pack( 'N', $bson_id_count++ % 0xFFFFFF ), 1, 3;

   $bson2_id_count++; $now > $bson2_prev_time and $bson2_id_count = 0;
   $bson2_prev_time = $now;

   $version < 2 and return (substr pack( 'n', thread_id() % 0xFF ), 1, 1)
                          .(pack 'n', $bson2_id_count % 0xFFFF);

   $version < 3 and return (pack 'n', thread_id() % 0xFFFF )
                          .(pack 'n', $bson2_id_count % 0xFFFF);

   return (pack 'n', thread_id() % 0xFFFF )
         .(substr pack( 'N', $bson2_id_count % 0xFFFFFF ), 1, 3);
};

my $_bsonid_time = sub {
   my ($now, $version) = @_;

   (not $version or $version < 2) and return pack 'N', $now;

   $version < 3 and return (substr pack( 'N', $now >> 32 ), 2, 2)
                          .(pack 'N', $now % 0xFFFFFFFF);

   return (pack 'N', $now >> 32).(pack 'N', $now % 0xFFFFFFFF);
};

my $_catpath = sub {
   return untaint_path( catfile( @_ ) );
};

my $_get_env_var_for_conf = sub {
   my $file = $ENV{ ($_[ 0 ] || return) };
   my $path = $file ? dirname( $file ) : q();

   return $path = assert_directory( $path ) ? $path : undef;
};

my $_get_pod_content_for_attr = sub {
   my ($class, $attr) = @_; my $pod;

   my $src    = find_source( $class )
      or throw( 'Class [_1] cannot find source', [ $class ] );
   my $events = Pod::Eventual::Simple->read_file( $src );

   for (my $ev_no = 0, my $max = @{ $events }; $ev_no < $max; $ev_no++) {
      my $ev = $events->[ $ev_no ]; $ev->{type} eq 'command' or next;

      $ev->{content} =~ m{ (?: ^|[< ]) $attr (?: [ >]|$ ) }msx or next;

      $ev_no++ while ($ev = $events->[ $ev_no + 1 ] and $ev->{type} eq 'blank');

      $ev and $ev->{type} eq 'text' and $pod = $ev->{content} and last;
   }

   $pod //= 'Undocumented'; chomp $pod; $pod =~ s{ [\n] }{ }gmx;

   $pod = squeeze( $pod ); $pod =~ m{ \A (.+) \z }msx and $pod = $1;

   return $pod;
};

my $_index64 = sub {
   return [ qw(XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX 64  XX XX XX XX
                0  1  2  3   4  5  6  7   8  9 XX XX  XX XX XX XX
               XX 10 11 12  13 14 15 16  17 18 19 20  21 22 23 24
               25 26 27 28  29 30 31 32  33 34 35 XX  XX XX XX 36
               XX 37 38 39  40 41 42 43  44 45 46 47  48 49 50 51
               52 53 54 55  56 57 58 59  60 61 62 XX  XX XX 63 XX

               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX
               XX XX XX XX  XX XX XX XX  XX XX XX XX  XX XX XX XX) ];
};

my $_pseudo_random = sub {
   return join q(), time, rand 10_000, $PID, {};
};

my $_bsonid = sub {
   my $version = shift;
   my $now     = time;
   my $time    = $_bsonid_time->( $now, $version );
   my $pid     = pack 'n', $PID % 0xFFFF;

   return $time.$host_id.$pid.$_bsonid_inc->( $now, $version );
};

my $_find_cfg_in_inc = sub {
   my ($classdir, $file, $extns) = @_;

   for my $dir (grep { defined and -d $_ }
                map  { abs_path( catdir( $_, $classdir ) ) } @INC) {
      for my $extn (@{ $extns // [ supported_extensions() ] }) {
         my $path = $_catpath->( $dir, $file.$extn );

         -f $path and return dirname( $path );
      }
   }

   return;
};

my $_read_variable = sub {
   my ($dir, $file, $variable) = @_; my $path;

  ($dir and $file and $variable) or return;
   is_arrayref( $dir ) and $dir = catdir( @{ $dir } );
   $path = io( $_catpath->( $dir, $file ) )->chomp;
  ($path->exists and $path->is_file) or return;

   return first   { length }
          map     { trim( (split '=', $_)[ 1 ] ) }
          grep    { m{ \A \s* $variable \s* [=] }mx }
          reverse $path->getlines;
};

my $_get_file_var = sub {
   my ($dir, $file, $classdir) = @_;

   my $path; $path = $_read_variable->( $dir, ".${file}", 'APPLDIR' )
         and $path = catdir( $path, 'lib', $classdir );

   return $path = assert_directory( $path ) ? $path : undef;
};

my $_get_known_file_var = sub {
   my ($appname, $classdir) = @_; length $appname or return;

   my $path; $path = $_read_variable->( DEFAULT_ENVDIR(), $appname, 'APPLDIR' )
         and $path = catdir( $path, 'lib', $classdir );

   return $path = assert_directory( $path ) ? $path : undef;
};

# Construction
sub _exporter_fail {
    my ($class, $name, $value, $globals) = @_;

    exists $EXPORT_REFS{ $name }
       and return ( $name => $EXPORT_REFS{ $name }->() );

    throw( 'Subroutine [_1] not found in package [_2]', [ $name, $class ] );
}

# Public functions
sub abs_path ($) {
   my $v = shift; (defined $v and length $v) or return $v;

   is_ntfs() and not -e $v and return untaint_path( $v ); # Hate

   $v = Cwd::abs_path( untaint_path( $v ) );

   is_win32() and defined $v and $v =~ s{ / }{\\}gmx; # More hate

   return $v;
}

sub app_prefix ($) {
   (my $v = lc ($_[ 0 ] // q())) =~ s{ :: }{_}gmx; return $v;
}

sub arg_list (;@) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'HASH' ? { %{ $_[ 0 ] } }
        : $_[ 0 ]                          ? { @_ }
                                           : {};
}

sub assert_directory ($) {
   my $v = abs_path( $_[ 0 ] );

   defined $v and length $v and -d "${v}" and return $v;

   return;
}

sub base64_decode_ns ($) {
   my $x = shift; defined $x or return; my @x = split q(), $x;

   my $index = $_index64->(); my $j = 0; my $k = 0;

   my $len = length $x; my $pad = 64; my @y = ();

 ROUND: {
    while ($j < $len) {
       my @c = (); my $i = 0;

       while ($i < 4) {
          my $uc = $index->[ ord $x[ $j++ ] ];

          $uc ne 'XX' and $c[ $i++ ] = 0 + $uc; $j == $len or next;

          if ($i < 4) {
             $i < 2 and last ROUND; $i == 2 and $c[ 2 ] = $pad; $c[ 3 ] = $pad;
          }

          last;
       }

      ($c[ 0 ]   == $pad || $c[ 1 ] == $pad) and last;
       $y[ $k++ ] = ( $c[ 0 ] << 2) | (($c[ 1 ] & 0x30) >> 4);
       $c[ 2 ]   == $pad and last;
       $y[ $k++ ] = (($c[ 1 ] & 0x0F) << 4) | (($c[ 2 ] & 0x3C) >> 2);
       $c[ 3 ]   == $pad and last;
       $y[ $k++ ] = (($c[ 2 ] & 0x03) << 6) | $c[ 3 ];
    }
 }

   return join q(), map { chr $_ } @y;
}

sub base64_encode_ns (;$) {
   my $x = shift; defined $x or return; my @x = split q(), $x;

   my $basis = $_base64_char_set->(); my $len = length $x; my @y = ();

   for (my $i = 0, my $j = 0; $len > 0; $len -= 3, $i += 3) {
      my $c1 = ord $x[ $i ]; my $c2 = $len > 1 ? ord $x[ $i + 1 ] : 0;

      $y[ $j++ ] = $basis->[ $c1 >> 2 ];
      $y[ $j++ ] = $basis->[ (($c1 & 0x3) << 4) | (($c2 & 0xF0) >> 4) ];

      if ($len > 2) {
         my $c3 = ord $x[ $i + 2 ];

         $y[ $j++ ] = $basis->[ (($c2 & 0xF) << 2) | (($c3 & 0xC0) >> 6) ];
         $y[ $j++ ] = $basis->[ $c3 & 0x3F ];
      }
      elsif ($len == 2) {
         $y[ $j++ ] = $basis->[ ($c2 & 0xF) << 2 ];
         $y[ $j++ ] = $basis->[ 64 ];
      }
      else { # len == 1
         $y[ $j++ ] = $basis->[ 64 ];
         $y[ $j++ ] = $basis->[ 64 ];
      }
   }

   return join q(), @y;
}

sub bsonid (;$) {
   return unpack 'H*', $_bsonid->( $_[ 0 ] );
}

sub bsonid_time ($) {
   return unpack 'N', substr hex2str( $_[ 0 ] ), 0, 4;
}

sub bson64id (;$) {
   return base64_encode_ns( $_bsonid->( 2 ) );
}

sub bson64id_time ($) {
   return unpack 'N', substr base64_decode_ns( $_[ 0 ] ), 2, 4;
}

sub canonicalise ($;$) {
   my ($base, $relpath) = @_;

   $base = is_arrayref( $base ) ? catdir( @{ $base } ) : $base;
   $relpath or return canonpath( untaint_path( $base ) );

   my @relpath = is_arrayref( $relpath ) ? @{ $relpath } : $relpath;
   my $path    = canonpath( untaint_path( catdir( $base, @relpath ) ) );

   -d $path and return $path;

   return canonpath( untaint_path( catfile( $base, @relpath ) ) );
}

sub class2appdir ($) {
   return lc distname( $_[ 0 ] );
}

sub classdir ($) {
   return catdir( split m{ :: }mx, $_[ 0 ] // q() );
}

sub classfile ($) {
   return catfile( split m{ :: }mx, $_[ 0 ].'.pm' );
}

sub create_token (;$) {
   return digest( $_[ 0 ] // urandom() )->hexdigest;
}

sub create_token64 (;$) {
   return digest( $_[ 0 ] // urandom() )->b64digest;
}

sub cwdp () {
   return abs_path( curdir );
}

sub dash2under (;$) {
  (my $v = $_[ 0 ] // q()) =~ s{ [\-] }{_}gmx; return $v;
}

sub data_dumper (;@) {
   _data_dumper( @_ ); return 1;
}

sub digest ($) {
   my $seed = shift; my ($candidate, $digest);

   if ($digest_cache) { $digest = Digest->new( $digest_cache ) }
   else {
      for (DIGEST_ALGORITHMS) {
         $candidate = $_; $digest = eval { Digest->new( $candidate ) } and last;
      }

      $digest or throw( 'Digest algorithm not found' );
      $digest_cache = $candidate;
   }

   $digest->add( $seed );

   return $digest;
}

sub distname ($) {
   (my $v = $_[ 0 ] // q()) =~ s{ :: }{-}gmx; return $v;
}

#head2 downgrade
#   $sv_pv = downgrade $sv_pvgv;
#Horrendous Perl bug is promoting C<PV> and C<PVMG> type scalars to
#C<PVGV>. Serializing these values with L<Storable> throws a can't
#store SCALAR items error. This functions copies the string value of
#the input scalar to the output scalar but resets the output scalar
#type to C<PV>
#sub downgrade (;$) {
#   my $x = shift // q(); my ($y) = $x =~ m{ (.*) }msx; return $y;
#}

sub elapsed () {
   return time - $BASETIME;
}

sub emit (;@) {
   my @args = @_; $args[ 0 ] //= q(); chomp( @args );

   local ($OFS, $ORS) = ("\n", "\n");

   return openhandle *STDOUT ? emit_to( *STDOUT, @args ) : undef;
}

sub emit_err (;@) {
   my @args = @_; $args[ 0 ] //= q(); chomp( @args );

   local ($OFS, $ORS) = ("\n", "\n");

   return openhandle *STDERR ? emit_to( *STDERR, @args ) : undef;
}

sub emit_to ($;@) {
   my ($handle, @args) = @_; local $OS_ERROR;

   return (print {$handle} @args or throw( 'IO error: [_1]', [ $OS_ERROR ] ));
}

sub ensure_class_loaded ($;$) {
   my ($class, $opts) = @_; $opts //= {};

   $class or throw( Unspecified, [ 'class name' ], level => 2 );

   is_module_name( $class )
      or throw( 'String [_1] invalid classname', [ $class ], level => 2 );

   not $opts->{ignore_loaded} and is_class_loaded( $class ) and return 1;

   eval { require_module( $class ) }; throw_on_error( { level => 3 } );

   is_class_loaded( $class )
      or throw( 'Class [_1] loaded but package undefined',
                [ $class ], level => 2 );

   return 1;
}

sub env_prefix ($) {
   return uc app_prefix( $_[ 0 ] );
}

sub escape_TT (;$$) {
   my $v  = defined $_[ 0 ] ? $_[ 0 ] : q();
   my $fl = ($_[ 1 ] && $_[ 1 ]->[ 0 ]) || '<';
   my $fr = ($_[ 1 ] && $_[ 1 ]->[ 1 ]) || '>';

   $v =~ s{ \[\% }{${fl}%}gmx; $v =~ s{ \%\] }{%${fr}}gmx;

   return $v;
}

sub exception (;@) {
   return EXCEPTION_CLASS->caught( @_ );
}

sub find_apphome ($;$$) {
   my ($appclass, $default, $extns) = @_; my $path;

   # 0. Pass the directory in (short circuit the search)
   $path = assert_directory $default and return $path;

   my $app_pref = app_prefix   $appclass;
   my $appdir   = class2appdir $appclass;
   my $classdir = classdir     $appclass;
   my $env_pref = env_prefix   $appclass;
   my $my_home  = File::HomeDir->my_home;

   # 1a.   Environment variable - for application directory
   $path = assert_directory $ENV{ "${env_pref}_HOME" } and return $path;
   # 1b.   Environment variable - for config file
   $path = $_get_env_var_for_conf->( "${env_pref}_CONFIG" ) and return $path;
   # 2a.   Users XDG_DATA_HOME env variable or XDG default share directory
   $path = $ENV{ 'XDG_DATA_HOME' } // catdir( $my_home, '.local', 'share' );
   $path = assert_directory catdir( $path, $appdir ) and return $path;
   # 2b.   Users home directory - dot file containing shell env variable
   $path = $_get_file_var->( $my_home, $app_pref, $classdir ) and return $path;
   $path = $_get_file_var->( $my_home, $appdir,   $classdir ) and return $path;
   # 2c.   Users home directory - dot directory is apphome
   $path = catdir( $my_home, ".${app_pref}" );
   $path = assert_directory $path and return $path;
   $path = catdir( $my_home, ".${appdir}" );
   $path = assert_directory $path and return $path;
   # 3.    Well known path containing shell env file
   $path = $_get_known_file_var->( $appdir, $classdir ) and return $path;
   # 4.    Default install prefix
   $path = catdir( @{ PREFIX() }, $appdir, 'default', 'lib', $classdir );
   $path = assert_directory $path and return $path;
   # 5a.   Config file found in @INC - underscore as separator
   $path = $_find_cfg_in_inc->( $classdir, $app_pref, $extns ) and return $path;
   # 5b.   Config file found in @INC - dash as separator
   $path = $_find_cfg_in_inc->( $classdir, $appdir,   $extns ) and return $path;
   # 6.    Default to /tmp
   return  untaint_path( DEFAULT_CONFHOME );
}

sub find_source ($) {
   my $class = shift; my $file = classfile( $class ); my $path;

   for (@INC) {
      $path = abs_path( catfile( $_, $file ) ) and -f $path and return $path;
   }

   return;
}

sub first_char ($) {
   return substr $_[ 0 ], 0, 1;
}

sub fqdn (;$) {
   my $x = shift // hostname; return (gethostbyname( $x ))[ 0 ];
}

sub fullname () {
   my $v = (split m{ \s* , \s * }msx, (get_user()->gecos // q()))[ 0 ];

   $v //= q(); $v =~ s{ [\&] }{}gmx; # Coz af25e158-d0c7-11e3-bdcb-31d9eda79835

   return untaint_cmdline( $v );
}

sub get_cfgfiles ($;$$) {
   my ($appclass, $dirs, $extns) = @_;

   $appclass // throw( Unspecified, [ 'application class' ], level => 2 );
   is_arrayref( $dirs ) or $dirs = [ $dirs || curdir ];

   my $app_pref = app_prefix   $appclass;
   my $appdir   = class2appdir $appclass;
   my $env_pref = env_prefix   $appclass;
   my $suffix   = $ENV{ "${env_pref}_CONFIG_LOCAL_SUFFIX" } // '_local';
   my @paths    = ();

   for my $dir (@{ $dirs }) {
      for my $extn (@{ $extns // [ supported_extensions() ] }) {
         for my $path (map { $_catpath->( $dir, $_ ) } "${app_pref}${extn}",
                       "${appdir}${extn}", "${app_pref}${suffix}${extn}",
                       "${appdir}${suffix}${extn}") {
            -f $path and push @paths, $path;
         }
      }
   }

   return \@paths;
}

sub get_user (;$) {
   my $user = shift; is_win32() and return Class::Null->new;

   defined $user and $user !~ m{ \A \d+ \z }mx and return getpwnam( $user );

   return getpwuid( $user // $UID );
}

sub hex2str (;$) {
   my @a = split m{}mx, shift // q(); my $str = q();

   while (my ($x, $y) = splice @a, 0, 2) { $str .= pack 'C', hex "${x}${y}" }

   return $str;
}

sub home2appldir ($) {
   $_[ 0 ] or return; my $dir = io( $_[ 0 ] );

   $dir = $dir->parent while ($dir ne $dir->parent and $dir !~ m{ lib \z }mx);

   return $dir ne $dir->parent ? $dir->parent : undef;
}

sub io (;@) {
   return File::DataClass::IO->new( @_ );
}

sub is_arrayref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'ARRAY' ? 1 : 0;
}

sub is_coderef (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'CODE' ? 1 : 0;
}

sub is_hashref (;$) {
   return $_[ 0 ] && ref $_[ 0 ] eq 'HASH' ? 1 : 0;
}

sub is_member (;@) {
   my ($candidate, @args) = @_; $candidate or return;

   is_arrayref $args[ 0 ] and @args = @{ $args[ 0 ] };

   return (first { $_ eq $candidate } @args) ? 1 : 0;
}

sub is_ntfs  () {
   return is_win32() || lc $OSNAME eq 'cygwin' ? 1 : 0;
}

sub is_win32 () {
   return lc $OSNAME eq 'mswin32' ? 1 : 0;
}

sub list_attr_of ($;@) {
   my ($obj, @except) = @_; my $class = blessed $obj;

   ensure_class_loaded( 'Pod::Eventual::Simple' );

   is_member 'new', @except or push @except, 'new';

   return map  { my $attr = $_->[0]; [ @{ $_ }, $obj->$attr ] }
          map  { [ $_->[1], $_->[0], $_get_pod_content_for_attr->( @{ $_ } ) ] }
          grep { $_->[0] ne 'Moo::Object' and not is_member $_->[1], @except }
          map  { m{ \A (.+) \:\: ([^:]+) \z }mx; [ $1, $2 ] }
              @{ Class::Inspector->methods( $class, 'full', 'public' ) };
}

sub loginid (;$) {
   return untaint_cmdline( get_user( $_[ 0 ] )->name || 'unknown' );
}

sub logname (;$) { # Deprecated use loginid
   return untaint_cmdline( $ENV{USER} || $ENV{LOGNAME} || loginid( $_[ 0 ] ) );
}

sub merge_attributes ($@) {
   my ($dest, @args) = @_;

   my $attr = is_arrayref( $args[ -1 ] ) ? pop @args : [];

   for my $k (grep { not exists $dest->{ $_ } or not defined $dest->{ $_ } }
                  @{ $attr }) {
      my $i = 0; my $v;

      while (not defined $v and defined( my $src = $args[ $i++ ] )) {
         my $class = blessed $src;

         $v = $class ? ($src->can( $k ) ? $src->$k() : undef) : $src->{ $k };
      }

      defined $v and $dest->{ $k } = $v;
   }

   return $dest;
}

sub my_prefix (;$) {
   return split_on__( basename( $_[ 0 ] // q(), PERL_EXTNS ) );
}

sub nonblocking_write_pipe_pair () {
   my ($r, $w); pipe $r, $w or throw( 'No pipe' );

   fcntl $w, F_SETFL, O_NONBLOCK; $w->autoflush( 1 );

   binmode $r; binmode $w;

   return [ $r, $w ];
}

sub ns_environment ($$;$) {
   my ($class, $k, $v) = @_; $k = (env_prefix $class).'_'.(uc $k);

   return defined $v ? $ENV{ $k } = $v : $ENV{ $k };
}

sub pad ($$;$$) {
   my ($v, $wanted, $str, $direction) = @_; my $len = $wanted - length $v;

   $len > 0 or return $v; (defined $str and length $str) or $str = q( );

   my $pad = substr( $str x $len, 0, $len );

   (not $direction or $direction eq 'right') and return $v.$pad;
   $direction eq 'left' and return $pad.$v;

   return (substr $pad, 0, int( (length $pad) / 2 )).$v
         .(substr $pad, 0, int( 0.99999999 + (length $pad) / 2 ));
}

sub prefix2class (;$) {
   return join '::', map { ucfirst } split m{ - }mx, my_prefix( $_[ 0 ] );
}

sub socket_pair () {
   my $rdr = gensym; my $wtr = gensym;

   socketpair( $rdr, $wtr, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
     or throw( $EXTENDED_OS_ERROR );
   shutdown  ( $rdr, 1 );  # No more writing for reader
   shutdown  ( $wtr, 0 );  # No more reading for writer

   return [ $rdr, $wtr ];
}

sub split_on__ (;$$) {
   return (split m{ _ }mx, $_[ 0 ] // q())[ $_[ 1 ] // 0 ];
}

sub split_on_dash (;$$) {
   return (split m{ \- }mx, $_[ 0 ] // q())[ $_[ 1 ] // 0 ];
}

sub squeeze (;$) {
   (my $v = $_[ 0 ] // q()) =~ s{ \s+ }{ }gmx; return $v;
}

sub strip_leader (;$) {
   (my $v = $_[ 0 ] // q()) =~ s{ \A [^:]+ [:] \s+ }{}msx; return $v;
}

sub sub_name (;$) {
   my $frame = 1 + ($_[ 0 ] // 0);

   return (split m{ :: }mx, ((caller $frame)[ 3 ]) // 'main')[ -1 ];
}

sub symlink (;$$$) {
   my ($from, $to, $base) = @_;

   defined $base and not CORE::length $base and $base = File::Spec->rootdir;
   $from or throw( Unspecified, [ 'path from' ] );
   $from = io( $from )->absolute( $base );
   $from->exists or throw( PathNotFound, [ "${from}" ] );
   $to   or throw( Unspecified, [ 'path to' ] );
   $to   = io( $to   )->absolute( $base ); $to->is_link and $to->unlink;
   $to->exists  and throw( PathAlreadyExists, [ "${to}" ] );
   CORE::symlink "${from}", "${to}"
      or throw( 'Symlink from [_1] to [_2] failed: [_3]',
                [ "${from}", "${to}", $OS_ERROR ] );
   return "Symlinked ${from} to ${to}";
}

sub thread_id () {
   return exists $INC{ 'threads.pm' } ? threads->tid() : 0;
}

sub throw (;@) {
   EXCEPTION_CLASS->throw( @_ );
}

sub throw_on_error (;@) {
   EXCEPTION_CLASS->throw_on_error( @_ );
}

sub trim (;$$) {
   my $chs = $_[ 1 ] // " \t"; (my $v = $_[ 0 ] // q()) =~ s{ \A [$chs]+ }{}mx;

   chomp $v; $v =~ s{ [$chs]+ \z }{}mx; return $v;
}

sub unescape_TT (;$$) {
   my $v  = defined $_[ 0 ] ? $_[ 0 ] : q();
   my $fl = ($_[ 1 ] && $_[ 1 ]->[ 0 ]) || '<';
   my $fr = ($_[ 1 ] && $_[ 1 ]->[ 1 ]) || '>';

   $v =~ s{ ${fl}\% }{[%}gmx; $v =~ s{ \%${fr} }{%]}gmx;

   return $v;
}

sub untaint_cmdline (;$) {
   return untaint_string( UNTAINT_CMDLINE, $_[ 0 ] );
}

sub untaint_identifier (;$) {
   return untaint_string( UNTAINT_IDENTIFIER, $_[ 0 ] );
}

sub untaint_path (;$) {
   return untaint_string( UNTAINT_PATH, $_[ 0 ] );
}

sub untaint_string ($;$) {
   my ($regex, $string) = @_;

   defined $string or return; length $string or return q();

   my ($untainted) = $string =~ $regex;

   (defined $untainted and $untainted eq $string)
      or throw( Tainted, [ $string ], level => 3 );

   return $untainted;
}

sub urandom (;$$) {
   my ($wanted, $opts) = @_; $wanted //= 64; $opts //= {};

   my $default = [ q(), 'dev', $OSNAME eq 'freebsd' ? 'random' : 'urandom' ];
   my $io      = io( $opts->{source} // $default )->block_size( $wanted );

   my $red; $io->exists and $io->is_readable and $red = $io->read
      and $red == $wanted and return ${ $io->buffer };

   my $res = q(); while (length $res < $wanted) { $res .= $_pseudo_random->() }

   return substr $res, 0, $wanted;
}

sub uuid (;$) {
   return io( $_[ 0 ] // UUID_PATH )->chomp->getline;
}

sub whiten ($) {
   my $v = unpack "b*", pop; my $pad = " \t" x 8;

   $v =~ tr{01}{ \t}; $v =~ s{ (.{9}) }{$1\n}gmx;

   return "${pad}\n${v}";
}

sub zip (@) {
   my $p = @_ / 2; return @_[ map { $_, $_ + $p } 0 .. $p - 1 ];
}

# Function composition
sub chain (;@) {
   return (fold( sub { my ($x, $y) = @_; $x->$y } )->( shift ))->( @_ );
}

sub compose (&;$) { # Was called build
   my ($f, $g) = @_; $g //= sub { @_ }; return sub { $f->( $g->( @_ ) ) };
}

sub curry (&$;@) {
   my ($f, @args) = @_; return sub { $f->( @args, @_ ) };
}

sub fold (&) {
   my $f = shift;

   return sub (;$) {
      my $x = shift;

      return sub (;@) {
         my $y = $x; $y = $f->( $y, shift ) while (@_); return $y;
      }
   }
}

sub Y (&) {
   my $f = shift; return sub { $f->( Y( $f ) )->( @_ ) };
}

sub factorial ($) {
   return Y( sub (&) {
      my $fac  = shift;

      return sub ($) {
         my $n = shift;

         return $n < 2 ? 1 : $n * $fac->( $n - 1 ) } } )->( @_ );
}

sub fibonacci ($) {
   return Y( sub {
      my $fib  = shift;

      return sub {
         my $n = shift;

         return $n == 0 ? 0
              : $n == 1 ? 1
                        : $fib->( $n - 1 ) + $fib->( $n - 2 ) } } )->( @_ );
}

sub product (;@) {
   return ((fold { $_[ 0 ] * $_[ 1 ] })->( 1 ))->( @_ );
}

sub sum (;@) {
   return ((fold { $_[ 0 ] + $_[ 1 ] })->( 0 ))->( @_ );
}

1;

__END__

=pod

=head1 Name

Class::Usul::Functions - Globally accessible functions

=head1 Synopsis

   package MyBaseClass;

   use Class::Usul::Functions qw( functions to import );

=head1 Description

Provides globally accessible functions

=head1 Subroutines/Methods

=head2 C<abs_path>

   $absolute_untainted_path = abs_path $some_path;

Untaints path. Makes it an absolute path and returns it. Returns undef
otherwise. Traverses the filesystem

=head2 C<app_prefix>

   $prefix = app_prefix __PACKAGE__;

Takes a class name and returns it lower cased with B<::> changed to
B<_>, e.g. C<App::Munchies> becomes C<app_munchies>

=head2 C<arg_list>

   $args = arg_list @rest;

Returns a hash ref containing the passed parameter list. Enables
methods to be called with either a list or a hash ref as it's input
parameters

=head2 C<assert>

   assert $ioc_object, $condition, $message;

By default does nothing. Does not evaluate the passed parameters. The
L<assert|Classs::Usul::Constants/ASSERT> constant can be set via
an inherited class attribute to do something useful with whatever parameters
are passed to it

=head2 C<assert_directory>

   $untainted_path = assert_directory $path_to_directory;

Untaints directory path. Makes it an absolute path and returns it if it
exists. Returns undef otherwise

=head2 C<base64_decode_ns>

   $decoded_value = base64_decode_ns $encoded_value;

Decode a scalar value encode using L</base64_encode_ns>

=head2 C<base64_encode_ns>

   $encoded_value = base64_encode_ns $encoded_value;

Base 64 encode a scalar value using an output character set that preserves
the input values sort order (natural sort)

=head2 C<bsonid>

   $bson_id = bsonid;

Generate a new C<BSON> id. Returns a 24 character string of hex digits that
are reasonably unique across hosts and are in ascending order. Use this
to create unique ids for data streams like message queues and file feeds

=head2 C<bsonid_time>

   $seconds_elapsed_since_the_epoch = bsonid_time $bson_id;

Returns the time the C<BSON> id was generated as Unix time

=head2 C<bson64id>

   $base64_encoded_extended_bson64_id = bson64id;

Like L</bsonid> but better thread long running process support. A custom
Base64 encoding is used to reduce the id length

=head2 C<bson64id_time>

   $seconds_elapsed_since_the_epoch = bson64id_time $bson64_id;

Returns the time the C<BSON64> id was generated as Unix time

=head2 C<canonicalise>

   $untainted_canonpath = canonicalise $base, $relpath;

Appends C<$relpath> to C<$base> using L<File::Spec::Functions>. The C<$base>
and C<$relpath> arguments can be an array reference or a scalar. The return
path is untainted and canonicalised

=head2 C<class2appdir>

   $appdir = class2appdir __PACKAGE__;

Returns lower cased L</distname>, e.g. C<App::Munchies> becomes
C<app-munchies>

=head2 C<classdir>

   $dir_path = classdir __PACKAGE__;

Returns the path (directory) of a given class. Like L</classfile> but
without the I<.pm> extension

=head2 C<classfile>

   $file_path = classfile __PACKAGE__ ;

Returns the path (file name plus extension) of a given class. Uses
L<File::Spec> for portability, e.g. C<App::Munchies> becomes
C<App/Munchies.pm>

=head2 C<create_token>

   $random_hex = create_token $optional_seed;

Create a random string token using L</digest>. If C<$seed> is defined then add
that to the digest, otherwise add some random data provided by a call to
L</urandom>. Returns a hexadecimal string

=head2 C<create_token64>

   $random_base64 = create_token64 $optional_seed;

Like L</create_token> but the output is C<base64> encoded

=head2 C<cwdp>

   $current_working_directory = cwdp;

Returns the current working directory, physical location

=head2 C<dash2under>

   $string_with_underscores = dash2under 'a-string-with-dashes';

Substitutes underscores for dashes

=head2 C<data_dumper>

   data_dumper $thing;

Uses L<Data::Printer> to dump C<$thing> in colour to I<stderr>

=head2 C<digest>

   $digest_object = digest $seed;

Creates an instance of the first available L<Digest> class and adds the seed.
The constant C<DIGEST_ALGORITHMS> is consulted for the list of algorithms to
search for. Returns the digest object reference

=head2 C<distname>

   $distname = distname __PACKAGE__;

Takes a class name and returns it with B<::> changed to
B<->, e.g. C<App::Munchies> becomes C<App-Munchies>

=head2 C<elapsed>

   $elapsed_seconds = elapsed;

Returns the number of seconds elapsed since the process started

=head2 C<emit>

   emit @lines_of_text;

Prints to I<STDOUT> the lines of text passed to it. Lines are C<chomp>ed
and then have newlines appended. Throws on IO errors

=head2 C<emit_err>

   emit_err @lines_of_text;

Like L</emit> but output to C<STDERR>

=head2 C<emit_to>

   emit_to $filehandle, @lines_of_text;

Prints to the specified file handle

=head2 C<ensure_class_loaded>

   ensure_class_loaded $some_class, $options_ref;

Require the requested class, throw an error if it doesn't load

=head2 C<env_prefix>

   $prefix = env_prefix $class;

Returns upper cased C<app_prefix>. Suitable as prefix for environment
variables

=head2 C<escape_TT>

   $text = escape_TT '[% some_stash_key %]';

The left square bracket causes problems in some contexts. Substitute a
less than symbol instead. Also replaces the right square bracket with
greater than for balance. L<Template::Toolkit> will work with these
sequences too, so unescaping isn't absolutely necessary

=head2 C<exception>

   $e = exception $error;

Expose the C<catch> method in the exception
class L<Class::Usul::Exception>. Returns a new error object

=head2 C<find_apphome>

   $directory_path = find_apphome $appclass, $homedir, $extns

Returns the path to the applications home directory. Searches the following:

   # 0.  Pass the directory in (short circuit the search)
   # 1a. Environment variable - for application directory
   # 1b. Environment variable - for config file
   # 2a. Users XDG_DATA_HOME env variable or XDG default share directory
   # 2b. Users home directory - dot file containing shell env variable
   # 2c. Users home directory - dot directory is apphome
   # 3.  Well known path containing shell env file
   # 4.  Default install prefix
   # 5a. Config file found in @INC - underscore as separator
   # 5b. Config file found in @INC - dash as separator
   # 6.  Default to /tmp

=head2 C<find_source>

   $path = find_source $module_name;

Find absolute path to the source code for the given module

=head2 C<first_char>

   $single_char = first_char $some_string;

Returns the first character of C<$string>

=head2 C<fqdn>

   $domain_name = fqdn $hostname;

Call C<gethostbyname> on the supplied hostname whist defaults to this host

=head2 C<fullname>

   $fullname = fullname;

Returns the untainted first sub field from the gecos attribute of the
object returned by a call to L</get_user>. Returns the null string if
the gecos attribute value is false

=head2 C<get_cfgfiles>

   $paths = get_cfgfiles $appclass, $dirs, $extns

Returns an array ref of configurations file paths for the application

=head2 C<get_user>

   $user_object = get_user $optional_uid_or_name;

Returns the user object from a call to either C<getpwuid> or C<getpwnam>
depending on whether an integer or a string was passed. The L<User::pwent>
package is loaded so objects are returned. On MSWin32 systems returns an
instance of L<Class::Null>.  Defaults to the current uid but will lookup the
supplied uid if provided

=head2 C<hex2str>

   $string = hex2str $pairs_of_hex_digits;

Converts the pairs of hex digits into a string of characters

=head2 C<home2appldir>

   $appldir = home2appldir $home_dir;

Strips the trailing C<lib/my_package> from the supplied directory path

=head2 C<io>

   $io_object_ref = io $path_to_file_or_directory;

Returns a L<File::DataClass::IO> object reference

=head2 C<is_arrayref>

   $bool = is_arrayref $scalar_variable

Tests to see if the scalar variable is an array ref

=head2 C<is_coderef>

   $bool = is_coderef $scalar_variable

Tests to see if the scalar variable is a code ref

=head2 C<is_hashref>

   $bool = is_hashref $scalar_variable

Tests to see if the scalar variable is a hash ref

=head2 C<is_member>

   $bool = is_member 'test_value', qw( a_value test_value b_value );

Tests to see if the first parameter is present in the list of
remaining parameters

=head2 C<is_ntfs>

   $bool = is_ntfs;

Returns true if L</is_win32> is true or the C<$OSNAME> is
L<cygwin|File::DataClass::Constants/CYGWIN>

=head2 C<is_win32>

   $bool = is_win32;

Returns true if the C<$OSNAME> is
L<unfortunate|File::DataClass::Constants/MSOFT>

=head2 C<list_attr_of>

   $attribute_list = list_attr_of $object_ref, @exception_list;

Lists the attributes of the object reference, including defining class name,
documentation, and current value

=head2 C<loginid>

   $loginid = loginid;

Returns the untainted name attribute of the object returned by a call
to L</get_user> or 'unknown' if the name attribute value is false

=head2 C<logname>

   $logname = logname;

Deprecated. Returns untainted the first true value returned by; the environment
variable C<USER>, the environment variable C<LOGNAME>, and the function
L</loginid>

=head2 C<merge_attributes>

   $dest = merge_attributes $dest, $src, $defaults, $attr_list_ref;

Merges attribute hashes. The C<$dest> hash is updated and returned. The
C<$dest> hash values take precedence over the C<$src> hash values which
take precedence over the C<$defaults> hash values. The C<$src> hash
may be an object in which case its accessor methods are called

=head2 C<nonblocking_write_pipe_pair>

   $array_ref = non_blocking_write_pipe;

Returns a pair of file handles, read then write. The write file handle is
non blocking, binmode is set on both

=head2 C<my_prefix>

   $prefix = my_prefix $PROGRAM_NAME;

Takes the basename of the supplied argument and returns the first _
(underscore) separated field. Supplies basename with
L<extensions|Class::Usul::Constants/PERL_EXTNS>

=head2 C<ns_environment>

   $value = ns_environment $class, $key, $value;

An accessor / mutator for the environment variables prefixed by the supplied
class name. Providing a value is optional, always returns the current value

=head2 C<pad>

   $padded_str = pad $unpadded_str, $wanted_length, $pad_char, $direction;

Pad a string out to the wanted length with the C<$pad_char> which
defaults to a space. Direction can be; I<both>, I<left>, or I<right>
and defaults to I<right>

=head2 C<prefix2class>

   $class = prefix2class $PROGRAM_NAME;

Calls L</my_prefix> with the supplied argument, splits the result on dash,
C<ucfirst>s the list and then C<join>s that with I<::>

=head2 C<socket_pair>

   ($reader, $writer) = @{ socket_pair };

Return a C<socketpair> reader then writer. The writer has been closed on the
reader and the reader has been closed on the writer

=head2 C<split_on__>

   $field = split_on__ $string, $field_no;

Splits string by _ (underscore) and returns the requested field. Defaults
to field zero

=head2 C<split_on_dash>

   $field = split_on_dash $string, $field_no;

Splits string by - (dash) and returns the requested field. Defaults
to field zero

=head2 C<squeeze>

   $string = squeeze $string_containing_muliple_spacesd;

Squeezes multiple whitespace down to a single space

=head2 C<strip_leader>

   $stripped = strip_leader 'my_program: Error message';

Strips the leading "program_name: whitespace" from the passed argument

=head2 C<sub_name>

   $sub_name = sub_name $level;

Returns the name of the method that calls it

=head2 C<symlink>

   $message = symlink $from, $to, $base;

It creates a symlink. If either C<$from> or C<$to> is a relative path
then C<$base> is prepended to make it absolute. Returns a message
indicating success or throws an exception on failure

=head2 C<thread_id>

   $tid = thread_id;

Returns the id of this thread. Returns zero if threads are not loaded

=head2 C<throw>

   throw 'error_message', [ 'error_arg' ];

Expose L<Class::Usul::Exception/throw>. L<Class::Usul::Constants> has a
class attribute I<Exception_Class> which can be set change the class
of the thrown exception

=head2 C<throw_on_error>

   throw_on_error @args;

Passes it's optional arguments to L</exception> and if an exception object is
returned it throws it. Returns undefined otherwise. If no arguments are
passed L</exception> will use the value of the global C<$EVAL_ERROR>

=head2 C<trim>

   $trimmed_string = trim $string_with_leading_and_trailing_whitespace;

Remove leading and trailing whitespace including trailing newlines. Takes
an additional string used as the character class to remove. Defaults to
space and tab

=head2 C<unescape_TT>

   $text = unescape_TT '<% some_stash_key %>';

Do the reverse of C<escape_TT>

=head2 C<untaint_cmdline>

   $untainted_cmdline = untaint_cmdline $maybe_tainted_cmdline;

Returns an untainted command line string. Calls L</untaint_string> with the
matching regex from L<Class::Usul::Constants>

=head2 C<untaint_identifier>

   $untainted_identifier = untaint_identifier $maybe_tainted_identifier;

Returns an untainted identifier string. Calls L</untaint_string> with the
matching regex from L<Class::Usul::Constants>

=head2 C<untaint_path>

   $untainted_path = untaint_path $maybe_tainted_path;

Returns an untainted file path. Calls L</untaint_string> with the
matching regex from L<Class::Usul::Constants>

=head2 C<untaint_string>

   $untainted_string = untaint_string $regex, $maybe_tainted_string;

Returns an untainted string or throws

=head2 C<urandom>

   $bytes = urandom $optional_length, $optional_provider;

Returns random bytes. Length defaults to 64. The provider defaults to
F</dev/urandom> and can be any type accepted by L</io>. If the provider exists
and is readable, length bytes are read from it and returned. Otherwise some
bytes from the second best generator are returned

=head2 C<uuid>

   $uuid = uuid $optional_uuid_proc_filesystem_path;

Return the contents of F</proc/sys/kernel/random/uuid>

=head2 C<whiten>

   $encoded = whiten 'plain_text_to_be_obfuscated';

Lifted from L<Acme::Bleach> this function encodes the passed scalar as spaces,
tabs, and newlines. The L<encrypt> and L<decrypt> functions take a seed
attribute in their options hash reference. A whitened line of Perl code
would be a suitable value

=head2 C<zip>

   %hash = zip @list_of_keys, @list_of_values;

Zips two list of equal size together to form a hash

=head2 C<chain>

   $result = chain $sub1, $sub2, $sub3

Call each sub in turn passing the returned value as the first argument to
the next function call

=head2 C<compose>

   $code_ref = compose { }, $code_ref;

Returns a code reference which when called returns the result of calling the
block passing in the result of calling the optional code reference. Delays the
calling of the input code reference until the output code reference is called

=head2 C<curry>

   $curried_code_ref = curry $code_ref, @args;
   $result = $curried_code_ref->( @more_args );

Returns a subroutine reference which when called, calls and returns the
initial code reference passing in the original argument list and the
arguments from the curried call. Must be called with a code reference and
at least one argument

=head2 C<fold>

   *sum = fold { $a + $b } 0;

Classic reduce function with optional base value

=head2 C<Y>

   $code_ref = Y( $code_ref );

The Y-combinator function

=head2 C<factorial>

   $result = factorial $n;

Calculates the factorial for the supplied integer

=head2 C<fibonacci>

   $result = fibonacci $n;

Calculates the Fibonacci number for the supplied integer

=head2 C<product>

   $product = product 1, 2, 3, 4;

Returns the product of the list of numbers

=head2 C<sum>

   $total = sum 1, 2, 3, 4;

Adds the list of values

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<Class::Usul::Constants>

=item L<Data::Printer>

=item L<Digest>

=item L<File::HomeDir>

=item L<List::Util>

=back

=head1 Incompatibilities

The L</home2appldir> method is dependent on the installation path
containing a B<lib>

The L</uuid> method with only work on a OS with a F</proc> filesystem

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
