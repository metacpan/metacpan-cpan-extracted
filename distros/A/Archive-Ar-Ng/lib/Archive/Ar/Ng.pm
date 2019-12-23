###########################################################
#    Archive::Ar - Pure perl module to handle ar achives
#
#    Copyright 2003 - Jay Bonci <jaybonci@cpan.org>
#    Copyright 2014 - John Bazik <jbazik@cpan.org>
#    Copyright 2019 - Varadi Gabor <varadi@mithrandir.hu>
#    Copyright 2019 - Fazekas Balint <fazekas.balint@mithrandir.hu>
#    Licensed under the same terms as perl itself
#
###########################################################
package Archive::Ar::Ng;

use base qw( Exporter );
our @EXPORT_OK = qw( COMMON BSD GNU );

use strict;
use File::Spec;
use Time::Local;
use Carp qw( carp longmess );
use Fcntl qw( SEEK_SET SEEK_END );

use vars qw( $VERSION );
$VERSION = '2.04';

use constant CAN_CHOWN => ( $> == 0 and $^O ne 'MacOS' and $^O ne 'MSWin32' );

use constant ARMAG    => "!<arch>\n";
use constant SARMAG   => length( ARMAG );
use constant ARFMAG   => "`\n";
use constant AR_EFMT1 => "#1/";

use constant COMMON => 1;
use constant BSD    => 2;
use constant GNU    => 3;

sub new {
  my $class = shift;
  my $file  = shift;
  my $opts  = shift || 0;
  my $self  = bless {}, $class;
  my $defopts = {
                 chmod      => 1,
                 chown      => 1,
                 same_perms => ( $> == 0 ) ? 1 : 0,
                 symbols    => undef,
                };
  $opts = {warn => $opts} unless ref $opts;
  $self->clear();
  $self->{opts} = {( %$defopts, %{$opts} )};

  if ( $file ) {
    return unless $self->read( $file );
  }
  return $self;
}

sub clear {
  my $self = shift;
  $self->{names} = [];
  $self->{files} = {};
  $self->{type}  = undef;
  if ( defined $self->{fh} ) {
    close( $self->{fh} );
  }
  $self->{fh} = undef;
}

sub myread {
  my $self = shift;
  my $fpos = shift;
  my $rlen = shift;
  my $dvar = undef;
  sysseek( $self->{fh}, $fpos, SEEK_SET );
  sysread( $self->{fh}, $dvar, $rlen );
  return $dvar;
}

sub read {
  my $self = shift;
  my $file = shift;
  open my $fh, '<', $file or return $self->_error( "$file: $!" );
  binmode $fh;
  $self->{fh} = $fh;
  my $x = $self->_parse();
  return $x;
}

sub contains_file {
  my $self     = shift;
  my $filename = shift;
  return unless defined $filename;
  return exists $self->{files}->{$filename};
}

sub extract {
  my $self = shift;
  for my $filename ( @_ ? @_ : @{$self->{names}} ) {
    $self->extract_file( $filename ) or return;
  }
  return 1;
}

sub write {
  my $self     = shift;
  my $filename = shift;
  my $opts     = {( %{$self->{opts}}, %{shift || {}} )};
  my $type     = $opts->{type} || $self->{type} || COMMON;
  my $name;
  my @body = ( ARMAG );
  my %gnuindex;
  my @filenames = @{$self->{names}};
  my $fpos      = 0;
  my $tmpname   = ( defined $filename ) ? $filename : '/tmp/tmp.ar';
  $fpos += SARMAG;
  my $tmpfn = $self->_get_handle( $tmpname, '>' );
  if ( $type eq GNU ) {
    #
    # construct extended filename index, if needed
    #
    if ( my @longs = grep( length( $_ ) > 15, @filenames ) ) {
      my $ptr = 0;
      for my $long ( @longs ) {
        $gnuindex{$long} = $ptr;
        $ptr += length( $long ) + 2;
      }
      push @body, pack( 'A16A32A10A2', '//', '', $ptr, ARFMAG ), join( "/\n", @longs, '' );
      push @body, "\n" if $ptr % 2;    # padding
    }
  }
  print $tmpfn @body;
  for my $fn ( @filenames ) {
    @body = ();
    $fpos += 60;
    my $meta = $self->{files}->{$fn};
    my $mode = sprintf( '%o', $meta->{mode} );
    my $size = $meta->{size};
    my $name;
    print $fn;
    if ( $type eq GNU ) {
      $fn = '' if defined $opts->{symbols} && $fn eq $opts->{symbols};
      $name = $fn . '/';
    } else {
      $name = $fn;
    }
    if ( length( $name ) <= 16 || $type eq COMMON ) {
      push @body, pack( 'A16A12A6A6A8A10A2', $name, @$meta{qw/date uid gid/}, $mode, $size, ARFMAG );
    } elsif ( $type eq GNU ) {
      push @body, pack( 'A1A15A12A6A6A8A10A2', '/', $gnuindex{$fn}, @$meta{qw/date uid gid/}, $mode, $size, ARFMAG );
    } elsif ( $type eq BSD ) {
      $size += length( $name );
      push @body, pack( 'A3A13A12A6A6A8A10A2', AR_EFMT1, length( $name ), @$meta{qw/date uid gid/}, $mode, $size, ARFMAG ), $name;
    } else {
      return $self->_error( "$type: unexpected ar type" );
    }
    print $tmpfn @body;
    if ( defined $meta->{original_fname} ) {
      if ( open( my $rfn, '<:encoding(UTF-8)', $meta->{original_fname} ) ) {
        while ( my $row = <$rfn> ) {
          chomp $row;
          print $tmpfn $row . "\n";
        }
        close $rfn;
      }
    } else {
      print $tmpfn $self->myread( $fpos, $size );
    }
    $fpos += $size + ( $size % 2 );
    print $tmpfn "\n" if $size % 2;    # padding
  }
  if ( $filename ) {
    my $len      = 0;
    my @filestat = stat $tmpfn;
    $len = $filestat[7];
    close $tmpfn;
    return $len;
  } else {
    seek $tmpfn, 0, 0;
    binmode( $tmpfn );
    my $out = <$tmpfn>;
    close $tmpfn;
    unlink $tmpfn;
    return $out;
  }
}

sub _get_handle {
  my $self = shift;
  my $file = shift;
  my $mode = shift || '<';
  if ( ref $file ) {
    return $file if eval { *$file{IO} } or $file->isa( 'IO::Handle' );
    return $self->_error( "Not a filehandle" );
  } else {
    open my $fh, $mode, $file or return $self->_error( "$file: $!" );
    binmode $fh;
    return $fh;
  }
}

sub extract_file {
  my $self     = shift;
  my $filename = shift;
  my $target   = shift || $filename;
  my $meta     = $self->{files}->{$filename};
  return $self->_error( "$filename: not in archive" ) unless $meta;
  open my $fh, '>', $target or return $self->_error( "$target: $!" );
  binmode $fh;
##--
  sysseek( $self->{fh}, $meta->{fpos}, SEEK_SET );
  my $rpos = 0;
  my $rbuf;
  while ( $rpos < $meta->{size} ) {
    my $blk_size = ( $meta->{size} - $rpos );
    if ( $blk_size > 16384 ) {
      $blk_size = 16384;
    }
    $rpos += sysread( $self->{fh}, $rbuf, $blk_size ) or return $self->_error( "$filename: $!" );
    syswrite( $fh, $rbuf, $blk_size ) or return $self->_error( "$filename: $!" );
  }
  undef $rbuf;
##--
  close $fh or return $self->_error( "$filename: $!" );
  if ( CAN_CHOWN && $self->{opts}->{chown} ) {
    chown $meta->{fuid}, $meta->{fgid}, $filename or return $self->_error( "$filename: $!" );
  }
  if ( $self->{opts}->{chmod} ) {
    my $mode = $meta->{mode};
    unless ( $self->{opts}->{same_perms} ) {
      $mode &= ~( oct( 7000 ) | ( umask | 0 ) );
    }
    chmod $mode, $filename or return $self->_error( "$filename: $!" );
  }
  utime $meta->{date}, $meta->{date}, $filename or return $self->_error( "$filename: $!" );
  return 1;
}

sub list_files {
  my $self = shift;
  return wantarray ? @{$self->{names}} : $self->{names};
}

sub _parse {
  my $self = shift;
  my $fpos = 0;
  my $type;
  my $names;
  my $flen = sysseek( $self->{fh}, 0, SEEK_END );
  sysseek( $self->{fh}, 0, SEEK_SET );
  unless ( $self->myread( $fpos, SARMAG ) eq ARMAG ) {
    return $self->_error( "Bad magic number - not an ar archive" );
  }
  $fpos += SARMAG;
  while ( $fpos < $flen ) {
    my ( $name, $date, $uid, $gid, $mode, $size, $magic ) = unpack( 'A16A12A6A6A8A10a2', $self->myread( $fpos, 60 ) );
    $fpos += 60;
    unless ( $magic eq "`\n" ) {
      return $self->_error( "Bad file header" );
    }
    if ( $name =~ m|^/| ) {
      $type = GNU;
      if ( $name eq '//' ) {
        $names = $self->myread( $fpos, $size );
        $fpos += $size + ( $size % 2 );
        next;
      } elsif ( $name eq '/' ) {
        $name = $self->{opts}->{symbols};
        unless ( defined $name && $name ) {
          $fpos += $size + ( $size % 2 );
          next;
        }
      } else {
        $name = substr( $names, int( substr( $name, 1 ) ) );
        $name = substr( $name, 0, index( $name, "\n" ) );
        chop $name;
      }
    } elsif ( $name =~ m|^#1/| ) {
      $type = BSD;
      my $l = int( substr( $name, 3 ) );
      $name = $self->myread( $fpos, $l );
      $fpos += $l;
      $size -= length( $name );
    } else {
      if ( $name =~ m|/$| ) {
        $type ||= GNU;    # only gnu has trailing slashes
        chop $name;
      }
    }
    $uid  = int( $uid );
    $gid  = int( $gid );
    $mode = oct( $mode );
    $self->_add_data( $name, $fpos, $date, $uid, $gid, $mode, $size, undef, undef );
    $fpos += $size + ( $size % 2 );
  }
  $self->{type} = $type || COMMON;
  return scalar @{$self->{names}};
}

sub _add_data {
  my $self     = shift;
  my $filename = shift;
  my $fpos     = shift;
  my $date     = shift;
  my $fuid     = shift;
  my $fgid     = shift;
  my $mode     = shift;
  my $size     = shift;
  my $ofn      = shift;
  my $content  = shift;
  if ( exists( $self->{files}->{$filename} ) ) {
    return $self->_error( "$filename: entry already exists" );
  }
  if ( !defined $date || $date == 0 ) {
    $date = timelocal( localtime() );
  }
  $self->{files}->{$filename} = {
                                 name           => $filename,
                                 date           => $date,
                                 fuid           => defined $fuid ? $fuid : 0,
                                 fgid           => defined $fgid ? $fgid : 0,
                                 mode           => defined $mode ? $mode : 0100644,
                                 size           => defined $size ? $size : 0,
                                 fpos           => $fpos,
                                 original_fname => $ofn,
                                 data           => $content,
                                };
  push @{$self->{names}}, $filename;
  return 1;
}

sub add_files {
  my $self  = shift;
  my $files = ref $_[0] ? shift : \@_;
  my $fpos  = 0;
  my $name;
  unless ( $self->myread( $fpos, SARMAG ) eq ARMAG ) {
    return $self->_error( "Bad magic number - not an ar archive" );
  }
  $fpos += sysseek( $self->{fh}, 0, SEEK_END );
  for my $path ( @$files ) {
    $fpos += 60;
    if ( open my $fd, $path ) {
      my @st = stat $fd or return $self->_error( "$path: $!" );
      local $/ = undef;
      binmode $fd;
      my $content = <$fd>;
      close $fd;
      my $filename  = ( File::Spec->splitpath( $path ) )[2];
      my @analitycs = stat $filename;
      my $uid       = int( @st[4] );
      my $gid       = int( @st[5] );
      my $date      = @st[9];
      my $mode      = @st[2];
      my $size      = @st[7];
      $self->_add_data( $filename, $fpos, $date, $uid, $gid, $mode, $size, $path, undef );
    } else {
      $self->_error( "$path: $!" );
    }
  }
  return scalar @{$self->{names}};
}

sub remove {
  my $self  = shift;
  my $files = ref $_[0] ? shift : \@_;
  my $path  = '/tmp/tmp_del.ar';
  $self->_write_wo_removed( $path, $files );
  $self->clear();
  $self->new( $path );
  return $self;
}

sub _write_wo_removed {
  my $self     = shift;
  my $filename = shift;
  my @files    = ref $_[0] ? shift : \@_;
  my $opts     = {( %{$self->{opts}}, %{shift || {}} )};
  my $type     = $opts->{type} || $self->{type} || COMMON;
  my $name;
  my @body = ( ARMAG );
  my %gnuindex;
  my @filenames = @{$self->{names}};
  my $fpos      = 0;
  my $tmpname   = ( defined $filename ) ? $filename : '/tmp/tmp.ar';
  $fpos += SARMAG;
  my $tmpfn = $self->_get_handle( $tmpname, '>' );
  if ( $type eq GNU ) {
    #
    # construct extended filename index, if needed
    #
    if ( my @longs = grep( length( $_ ) > 15, @filenames ) ) {
      my $ptr = 0;
      for my $long ( @longs ) {
        $gnuindex{$long} = $ptr;
        $ptr += length( $long ) + 2;
      }
      push @body, pack( 'A16A32A10A2', '//', '', $ptr, ARFMAG ), join( "/\n", @longs, '' );
      push @body, "\n" if $ptr % 2;    # padding
    }
  }
  print $tmpfn @body;
  for my $fn ( @filenames ) {
    if ( grep { $_ ne $fn } @files ) {
      @body = ();
      $fpos += 60;
      my $meta = $self->{files}->{$fn};
      my $mode = sprintf( '%o', $meta->{mode} );
      my $size = $meta->{size};
      my $name;
      if ( $type eq GNU ) {
        $fn = '' if defined $opts->{symbols} && $fn eq $opts->{symbols};
        $name = $fn . '/';
      } else {
        $name = $fn;
      }
      if ( length( $name ) <= 16 || $type eq COMMON ) {
        push @body, pack( 'A16A12A6A6A8A10A2', $name, @$meta{qw/date uid gid/}, $mode, $size, ARFMAG );
      } elsif ( $type eq GNU ) {
        push @body, pack( 'A1A15A12A6A6A8A10A2', '/', $gnuindex{$fn}, @$meta{qw/date uid gid/}, $mode, $size, ARFMAG );
      } elsif ( $type eq BSD ) {
        $size += length( $name );
        push @body, pack( 'A3A13A12A6A6A8A10A2', AR_EFMT1, length( $name ), @$meta{qw/date uid gid/}, $mode, $size, ARFMAG ), $name;
      } else {
        return $self->_error( "$type: unexpected ar type" );
      }
      print $tmpfn @body;
      if ( defined $meta->{original_fname} ) {
        if ( open( my $rfn, '<:encoding(UTF-8)', $meta->{original_fname} ) ) {
          while ( my $row = <$rfn> ) {
            chomp $row;
            print $tmpfn $row . "\n";
          }
          close $rfn;
        }
      } else {
        print $tmpfn $self->myread( $fpos, $size );
      }
      $fpos += $size + ( $size % 2 );
      print $tmpfn "\n" if $size % 2;    # padding
    }
  }
  if ( $filename ) {
    my $len      = 0;
    my @filestat = stat $tmpfn;
    $len = $filestat[7];
    close $tmpfn;
    return $len;
  }
}

sub _error {
  my $self = shift;
  my $msg  = shift;
  $self->{error}     = $msg;
  $self->{longerror} = longmess( $msg );
  if ( $self->{opts}->{warn} > 1 ) {
    carp $self->{longerror};
  } elsif ( $self->{opts}->{warn} ) {
    carp $self->{error};
  }
  return 1;
}
