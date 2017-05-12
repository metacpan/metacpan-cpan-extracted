=head1 NAME

Cache::RamDisk

Sharing of Perl Objects Between Processes on Several RAM Drives

=head1 VERSION

0.1.6

=head1 SYNOPSYS

Application start phase:

   use Cache::RamDisk::Functions;

   cache_install( { 'Base'   => '/tmp/rd',
                    'Size'   => 16,
                    'INodes' => 1024,
                    'SIndex' => { 'fie' => 8,
                                  'foe' => 64,
                                  'fum' => 512 },
                    'ShMem'  => 'RdLk',
                    'Keys'   => { 'fie' => 50,
                                  'foe' => 200,
                                  'fum' => 4000 },
                    'User'   => 'apache',
                    'Group'  => 'apache' } );

Content handler code:

   use MyApp::Fie;

   my $fie = MyApp::Fie->new (12345);
   print $fie->{'some_field'};


Object code:

   package MyApp::Fie;
   use Cache::RamDisk;

   sub new {
      my ($class, $id) = @_;
      my $c = Cache::RamDisk->new ('/tmp/rd', CACHE_LRU);
      my $self = $c->get({'fie' => $id})->{'fie'}->{$id} || do {
         # perform some db logics
         $self = $sth->fetchrow_hashref;
         bless $self, $class;
         $c->put({'fie' => { $id => $self } });
      }
      $self;
   }


Later on in a cgi script:

   use CGI qw(:html);
   use Cache::RamDisk::Functions;
   [...]
   my $s = cache_status ('/tmp/rd');
   [...]
   print "Number of items for 'fie': ".$s->key_stat('fie'), br;


On application shutdown:

   cache_remove ('/tmp/rd');


=head1 DESCRIPTION

I<Note: 'rd' is from now on in this document an abbreviation for 'ramdisk' or 'RAM Disk' or however you prefer
to write or exclaim that herewith specified thing.>

Cache::RamDisk provides multi-process applications with a means of sharing Perl objects between the
processes while trying to avoid the inconveniences inherent to other IPC tools:

1. Message queues are extremely fast, but extremely limited too.

2. Shared memory is perhaps even faster, but it came out for me to be an at least hairy problem
trying to store several references all in one segment.

3. Sockets are reliable, but require a second communication endpoint and yet another server process.

But a file is a file is a file.

The package collects as much ramdisks to a bundle as possible and necessary to hold the required user space,
depending on the respective parameters under which the system's individual kernel had been compiled.
The system user and group who owns the cache can be specified for the whole rd bunch, say cache.


=head2 Cache Types

The package provides three ways of cacheing policy. The desired type can be submitted to the individual
object constructor with one of the following values:

=head3 CACHE_LRU

Forces the accessing object methods to treat the cache under B<L>ast B<R>ecently B<U>sed aspects: an existent
object will be delivered, and the respective index entry moves to the top. Values from the 'Keys' reference
in the latest call to C<install()> define the B<maximum number of objects> for the respective key. If the index
list is full, its last line will be C<pop()>ped and the new entry C<unshift()>ed.

=head3 CACHE_TIMED

All accesses from this object to the cache treat the value for each cache key as B<maximum age in seconds>
that cache objects belonging to the key are allowed to reach. "Stale" objects will not be delivered,
but removed instead. (The decision whether to deliver or remove happens on every C<get()> request. There
may a thread be born some day.)

=head3 CACHE_DEFAULT

A fallback policy by which you may use parts of your cache as a convenient substitute for SysV shared
memory. Values set for the cache keys are ignored - which means that you will have
to invalidate objects on this type of cache "by hand". Indexes are being kept up to date by simple
C<unshift()>s and C<splice()>s. B<Note: the invalidate() method is not part of v0.1.2!>


=head1 REQUIRES

Perl B<5.6.1> on a Linux/ Unix System containing the following binaries:

   chown, mkdir, mke2fs, mount, umount

The package uses these Perl modules available from CPAN:

   IPC::Shareable
   IPC::SysV
   Filesys::Df
   Filesys::Statvfs
   File::stat
   Fcntl
   Symbol
   Class::Struct
   POSIX


=head1 EXPORTS

   CACHE_DEFAULT, CACHE_LRU, CACHE_TIMED

=head1 METHODS

=head2 Class Methods

=head3 Cache::RamDisk->new ( $basepath [, $type [, $shmemkey]])

Creates a new class instance that will act on the cache denoted by C<$basepath>. If no C<$type> has
been requested, C<CACHE_DEFAULT> is assumed. Please note that, although it is possible to access one cache
with several types of instances at the same time, it is not intended to create one instance of
several types. Do not try to perform bitwise operations on C<$type>, as their results will all lead to a
C<CACHE_DEFAULT> cache. Returns undef when called as a class method, or when the 'Base' parameter is
missing. The C<$shmemkey> argument is optional, but it becomes a vital necessity, if you want to access
a cache that has been created with another than the default key. See L<Cache::RamDisk::Functions> for
details.

From this and from what can be read under L<CACHE TYPES> follows: it is up to the programmer's
responsibility how the cache will act. You will always have to have in mind which keys on the cache
you want to be treated like what in one application. If you don't always stick to the same type of
cache for one key, you will most likely mostly never get a predictable result, but see far below.


=head2 Object Methods

All of the following methods return the C<undef> value when called with faulty arguments, unless
no runtime error prevents them from returning at all. ("faulty" means that they return the undef value
also when called as class methods.)

=head3 $c-E<gt>errstr

If an error has ocurred in the current B<instance>, holds the message.

=head3 $c-E<gt>get ( $href )

Get one or more objects from the current cache. The values in C<$href> may be scalars or arrayrefs.
There may obviously be more than one key in the argument hash. Thus C<get()> is a means to retrieve
a bunch of objects at one request. Returns a reference to a hash of hashrefs.

Examples:

   $c->get( { 'fie' => 12345 } )  returns   { 'fie' => { '12345' => $a_reference }}

   $c->get( { 'fie' => [12345, 67890],
              'fum' => 54321 } )
                                  returns   { 'fie' => { '12345' => $a_reference,
                                                         '67890' => $another_reference },
                                              'fum' => { '54321' => $something_blessed } }

If an object could not be found on the cache the respective value will be 0. If a non-existing key
has been submitted, the respective value will be C<undef>. Returns C<undef> and sets C<errstr> if no argument
can be found, or the argument isn't a hashref, or an OS error occurs.


=head3 $c-E<gt>put ( $href )

Puts objects on the cache. The hashref it requires has to look like what C<get()> returns.
How C<put()> behaves depends on which type of cache you chose. Returns 1 on success, or undef else and
sets the by C<errstr> accessible field.
Requests for keys which do not exist on the cache are ignored. Values being no hashrefs are ignored.


=head3 $c-E<gt>invalidate ( $href )

Invalidates cache entries. With CACHE_LRU and CACHE_TIMED instances the C<put()> method will automatically
perform the necessary steps, and mostly you will not need to C<invalidate()> something by hand.
On a CACHE_DEFAULT cache, however, you will have to remove objects from time to time. Awaits a hashref
like C<get()>. Returns 1 on success, else sets C<errstr> and returns C<undef>.


=head1 LOCKING

C<put()> operations lock the whole cache by locking the 'ShMem' segment exclusively. C<invalidate()> and
C<get()> operations apply a shared lock to this segment for every input key, except the moments when they
have to write back eventually changed data. Whenever a C<get()> accesses a key, it locks "its" respective
shmem segment exclusively, because every access alters the index order. This means that put()s
are egoistic, whereas get()s and invalidations try to be fair.


=head1 SOME NOTES

If running under Apache all filehandles will be created by C<&Apache::gensym>, else C<&Symbol::gensym> gets
called.

There is a means of controlling the size of a running cache: it lies in performing a LRU put on a key that
elsewhere in your application is being used as TIMED - because a LRU put trims the number of items to the
limit a key has to obey.

A cache can serve more than one application - as long as they all stick to the same 'ShMem' segment.

Attempts to store anything else than a Perl reference will be ignored.


=head1 KNOWN BUGS

Something seems to go wrong in connection with TIMED gets: getting 10000 objects that have to be
declared stale after 4000 seconds resulted even after just under 1000 seconds in a minimization
of used disk spaces to 51% (!?) each. And I simply cannot figure out why: the respective codeline
looks proper to me.


=head1 TODO

Implement some sort of debug mode?

Signal handling?


=head1 SEE ALSO

L<Cache::RamDisk::Functions.pm3>

=for html <i>html link:</i> <a href="RamDisk/Functions.html">Cache::RamDisk::Functions</a>

=head1 AUTHOR

Martin Haase-Thomas E<lt>L<njarl@punkass.com>E<gt>

=head1 HISTORY

B<0.1.6> Nothing here, see Functions.pm

B<0.1.5> Some smaller changes due to my newly achieved respect for initrd's.

B<0.1.4> added invalidate method, published on thcsoft.de 07/26/02.

B<0.1.3> altered 'SIndex' logics, published on thcsoft.de 07/25/02.

B<0.1.2> rewrote them again, published on thcsoft.de 07/24/02.

B<0.1.1> rewrote object methods to fulfill the locking policy

B<0.1> Jul. 02, first approach, runnable under certain conditions


=cut

##############################################################################

package Cache::RamDisk;

# a cache implementation based on ramdisks.
# all methods return undef in case of an error and leave an error message that can be retrieved
# by $c->errstr

require 5.6.1;
use strict;
use warnings;
no warnings 'untie';        # no idea where all those funny inner references come from when
use Exporter;               # trying to untie from IPC::Shareable

use vars qw(@ISA $VERSION @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(CACHE_DEFAULT CACHE_LRU CACHE_TIMED);
$VERSION = 0.1.6;

sub CACHE_DEFAULT { 0 }
sub CACHE_LRU     { 1 }
sub CACHE_TIMED   { 2 }

use IPC::Shareable qw(:lock);
use Filesys::Df;
use Filesys::Statvfs;
use File::stat;
use Fcntl qw( O_CREAT O_RDONLY O_RDWR );
use Symbol;
use POSIX 'ceil';

# constructor.
# args: Base(path) for the rds, cache type
sub new {
   my $class = shift || return undef;
   return undef if ref $class;
   my $self = {};
   $self->{Err} = 0;
   $self->{Base} = shift || return undef;

   my $type = shift || CACHE_DEFAULT; # == 0
   $type = CACHE_DEFAULT unless ($type == CACHE_LRU || $type == CACHE_TIMED);
   $self->{Type} = $type;

   $self->{ShMem} = shift || 'RdLk';

   bless $self, $class;
   $self;
}

# returns a hashref of hashrefs for each requested item.
# e.g.:
# $cache->get( { 'category' => 1201,
#                'post' => [ 1111 2222 3333 4444 ] })
# returns (assumed all items could be found on the cache):
# { 'category' => { '1201' => blessed ref },
#   'post' => { '1111' => blessed ref,
#               '2222' => blessed ref,
#               ...
#             }
# }
sub get {
   my $self = shift || return undef;
   return undef unless (ref $self || $self->{Err}); # we have to be in a clean state
   $self->{Err} = 0;
   my $what = shift;
   unless ($what || ref($what) ne 'HASH') {
      $self->errstr("Argument has to be a hashref in call to get");
      return undef;
   }

   my $that = {};
   my (%cache, $ctie);
   unless (eval { $ctie = tie %cache, 'IPC::Shareable', $self->{ShMem}, { create => 0, destroy => 0,
                                                                          exclusive => 0, mode => 0666,
                                                                          size => 65536 } } ) {
      $self->errstr($@);
      return undef;
   }

   my ($k, @key, $xtie, $idx, $id, $rd, $rdpath, $hdl, $stats, $item);
   foreach $k (keys %{$what}) {
      $ctie->shlock(LOCK_SH);
      unless (exists $cache{$k}) {
         $that->{$k} = undef;
         next;
      }
      @key = split /:/, $cache{$k}; # [0] = cache value, [1] = items on cache, [2] = ftok, [3] = shmemsize

      undef $xtie if $xtie;
      untie $idx if tied $idx;
      unless (eval { $xtie = tie $idx, 'IPC::Shareable', $key[2], { create => 0, destroy => 0,
                                                                   exclusive => 0, mode => 0666,
                                                                   size => $key[3]*1024 } } ) {
         $self->errstr($@);
         undef $ctie;
         untie %cache;
         return undef;
      }
      $what->{$k} = [ $what->{$k} ] unless ref $what->{$k} eq 'ARRAY'; # try to normalize input
      $that->{$k} = {};
      $xtie->shlock(LOCK_EX);
      foreach $id (@{$what->{$k}}) {
         $idx =~ s/(\d+)\/\/$id\n//s;    # "splice" ...
         $key[1]--;
         unless ($& || $1) {
            $that->{$k}->{$id} = 0;
            next;
         }
         chop ($rdpath = $&);
         $rd = $1;
         $rdpath =~ s/\/\//\/$k\//;
         $rdpath = $self->{Base}.$rdpath;
         $that->{$k}->{$id} = 0 unless eval { $stats = stat $rdpath };

         # this is what makes a cache to be a timed cache:
         if ($self->{Type} == CACHE_TIMED && ($stats->atime < (time()-$key[0]))) {
            unlink $rdpath;
            $that->{$k}->{$id} = 0;
            next;
         }

         $hdl = $self->_gensym;
         sysopen($hdl, $rdpath, O_RDONLY, 0644) ||
                                do { $self->errstr("$rdpath: $!");
                                    $that->{$k}->{$id} = undef;
                                    $ctie->shlock(LOCK_EX);
                                    $cache{$k} = join ":", @key;
                                    $ctie->shunlock;
                                    next;
                                  };
         sysread $hdl, $item, $stats->size;
         close $hdl;

         $idx = "$rd//$id\n".$idx if $item;    # ... and "unshift"
         $key[1]++;
         $that->{$k}->{$id} = ($item ? Storable::thaw($item) : 0);
      }
      $xtie->shunlock;
      undef $xtie;
      untie $idx;

      $ctie->shlock(LOCK_EX);
      $cache{$k} = join ":", @key;
      $ctie->shlock(LOCK_UN);
   }
   undef $ctie;
   untie %cache;
   $that;
}


# requests what get() returns as input. returns 1 on success, else undef.
sub put {
   my $self = shift || return undef;
   return undef if $self->{Err};
   unless (ref $self) {
      $self->errstr("You can't call Cache::RamDisk::put as a class method");
      return undef;
   }
   $self->{Err} = 0;
   my $what = shift;
   unless ($what || ref($what) eq 'HASH') {
      $self->errstr("Argument has to be a hashref in call to put");
      return undef;
   }

   my (%cache, $ctie);
   unless (eval { $ctie = tie %cache, 'IPC::Shareable', $self->{ShMem}, { create => 0, destroy => 0,
                                                                          exclusive => 0, mode => 0666,
                                                                          size => 65536 } } ) {
      $self->errstr($@);
      return undef;
   }

   $ctie->shlock(LOCK_EX);
   my ($k, @key, $xtie, $idx, $id, $rd, $rdpath, $df, $item, $l, $hdl, $iline);
   foreach $k (keys %{$what}) {
      next unless exists($cache{$k});
      @key = split /:/, $cache{$k};  # [0] = cache value, [1] = items on cache, [2] = ftok, [3] = shmemsize

      undef $xtie if defined($xtie);
      untie $idx if tied $idx;
      unless (eval { $xtie = tie $idx, 'IPC::Shareable', $key[2], { create => 0, destroy => 0,
                                                                   exclusive => 0, mode => 0666,
                                                                   size => $key[3]*1024 } } ) {
         $self->errstr($@);
         $ctie->shunlock;
         undef $ctie;
         untie %cache;
         return undef;
      }
      $xtie->shlock(LOCK_EX);
      foreach $id (keys %{$what->{$k}}) {
         next unless ref $what->{$k}->{$id}; # lex Storable
         # the cache truncating loop (when pop'ping has to be done for one overstanding
         if ($self->{Type} == CACHE_LRU) {        # element anyway, why not just pop them all?):
            while ($key[1] >= $key[0]) {
               $idx =~ s/(\d+){1}\/\/\w+?\n$//s;
               $rd = "__".$1."__";
               chop ($rdpath = $&);
               $rdpath =~ s/\/\//\/$k\//;
               $key[1]--;
               $rdpath = $self->{Base}.$rdpath;
               unlink $rdpath;
            }
         }

         $idx ||= "";
         $idx =~ s/(\d+\/\/$id)\n//s if $idx;    # "splice" ...
         $rdpath = $1 || "";

         # remove an existing item (items are stored as a whole on one disk and not broken up, and as we
         # secondly have to stat() an existing item anyway in order to compare the sizes, and after this
         # comparison maybe ++have++ to delete the old item, we just remove it right here):
         if ($rdpath) {
            $rdpath =~ s/\/\//\/$k\//;
            $rdpath = $self->{Base}.$rdpath;
            $key[1]--;
            unlink $rdpath;
         }
         $item = Storable::freeze($what->{$k}->{$id});
         $l = length $item;
         # find a free rd (__DStart__: new in 0.1.5, see Functions.pm)
         for ($rd = $cache{__DStart__}; $rd <= $cache{__Disks__}+$cache{__DStart__}; $rd++) {
            $df = df($self->{Base}.$rd);
            last if ($df->{favail} && ($df->{bavail} >= ceil($l/$cache{__BSize__}))); #/
         }
         if ($rd > $cache{__Disks__}+$cache{__DStart__}) {
            $self->errstr("Cache overflow");
            undef $xtie;
            untie $idx;
            $cache{$k} = join ":", @key;
            $ctie->shunlock;
            undef $ctie;
            untie %cache;
            return undef;
         }

         $iline  = "$rd//$id\n";
         $rdpath = $self->{Base}."$rd/$k/$id";
         $hdl = $self->_gensym;
         sysopen($hdl, $rdpath, O_CREAT | O_RDWR, 0644) || do { $self->errstr("$rdpath: $!");
                                                                undef $xtie;
                                                                untie $idx;
                                                                $cache{$k} = join ":", @key;
                                                                $ctie->shunlock;
                                                                undef $ctie;
                                                                untie %cache;
                                                                return undef;
                                                              };
         syswrite $hdl, $item, $l;
         close $hdl;
         $key[1]++;
         $idx = $iline.$idx;                       # ... and "unshift"
      }
      $cache{$k}  = join ":", @key;
      $xtie->shunlock;
      undef $xtie;
      untie $idx;
   }
   $ctie->shunlock;
   undef $ctie;
   untie %cache;
   1;
}


# also accepts wildcards
sub invalidate {
   my $self = shift || return undef;
   return undef unless (ref $self || $self->{Err});
   $self->{Err} = 0;
   my $what = shift;
   unless ($what || ref($what) eq 'HASH') {
      $self->errstr("Argument has to be a hashref in call to invalidate");
      return undef;
   }

   my (%cache, $ctie);
   unless (eval { $ctie = tie %cache, 'IPC::Shareable', $self->{ShMem}, { create => 0, destroy => 0,
                                                                          exclusive => 0, mode => 0666,
                                                                          size => 65536 } } ) {
      $self->errstr($@);
      return undef;
   }
   $ctie->shlock(LOCK_SH);

   my ($k, @key, $xtie, $idx, $id, $rd, $rdpath);
   foreach $k (keys %{$what}) {
      next unless exists $cache{$k};
      @key = split /:/, $cache{$k}; # [0] = cache value, [1] = items on cache, [2] = ftok, [3] = shmemsize

      undef $xtie if $xtie;
      untie $idx if tied $idx;
      unless (eval { $xtie = tie $idx, 'IPC::Shareable', $key[2], { create => 0, destroy => 0,
                                                                   exclusive => 0, mode => 0666,
                                                                   size => $key[3]*1024 } } ) {
         $self->errstr($@);
         undef $ctie;
         untie %cache;
         return undef;
      }
      $what->{$k} = [ $what->{$k} ] unless ref $what->{$k} eq 'ARRAY'; # try to normalize input
      $xtie->shlock(LOCK_EX);
      foreach $id (@{$what->{$k}}) {
         $idx =~ s/\d+\/\/$id\n//s;    # "splice" ...
         next unless ($rdpath = $&);
         chop $rdpath;
         $rdpath =~ s/\/\//\/$k\//;
         $rdpath = $self->{Base}.$rdpath;
         eval { unlink $rdpath };   # suppress eventual error message if the file doesn't exist.
         $key[1]--;                 # ... and don't unshift :)
      }
      $xtie->shunlock;
      undef $xtie;
      untie $idx;

      $ctie->shlock(LOCK_EX);
      $cache{$k} = join ":", @key;
      $ctie->shlock(LOCK_UN | LOCK_SH);
   }
   $ctie->shunlock;
   undef $ctie;
   untie %cache;
   1;
}


# gets the current error message
sub errstr {
   my $self = shift || return undef;
   return undef unless ref $self;
   return 0 unless $self->{Err};
   my @caller = caller;
   $self->{Err}." at $caller[1] line $caller[2]";
}


####################################
# internal subs

# call the appropriate gensym function
# args: none,
# returns: globref
sub _gensym {
   my $self = shift || return undef;
   $ENV{MOD_PERL} ? &Apache::gensym : &Symbol::gensym;
}


1;
