package App::Manager;

use strict 'subs';
use Carp;
use subs qw(LIBTRACER_SO LIBDIR S_ISLNK S_ISREG S_ISDIR S_IFMT);

require Exporter;
require DynaLoader;

use IO::Socket::UNIX;
use File::Spec 0.7;
use File::Basename;
use Cwd;
use Fcntl;
use POSIX qw(EAGAIN);

BEGIN {
   $^W=0; # I'm fed up with bogus and unnecessary warnings nobody can turn off.

   @ISA = qw(Exporter DynaLoader);

   @EXPORT = qw(trace_program);
   @EXPORT_OK = (@EXPORT,qw(slog S_ISLNK S_ISREG S_ISDIR S_IFMT));
   $VERSION = '0.03';
}

bootstrap App::Manager $VERSION;

$verbose=0;

$unix_path = (eval { File::Spec->tmpdir } || "/tmp")."/installtracer_socket$$~";

sub slog($@) {
   (print STDERR "APPMAN: ",@_,"\n") if $verbose => shift;
}

my $sizeof_int = length pack "i",0;

my $unix;	# unix listening socket
my $fh;		# the filehandle
my $change_cb;	# call before every change

sub xread($) {
   my $len=shift;
   my $buff;
   while ($len) {
      my $read = sysread $fh,$buff,$len,length($buff);
      redo if !$read && $! == EAGAIN;
      $read>0 or die "\n";
      $len -= $read;
   }
   $buff;
}

sub get_char() { xread 1 }
sub get_int() { unpack "i", xread $sizeof_int }
sub get_str() { xread get_int }

# read cwd, pathname and canonicalize it
sub get_abspath() {
   my $path = File::Spec->catdir(get_str,get_str);
   my($base,$dir)=fileparse($path);
   
   $abspath{$dir} = Cwd::abs_path($dir) unless defined $abspath{$dir};
   File::Spec->canonpath("$abspath{$dir}/$base$suffix");
}

sub handle_msg {
   my $type = get_char;

   if ($type eq "S") {
      syswrite $fh,"s",1;
   } elsif ($type eq "C") {
      $change_cb->(get_abspath);
   } elsif ($type eq "I") {
      my $pid = get_int;
      # process $pid just connected.. fine
   } else {
      die "illegal message received: MSG $type, pid $pid\n";
   }
   1;
}

END { unlink $unix_path }

sub init_tracer() {
   $unix = new IO::Socket::UNIX Local => $unix_path, Listen => 1;
   $unix or die "Unable to create unix domain socket '$unix_path' for listening: $!\n";

   -x LIBTRACER_SO
      or die "FATAL: tracer helper object '".LIBTRACER_SO."' not executable!\n";
}

sub stop_tracer() {
   unlink $unix_path; undef $unix_path;
}

sub run_tracer() {
   my($rm,$r,$handles);

   vec($rm,fileno($unix),1)=1;

   while(!$server_quit) {
      if(select($r=$rm,undef,undef,undef)>0) {
         if ($unix && vec($r,fileno($unix),1)) {
            $fh = $unix->accept;
            $handles{fileno $fh} = $fh;
            vec($rm,fileno($fh),1)=1;
         }
         for $f (keys(%handles)) {
            if(vec($r,$f,1)) {
               $fh=$handles{$f};
               if(!eval { handle_msg }) {
                  vec($rm,$f,1)=0;
                  delete $handles{$f};
                  undef $fh;
                  die $@ if $@ && $@ ne "\n";
               }
            }
         }
      }
   }
}

# launch a single program and update %before hashes.
sub trace_program($@) {
   $change_cb = shift;
   
   init_tracer;
   
   $server_quit = 0;
   local $SIG{CHLD} = sub { $server_quit = 1 };

   if (fork == 0) {
      $ENV{LD_PRELOAD}=join(":",LIBTRACER_SO,split /:/,$ENV{LD_PRELOAD});
      $ENV{INSTALLTRACER_SOCKET}=$unix_path;
      exec @_;
      die "Unable to exec @_: $!\n";
   }

   local $SIG{PIPE} = 'IGNORE';
   local $SIG{QUIT} = 'IGNORE';
   local $SIG{INT}  = 'IGNORE';
   local $SIG{HUP}  = 'IGNORE';

   run_tracer;
   stop_tracer;
}

package App::Manager::DB;

use Storable qw(nstore retrieve);
use File::Copy;
use App::Manager qw(S_ISDIR S_ISLNK S_ISREG S_IFMT slog);
use File::Compare;

sub new {
   my $self = bless {},shift;
   $self->{path} = shift;
   $self;
}

sub sync {
   my $self=shift;
   if ($self->{dirty}) {
      my @unlink = @{delete $self->{unlink}};
      $self->{dirty}=0;
      nstore $self,$self->{path}."/db"
         or die "Unable to freeze into $self->{path}/db: $!\n";
      unlink @unlink;
   }
}

sub dirty {
   my $self=shift;
   $self->{mtime}=time;
   $self->{dirty}++;
}

sub DESTROY {
   my $self=shift;
   $self->sync;
}

sub open {
   shift;
   my $path=App::Manager::LIBDIR."/".shift;
   slog 1,"opening db $path";
   retrieve $path."/db";
}

sub creat {
   my $self = bless {}, shift;
   $self->{path} = App::Manager::LIBDIR."/".shift;
   slog 1,"creating db $self->{path}";
   system 'rm','-rf',$self->{path};
   mkdir $self->{path},0777
      or die "Unable to create database '$self->{path}': $!\n";
   $self->{genfile} = 'Xaaaaaa';
   $self->{ctime} = time; # now this really is the _creation_ time
   $self->{version}=$VERSION;
   $self->dirty;
   $self;
}

sub xlstat($) {
   my @stat = lstat $_[0];
   @stat ?
      {
         path		=> $_[0],
         dev		=> $stat[ 0],
         ino		=> $stat[ 1],
         mode		=> $stat[ 2],
         nlink		=> $stat[ 3],
         uid		=> $stat[ 4],
         gid		=> $stat[ 5],
         rdev		=> $stat[ 6],
         size		=> $stat[ 7],
         atime		=> $stat[ 8],
         mtime		=> $stat[ 9],
         ctime		=> $stat[10],
         blksize	=> $stat[11],
         blocks		=> $stat[12],
      }
   :
      {
         path	=> $_[0],
      }
}

sub ci($$) {
   my $self=shift;
   my $stat=xlstat shift;
   my $gen = $self->{genfile}++;

   $stat->{id} = $gen;

   $self->{storage}{$gen}=
   $self->{source}{$stat->{path}}=$stat;

   if (defined $stat->{mode}) {
      if (S_ISREG $stat->{mode}) {
         $stat->{savetype} = 1; # none, stored
         $stat->{savepath} = $self->{path}."/".$gen;
         copy $stat->{path},$stat->{savepath}
            or die "Unable to save away file '$stat->{path}': $!\n";
      } elsif (App::Manager::S_ISLNK $stat->{mode}) {
         $stat->{symlink}=readlink $stat->{path}
            or die "Unable to read symlink '$stat->{path}': $!\n";
      } elsif (App::Manager::S_ISDIR $stat->{mode}) {
         # nothing to do
      } else {
         die "FATAL: Don't know how to check in $stat->{path}.\n";
      }
   }
   $self->dirty;
}

sub optimize($$) {
   my $self=shift;
   my $level=shift;
   slog 1,"checking for differences between database and filesystem";
   for my $stat (values (%{$self->{storage}})) {
      my $msg;
      my $nstat = xlstat $stat->{path};
      if (defined $stat->{mode} || defined $nstat->{mode}) {
         if (($stat->{mode} ^ $nstat->{mode}) & App::Manager::S_IFMT
             || defined $stat->{mode} ^ defined $nstat->{mode}) {
            $msg = "type changed";
         } else {
            my $samecontent;
            $msg = "content changed";
            if (S_ISREG $stat->{mode}) {
               $samecontent = !compare ($stat->{path}, $stat->{savepath});
               if ($samecontent) {
                  unlink delete $stat->{savepath};
                  $stat->{savetype} = 0;
               }
            } elsif (S_ISDIR $stat->{mode}) {
               $samecontent = 1;
            } elsif (S_ISLNK $stat->{mode}) {
               $samecontent = $stat->{symlink} eq readlink $stat->{path};
            }
            $msg = "attributes changed" if $samecontent;
            if ($samecontent
                && $stat->{uid} eq $nstat->{uid}
                && $stat->{gid} eq $nstat->{gid}
                && $stat->{size} eq $nstat->{size}
                && ($level > 0 || $stat->{mtime} eq $nstat->{mtime})) {
               $msg = "no change";
               delete $self->{storage}{$stat->{id}};
               delete $self->{source}{$stat->{path}};
            }
         }
         slog 3,"$stat->{path}: $msg";
         $stat->{ctype} = $msg;
      } else {
         delete $self->{storage}{$stat->{id}};
         delete $self->{source}{$stat->{path}};
      }
   }
   $self->dirty;
}

sub storage {
   my $self=shift;
   $self->{storage};
}

sub remove($) {
   my $path=shift;
   lstat $path;
   if (-e _) {
      if (-d _) {
         rmdir $path
            or warn "WARNING: Unable to remove existing directory '$path': $!\n";
      } else {
         unlink $path
            or die "Unable to remove existing object '$path': $!\n";
      }
   }
}

sub recreate($) {
   my $stat = shift;
   if (defined $stat->{mode}) {
      if (S_ISREG $stat->{mode}) {
         if (exists $stat->{savepath}) {
            remove $stat->{path};
            $stat->{savetype} == 1
               or die "Unknown savetype for file\n";
            copy $stat->{savepath},$stat->{path}
               or die "Unable to recreate file '$stat->{path}': $!\n";
         }
      } elsif (S_ISLNK $stat->{mode}) {
         remove $stat->{path};
         symlink $stat->{symlink},$stat->{path}
            or die "Unable to recreate symbolic link '$stat->{path}' => '$stat->{symlink}': $!\n";
      } elsif (S_ISDIR $stat->{mode}) {
         remove $stat->{path};
         mkdir $stat->{path},$stat->{mode} & 07777
            or die "Unable to recreate directory '$stat->{path}': $!\n";
      } else {
         die "FATAL: don't know how to check in $stat->{path}.\n";
      }
      unless (S_ISLNK $stat->{mode}) {
         chmod $stat->{mode} & 07777,$stat->{path}
            or die "Unable to change mode for '$stat->{path}': $!\n";
         chown $stat->{uid},$stat->{gid},$stat->{path}
            or warn "Unable to change user and group id for '$stat->{path}': $!\n";
         utime $stat->{atime},$stat->{mtime},$stat->{path}
            or warn "Unable to change atime and mtime for '$stat->{path}': $!\n";
      }
   }
}

# this is safe as long as we don't sync too early
sub swap {
   my $self=shift;
   slog 1,"swapping all changes";
   for my $stat (reverse sort values %{$self->{storage}}) {
      slog 2,"swapping $stat->{path}";
      # saving old version
      $self->ci($stat->{path});
      recreate $stat;
      push @{$self->{unlink}},$stat->{savepath} if exists $stat->{savepath};
      delete $self->{storage}{$stat->{id}};
   }
   slog 2,"syncing database";
   $self->dirty;
   $self->sync;
   slog 2,"optimizing database";
   $App::Manager::verbose=0;
   local $App::Manager::verbose=0;
   $self->optimize(0);
}

1;

__END__

=head1 NAME

App::Manager - Perl module for installing, managing and uninstalling software packages.

=head1 SYNOPSIS

  use App::Manager; # use appman instead

=head1 DESCRIPTION

Oh well ;) Not written yet! The manager program (appman) has documented commandlien switches, though.

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>.

=head1 SEE ALSO

perl(1).

=cut

