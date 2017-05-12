=head1 TITLE: Cache::RamDisk::Functions

Script-like things for installing and monitoring a Cache::RamDisk

=head1 SYNOPSIS

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


   cache_status ('/tmp/rd');

   cache_remove ('/tmp/rd');


=head1 VERSION

0.1.6

=head1 EXPORTS

   cache_install
   cache_status
   cache_remove
   cache_objects


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


=head1 DESCRIPTION

The package provides programmers with functions for creating, monitoring and removing a cache based on a
bundle of ramdisks.

=head2 cache_install ( $href )

Initialize the rd bundle. What will actually happen when you call this method depends on how the system
kernel had been compiled. Please refer to the manpages about lilo.conf, lsmod etc. for some
further details about manipulating the standard rd size on your box. All rds will be formatted with
standard e2fs and under the default blocksize parameter.
Of course the calling process has to have root privileges.

C<cache_install()> does not terminate the calling process after an error has occurred, but emits a warning and
returns a somehow valuable result! After successful execution the function calls C<cache_status()> on the freshly
installed cache and passes the return value to the caller.

From version 0.1.5 on C<cache_install> tries to find out whether there an C<initrd> has been installed. The most effective - but
nevertheless hack-like - way to me was to grep in C</proc/mounts>. If an entry named 'initrd' can be found, the first rd it tries to install
will be on /dev/ram1, assuming that /dev/ram0 is occupied in some way...


=head3 Arguments

Of course all argument names are case sensitive.

=head4 Base

'Base' is an optional argument defaulting to '/tmp/rd'. Please note that the argument will not be treated
as a pathname, but as the beginning of it. With the default value the rds will be called '/tmp/rd0', '/tmp/rd1', ...
From version 0.1.5 on can be stated that an initrd being found on '/tmp/rd0' will be respected.

=head4 Size

The B<minimum> user space in B<MB> to be installed. "Minimum" results from the root space that ext2 reserves on
each disk. The creating loop stops when there are more blocks available than necessary for the requested
value. This will in effect lead to an available space of ca. 19 MB when you want just 16 - but there aren't
many of such opportunities in life, so don't complain.. 'Size' is an optional argument that defaults to 16.

=head4 SIndex

Each key's index will be stored on a shared memory segment of the key's 'SIndex' Size in B<kB>.
This is an optional value with a default of 128 for each key. An index element will have the length
of the item's id plus 4 bytes (or 5 if there are more than 10 rds keeping the data). In order to speed
up performance the indexes are stored as strings and parsed by regexes, which I expect to act somewhat
faster than painful C<for> loops over arrays.

Although the installation doesn't care about how the cache will be used, setting the 'SIndex' values
predefines its policies: when you know that you will always treat a key under LRU aspects with a rather
low amount of items to be stored (e.g. C<{'fie' => 50}>), the index will probably be no longer than 2 kB.
On the other hand storing sessions with keys of 32 bytes of size each and lifetimes of one hour may lead to
an index that doesn't fit into 128 kB.


=head4 ShMem

All data the install function has gathered so far are static data for a running cache. They consist of

=over4

=item *

the total rds allocated,

=item *

their common blocksize,

=item *

the cache keys and their limiting values and keys under which the indexes can be accessed on the shared
memory.

=back

They all have to be stored somewhere, hence another shmem segment came out to be the appropriate place.
The value 'ShMem' awaits is the key, under which this segment will be reachable. Please see L<IPC::Shareable.pm3>
for details on what this value is allowed to be.

The existence of this argument may look weird to some people, as the shmem key could easily be calculated
through C<ftok()> from one of the freshly created directories as well.
But implementing it enables your cache to serve more than just one
application at the same time - as long as they all stick to the same cache control segment.

'ShMem' is an optional argument with a default of 'RdLk'. You will always be advised well when you leave
it untouched - unless there is another application running on your server which you can't persuade of
using another key. Because if another key than the default is used, it has to passed to every
C<Cache::RamDisk> constructor. ;)

=head4 INodes

The number of inodes to be reserved for the filesystem on each disk, see L<mke2fs(8)>. This optional
parameter defaults to 1024. Both the number of inodes and that of the available blocks determine how the
disks' capacities will be used by the cache: when you know that most of the objects to be stored will have
a rather small size (around 1k) it can make sense to double the value, as else only about 50% of the
disk spaces may be occupied. But mostly the default should suffice. Please note that as for the current
version it is not intended to let programmers alter the blocksize on the rds. But this may change, and
any comments being able to change my mind about this item will be appreciated.

=head4 Keys

'Keys' is the only mandatory argument, as a cache without a cache key wouldn't make a sense. 'Keys' awaits
a hashref, where the keys are the cache's keys, and the values limitate each individual Cache::RamDisk
instance's behaviour: for a TIMED instance a value means an item's maximum lifetime in seconds, a LRU
instance treats a cache key's value as maximum number of items allowed. Per DEFAULT the cache is ignorant.

=head4 User/ Group

The system user and group allowed to access the cache. Values have to be real names and not numeric ids.
Both arguments are optional and default to 'root'.


=head3 What happened?

   cd /tmp/rd0 && ls -la
   ipcs


=head2 cache_status ( $basename [, $shmemkey] )

   my $s = cache_status('/tmp/rd');
   print $s->key_stat('fie');
   print $s->rd_stat(0)->{bavail};

The monitoring tool for a running cache. Requires the cache's base pathname (-fragment, see cache_install), and
the 'ShMem' key for this cache, if another than the default value 'RdLk' had been chosen.
Always (!) returns a Class::Struct reference with the following accessible members:

   $s->error                  # contains the error message in case something went wrong
   $s->start_disk             # the index of the first rd allocated
   $s->disks                  # the total of allocated disks
   $s->blocksize              # guess what
   $s->keys                   # a key's limit, as set in 'Keys'
   $s->key_stat               # the number of items currently being stored for a key
   $s->rd_stat                # the resulting hashref from a df() call on a rd


=head2 cache_objects ( $basename [, $shmemkey] )

Monitoring tool #2: get lists of all cached objects. (new in 0.1.6) Returns a hashref keyed to object types. For each object
type the value is another hashref, keyed to the rds' numbers and containing arrayrefs with the object ids as values. E.g.:

   { 'User' => { '1' => [ 2, 5, 67, 8999 ],
                 '2' => [ 1, 3, 4, 66 ] 
               },
     'Foo'  => { '1' => [ 'fie', 'fee', 'fum' ],
                 '2' => [ 'blah', 'bar', 'baz' ]
               }
   }              

=head2 cache_remove ( $basename [, $shmemkey] )

Completely clears all devices (by unmounting them) and removes all relevant shared memory segments.
Awaits the same arguments as cache_status. Returns 1 on success, else emits a warning and returns 0.


=head1 NOTES

As both key and internal information are stored on the 'ShMem' segment, they have to be distinguishable
from another: internal keys all begin and end with each a double underscore. From this follows that input
keys matching the pattern C</^__.*__$/> are ignored by C<cache_install>.

The same applies to key names containing any Perl non-word chars (C</\W/>).

=head1 SEE ALSO

L<Cache::RamDisk.pm3>, L<Filesys::Df.pm3>, L<mke2fs(8)>, L<initrd(4)>, L<Class::Struct.pm3>, L<IPC::Shareable.pm3>


=head1 AUTHOR

Martin Haase-Thomas E<lt>thcsoft@snafu.deE<gt>

=head1 HISTORY

B<0.1.6>   (08/04/03) Fixed some samll bugs, added C<cache_objects> method.

B<0.1.5>   Some smaller changes due to my newly achieved respect for initrd's.

B<0.1.4>   Nothing serious. Just beautified the docs a little.

B<0.1.3>   Implemented 'SIndex' as hashref for assigning shmem sizes to the keys directly.

B<0.1.2>   dropped the idea of keeping any internal data on the rds and added 'SIndex' arg, rewrote locking
again. Added cache_remove.

B<0.1.1>   rewrote locking concept and cache_install, wrote cache_status. Stress tests showed an
extremely lame performance.

B<0.1>   Jul. 02, cache_install ok, but cache unuseable: locking unclear


=head1 TODO

What about that funny blocksize story?



=cut

##############################################################################

package Cache::RamDisk::Functions;

use strict;
use warnings;
no warnings 'untie';
use vars qw($VERSION @ISA @EXPORT);
$VERSION = 0.1.6;
@ISA = qw(Exporter);
@EXPORT = qw(cache_install cache_status cache_objects cache_remove);

use IPC::SysV 'ftok';
use IPC::Shareable qw(:lock);
use Filesys::Df;
use Filesys::Statvfs;
use File::stat;
use Symbol 'gensym';
use Class::Struct;

sub cache_install {
   if ($<) {
      warn "You must be root to install a cache";
      return {}; # a somehow useable value...
   }
   my $args = shift || return 0;
   my ($i, $rdpath, $hdl, $ret, @stat);
   $args->{'Base'}  = '/tmp/rd' unless $args->{'Base'};
   $args->{'Size'}  = 16 unless $args->{'Size'};
   $args->{'INodes'}= 1024 unless $args->{'INodes'};
   $args->{'ShMem'} = 'RdLk' unless $args->{'ShMem'};
   $args->{'User'}  = 'root' unless $args->{'User'};
   $args->{'Group'} = 'root' unless $args->{'Group'};
   unless ($args->{'Keys'}) {
      warn "A cache like me needs a key";
      return {};
   }
   $args->{'SIndex'} = {} unless $args->{'SIndex'};

   my @keys;
   foreach (keys %{$args->{'Keys'}}) {
      unless(/\W/ or /^__.*__$/) {
         push @keys, $_;
         $args->{'SIndex'}->{$_} = 128 unless $args->{'SIndex'}->{$_};
      }

   }
   $ret = { 'Disks' => 0, 'DStart' => 0, 'Blocks' => 0, 'BSize' => 1024  };

   # new in 0.1.5: respect an eventual initrd.
   # to me this looks like an ugly hack...
   $hdl = gensym;
   open $hdl, '/proc/mounts' || do { warn "Oops! Is this a linux box? Can't open /proc/mounts: $!";
                                     return $ret;
                                   };
   @stat = (<$hdl>);
   close $hdl;
   $ret->{'DStart'} = 1 if (grep 'initrd', @stat);

   print STDERR "\n"; # some scripts don't make a nice display... ;)
   for ($i=$ret->{'DStart'};;$i++) {

      $rdpath = $args->{'Base'}.$i;
      $hdl = gensym;
      open $hdl, '/etc/mtab' ||  do { warn "Can't open /etc/mtab: $!";
                                     return $ret;
                                    };
      my @mount = (<$hdl>);
      close $hdl;
      if (grep(/$rdpath/, @mount) && system("umount ".$rdpath) < 0) {
         warn "Can't unmount $rdpath: $!";
         return $ret;
      }
      if (-e "/dev/ram$i") {
        if (system("mke2fs -q -N".$args->{'INodes'}." /dev/ram$i") < 0 ||
             system("mkdir -p $rdpath") < 0 ||
             system("mount /dev/ram$i $rdpath")) {
            warn "Error while creating /dev/ram$i on $rdpath: $!";
            return $ret;
         }
         $ret->{'BSize'} = (statvfs $rdpath)[0] unless $i;

         # chowning must not affect a 'lost+found' directory, that's why it's not done recursively
         # for the whole of each disk, but lets the '.' directory belong to root
         foreach (@keys) {
            unless (mkdir "$rdpath/$_") {
               warn "Error while creating directories on $rdpath: $!";
               return $ret;
            }
            if (system("chown -R ".$args->{'User'}.".".$args->{'Group'}." $rdpath/$_") < 0) {
               warn "Unable to change ownership of $rdpath/$_: $!";
               return $ret;
            }
         }
         @stat = statvfs($rdpath);      # df doesn't return the blocksize ?!
         $ret->{'Blocks'} += $stat[4];
         $ret->{$i} = $stat[0];
         $ret->{'Disks'} = $i;
         last if $ret->{'Blocks'} > $args->{'Size'}*$ret->{'BSize'};

      }
      else {
         warn "Not enough devices for ".$args->{'Size'}."MB -  run 'man MAKEDEV'";
         return $ret;
      }
   }

   # write static data to the control segment:
   # 1. get the shmem keys
   my @ftoks;
   for ($i = 0; $i < @keys; $i++) {
      $ftoks[$i] = ftok($args->{'Base'}.$ret->{'DStart'}."/$keys[$i]", 0);
   }

   my (%cache, $stie);
   unless (eval { $stie = tie %cache, 'IPC::Shareable', $args->{'ShMem'}, { create => 1, mode => 0666,
                                                                            size => 65536, exclusive => 0,
                                                                            destroy => 0 } } ) {
      warn $@;
      return $ret;
   }
   $stie->shlock;
   $cache{__Disks__}  = $ret->{'Disks'};
   $cache{__BSize__}  = $ret->{'BSize'};
   $cache{__DStart__} = $ret->{'DStart'};

   for ($i = 0; $i < @keys; $i++) {
      $cache{$keys[$i]} = $args->{'Keys'}->{$keys[$i]}.":0:$ftoks[$i]:".$args->{'SIndex'}->{$keys[$i]};
   }
#                              foreach (keys %cache) { print STDERR "$_=".$cache{$_}."\n";}
   $stie->shunlock;
   undef $stie;
   untie %cache;
   # finally create the shmem segments and prefill them
   for ($i = 0; $i < @keys; $i++) {
      my $baz = "";
      unless (eval { $stie = tie $baz, 'IPC::Shareable', $ftoks[$i], { create => 1, mode => 0666,
                                                                       size => $args->{'SIndex'}->{$keys[$i]}*1024,
                                                                       exclusive => 0, destroy => 0 } } ) {
         warn $@;
         return $ret;
      }
      $stie->shlock;
      $baz = "";
      $stie->shunlock;
      undef $stie;
      untie $baz;
   }

   cache_status ($args->{'Base'}, $args->{'ShMem'});
}

# monitoring tool
sub cache_status {
   struct ( c_status => { disks     => '$',
                          blocksize  => '$',
                          keys       => '*%',
                          rd_stat    => '*%',
                          key_stat   => '*%',
                          error      => '$',
                          start_disk => '$'
                        } ) unless defined &c_status::new;
   my $stat = new c_status (disks => 0, blocksize => 1024, error => 0);
   my $rdpath = shift || do {
                              $stat->error("Argument missing");
                              return $stat;
                            };
   my (%cache, $tie);
   my $shkey = shift || 'RdLk';
   unless (eval { $tie = tie %cache, 'IPC::Shareable', $shkey, { create => 0, destroy => 0,
                                                                 exclusive => 0, mode => 0666,
                                                                 size => 65536 } } ) {
      $stat->error($@);
      return $stat;
   }

   $tie->shlock(LOCK_SH);

   # 1. general:
   $stat->disks($cache{__Disks__});
   $stat->blocksize($cache{__BSize__});
   $stat->start_disk($cache{__DStart__}); # new in 0.1.5

   # 2. key infos:
   my @key;
   foreach (keys %cache) {
      unless (/^__.*__/) {
         @key = split /:/, $cache{$_};
         $stat->keys($_, $key[0]);
         $stat->key_stat($_, $key[1]);
      }
   }
   $tie->shunlock;

   # 3. disk infos:
   for (my $i = $stat->start_disk; $i < $stat->disks+$stat->start_disk; $i++) {
      $stat->rd_stat($i, df($rdpath.$i));
   }

   undef $tie;
   untie %cache;

   $stat;
}

# new in 0.1.6: monitoring tool, pt.2:
sub cache_objects {
   my $rdpath = shift || die "Argument missing!";
   my (%cache, $tie);
   my $shkey = shift || 'RdLk';
   die $@ unless (eval { $tie = tie %cache, 'IPC::Shareable', $shkey, { create => 0, destroy => 0,
                                                                        exclusive => 0, mode => 0666,
                                                                        size => 65536 } } );
   my $res = {};
   my (@key, $idx, $xtie, $obj, @tidx, $ikey, $rd, $id);
   foreach $ikey (keys %cache) { 
      @key = split /:/, $cache{$ikey}; # [0] = cache value, [1] = items on cache, [2] = ftok, [3] = shmemsize
      unless (eval { $xtie = tie $idx, 'IPC::Shareable', $key[2], { create => 0, destroy => 0,
                                                                   exclusive => 0, mode => 0666,
                                                                   size => $key[3]*1024 } } ) {
         undef $tie;
         untie %cache;
         die $@;
      }
      unless ($ikey =~ /^__\w+__$/) {
         $obj = {};
         @tidx = split /\n/, $idx;
         foreach (@tidx) {
            ($rd, $id) = split /\/\//;
            $obj->{$rd} = [] unless defined $obj->{$rd};
            push @{$obj->{$rd}}, $id;
         }
         $res->{$ikey} = $obj; 
      }
      undef $xtie;
      untie $idx;
   }

   undef $tie;
   untie %cache;
   $res;
}

# remove all system resources related to a cache.
sub cache_remove {
   if ($<) {
      warn "You must be root to remove a cache";
      return 0;
   }

   my $rdpath = shift || do {
                              warn "Argument missing";
                              return 0;
                            };
   my (%cache, $tie);
   my $shkey = shift || 'RdLk';
   unless (eval { $tie = tie %cache, 'IPC::Shareable', $shkey, { create => 0, destroy => 0,
                                                                 exclusive => 0, mode => 0666,
                                                                 size => 65536 } } ) {
      warn $@;
      return 0;
   }
   $tie->shlock(LOCK_EX);

   for (my $rd = $cache{__DStart__}; $rd < $cache{__Disks__}+$cache{__DStart__}; $rd++) {
      system "umount $rdpath".$rd;
   }

   foreach (keys %cache) {
      next if /^__.*__$/;
      my (@key, $ttie, $idx);
      @key = split /:/, $cache{$_};
      unless (eval { $ttie = tie $idx, 'IPC::Shareable', $key[2], { create => 0, destroy => 0,
                                                                    exclusive => 0, mode => 0666,
                                                                    size => $key[3]*1024 } } ) {
         warn $@;
         return 0;
      }
      $ttie->remove;
   }
   $tie->remove;
   1;
}

1;
