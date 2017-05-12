#$Id: stat.pm,v 1.35 2014/01/06 16:36:48 dankogai Exp dankogai $

package BSD::stat;

use 5.00503;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

use vars qw($VERSION $DEBUG);

$VERSION = sprintf "%d.%02d", q$Revision: 1.35 $ =~ /(\d+)/g;

# In favor of speed, especially when $st_ series variables are exported,
# Exporter is no longer used, though EXPORT variables are still used
# to make the code easier to read. see how $USE_OUR_ST is used

use vars qw(@ISA @EXPORT_OK @EXPORT $USE_OUR_ST);

@ISA = qw(DynaLoader);

@EXPORT_OK = 
    qw( 
	$st_dev $st_ino $st_mode $st_nlink $st_uid $st_gid $st_rdev $st_size 
	$st_atime $st_mtime $st_ctime $st_blksize $st_blocks
	$st_atimensec $st_mtimensec $st_ctimensec $st_flags $st_gen
	);

@EXPORT = 
    qw(
       stat
       lstat
       chflags
       utimes
       lutimes
       UF_SETTABLE
       UF_NODUMP
       UF_IMMUTABLE
       UF_APPEND
       UF_OPAQUE
       UF_NOUNLINK
       SF_SETTABLE
       SF_ARCHIVED
       SF_IMMUTABLE
       SF_APPEND
       SF_NOUNLINK
       );

$USE_OUR_ST = 0;

sub import{
    no strict 'refs';
    my $pkg = shift;
    my $callpkg = caller();
    if (my ($flag) = @_){  # we have an arg
	if ($flag eq ":FIELDS"){
	    # import everything available
	    @_ = (@{"$pkg\::EXPORT"}, @{"$pkg\::EXPORT_OK"});
	    $USE_OUR_ST = 1;
	}else{
	    # just use the supplied list
	}
    }else{ # no arg.  Default @EXPORT used;
		@_ = @{"$pkg\:\:EXPORT"};
	}
    for my $sym (@_) {
        no warnings 'uninitialized';
	$sym =~ s/^([\$\@\%\*\&])//o;
	*{"$callpkg\::$sym"} = 
	    ($1 eq '$') ? \${"$pkg\::$sym"} :
	    ($1 eq '@') ? \@{"$pkg\::$sym"} :
	    ($1 eq '%') ? \%{"$pkg\::$sym"} :
	    ($1 eq '*') ? \*{"$pkg\::$sym"} : \&{"$pkg\::$sym"};
    }
}

bootstrap BSD::stat $VERSION; # make XS available;

# Looks like as of Perl 5.18.1 the stat cache must be filled
# before BSD::stat makes use of it
CORE::lstat(__FILE__);

my $field = {
    dev       =>  0,
    ino       =>  1,
    mode      =>  2,
    nlink     =>  3,
    uid       =>  4,
    gid       =>  5,
    rdev      =>  6,
    size      =>  7,
    atime     =>  8,
    mtime     =>  9,
    ctime     => 10,
    blksize   => 11,
    blocks    => 12,
    atimensec => 13,
    mtimensec => 14,
    ctimensec => 15,
    flags     => 16,
    gen       => 17,
};

# define attribute methods all at once w/o AUTOLOAD

while (my ($method, $index) = each %{$field}){
    no strict 'refs';
    *$method = sub{ $_[0]->[$index] };
}

sub atimespec { $_[0]->[8] + $_[0]->[13] / 1e9 }
sub mtimespec { $_[0]->[9] + $_[0]->[14] / 1e9 }
sub ctimespec { $_[0]->[10] + $_[0]->[15] / 1e9 }

# "my" subroutine which is invisible from other package

my $set_our_st = sub 
{
    no strict 'vars';
    no warnings 'uninitialized';
    ( 
      $st_dev, $st_ino, $st_mode, $st_nlink, $st_uid, $st_gid, $st_rdev, 
      $st_size, $st_atime, $st_mtime, $st_ctime, $st_blksize, $st_blocks,
      $st_atimensec, $st_mtimensec, $st_ctimensec, $st_flags, $st_gen,
      ) = @{$_[0]};
};

sub DESTROY{
    $DEBUG or return;
    carp "Destroying ", __PACKAGE__;
    $DEBUG >= 2 or return;
    eval qq{ require Devel::Peek; } and Devel::Peek::Dump $_[0];
    return;
}

sub stat(;$){
    my $arg = shift || $_;
    my $self = 
	ref \$arg eq 'SCALAR' ? xs_stat($arg) : xs_fstat(fileno($arg), 0);
    defined $self or return;
    $USE_OUR_ST and $set_our_st->($self);
    return wantarray ? @$self : bless $self;
}

sub lstat(;$){
    my $arg = shift || $_;
    my $self =
	ref \$arg eq 'SCALAR' ? xs_lstat($arg) : xs_fstat(fileno($arg), 1);
    defined $self or return;
    $USE_OUR_ST and $set_our_st->($self);
    return wantarray ? @$self : bless $self;
}

# chflag implementation
# see <sys/stat.h>

use constant UF_SETTABLE  => 0x0000ffff;
use constant UF_NODUMP    => 0x00000001;
use constant UF_IMMUTABLE => 0x00000002;
use constant UF_APPEND    => 0x00000004;
use constant UF_OPAQUE    => 0x00000008;
use constant UF_NOUNLINK  => 0x00000010;
use constant SF_SETTABLE  => 0xffff0000;
use constant SF_ARCHIVED  => 0x00010000;
use constant SF_IMMUTABLE => 0x00020000;
use constant SF_APPEND    => 0x00040000;
use constant SF_NOUNLINK  => 0x00100000;

sub chflags{
    my $flags = shift;
    my $count = 0;
    for my $f (@_){
	xs_chflags($f, $flags) == 0 and $count++;
    }
    $count;
}

sub utimes {
    my $atime = shift;
    my $mtime = shift;
    my $count = 0;
    for my $f (@_) {
        (
         ref \$f eq 'SCALAR'
         ? xs_utimes( $atime, $mtime, $f )
         : xs_futimes( $atime, $mtime, fileno($f) )
        ) == 0 and $count++;
    }
    $count;
}

sub lutimes {
    my $atime = shift;
    my $mtime = shift;
    my $count = 0;
    for my $f (@_) {
        xs_lutimes( $atime, $mtime, $f ) == 0 and $count++;
    }
    $count;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

BSD::stat - stat() with BSD 4.4 extentions

=head1 SYNOPSIS

  use BSD::stat;

  # just like CORE::stat

  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
   $atime,$mtime,$ctime,$blksize,$blocks,
   $atimensec,$mtimensec,$ctimensec,$flags,$gen)
    = stat($filename); 

  # BSD::stat now accepts filehandles, too

  open F, "foo";
  my @stat = stat(*F);

  # omit an argument and it will use $_;

  my $_ = "foo";
  my stat = stat;

  # stat($file) then -x _ works like CORE::stat();
  stat("foo") and -x _ and print "foo is executable"

  # but -x $file then stat(_) will not!!!

  # just like File::stat

  $st = stat($file) or die "No $file: $!";
  if ( ($st->mode & 0111) && $st->nlink > 1) ) {
    print "$file is executable with lotsa links\n";
  }

  use BSD::stat qw(:FIELDS);
  stat($file) or die "No $file: $!";
  if ( ($st_mode & 0111) && $st_nlink > 1) ) {
      print "$file is executable with lotsa links\n";
  } 

  # chflags

  chflags(UF_IMMUTABLE, @files)

  # utimes and lutimes

  my $when = 1234567890.987654;
  utimes $when, $when, @files;
  lutimes $when, $when, @links;

=head1 DESCRIPTION

This module's default exports override the core stat() and
lstat() functions, replacing them with versions that contain BSD 4.4
extentions such as file flags.  This module also adds chflags function.

=head2 BSD::stat vs. CORE::stat

When called as array context, C<lstat()> and C<stat()> return an array
like CORE::stat. Here are the meaning of the fields:

  0 dev        device number of filesystem
  1 ino        inode number
  2 mode       file mode  (type and permissions)
  3 nlink      number of (hard) links to the file
  4 uid        numeric user ID of file's owner
  5 gid        numeric group ID of file's owner
  6 rdev       the device identifier (special files only)
  7 size       total size of file, in bytes
  8 atime      last access time in seconds since the epoch
  9 mtime      last modify time in seconds since the epoch
 10 ctime      inode change time (NOT creation time!) in seconds si
 11 blksize    preferred block size for file system I/O
 12 blocks     actual number of blocks allocated
 13 atimensec  nsec of last access
 14 mtimensec  nsec of last data modification
 15 ctimensec  nsec of last file status change
 16 flags      user defined flags for file
 17 gen        file generation number

Like CORE::stat, BSD::stat supports _ filehandle.  It does set "stat
cache" so the following -x _ operators can benefit.  Be careful,
however, that BSD::stat::stat(_) will not work (or cannot be made to
work) because BSD::stat::stat() holds more info than that is stored in
Perl's internal stat cache.

C<atimespec>, C<mtimespec>, C<ctimespec> are available only as methods
that return times in floating point.

  my $st = stat($path);
  printf "%f\n" $st->atimespec; # $st->atime + $st->atimensec / 1e9

=head2 BSD::stat vs File::stat

When called as scalar context, it returns an object whose methods are
named as above, just like File::stat. 

Like File::stat, You may also import all the structure fields directly
nto yournamespace as regular variables using the :FIELDS import tag.
(Note that this still overrides your stat() and lstat() functions.)
Access these fields as variables named with a preceding C<st_> in
front their method names. Thus, C<$stat_obj-E<gt>dev()> corresponds to
$st_dev if you import the fields.

Note:  besides polluting the name space, :FIELDS comes with
performance penalty for setting extra variables.  Unlike File::stat
which always sets $File::stat::st_* (even when not exported),
BSD::stat implements its own import mechanism to prevent performance
loss when $st_* is not needed

=head2 chflags

BSD::stat also adds chflags().  Like CORE::chmod it takes first
argument as flags and any following arguments as filenames.  
for convenience, the followin constants are also set;

  UF_SETTABLE     0x0000ffff  /* mask of owner changeable flags */
  UF_NODUMP       0x00000001  /* do not dump file */
  UF_IMMUTABLE    0x00000002  /* file may not be changed */
  UF_APPEND       0x00000004  /* writes to file may only append */
  UF_OPAQUE       0x00000008  /* directory is opaque wrt. union *
  UF_NOUNLINK     0x00000010  /* file may not be removed or renamed */
  SF_SETTABLE     0xffff0000  /* mask of superuser changeable flags */
  SF_ARCHIVED     0x00010000  /* file is archived */
  SF_IMMUTABLE    0x00020000  /* file may not be changed */
  SF_APPEND       0x00040000  /* writes to file may only append */
  SF_NOUNLINK     0x00100000  /* file may not be removed or renamed */

so that you can go like

  chflags(SF_ARCHIVED|SF_IMMUTABLE, @files);

just like CORE::chmod(), chflags() returns the number of files
successfully changed. when an error occurs, it sets !$ so you can
check what went wrong when you applied only one file.

to unset all flags, simply

  chflags 0, @files;

=head2 utimes and lutimes

C<utimes()> and C<lutimes()) are introduced in version 1.30.

C<utimes()> is identical to C<utime()> except fractional time is accepted.

C<lutimes()> is identical to C<utimes()> except when the path is
symbolic link, in which case it changes the time stamp of the symlink
link instead of the file it links to.

=head1 PERFORMANCE

You can use t/benchmark.pl to test the perfomance.  Here is the result
on my FreeBSD box.

  Benchmark: timing 100000 iterations of BSD::stat, Core::stat,
  File::stat...
  BSD::stat:  3 wallclock secs ( 2.16 usr +  0.95 sys =  3.11 CPU) @
32160.80/s (n=100000)
  Core::stat:  1 wallclock secs ( 1.18 usr +  0.76 sys =  1.94 CPU) @
51612.90/s (n=100000)
  File::stat:  7 wallclock secs ( 6.40 usr +  0.93 sys =  7.33 CPU) @
13646.06/s (n=100000)

Not too bad, huh?

=head1 EXPORT

stat(), lstat(), chflags() and chflags-related constants are exported
as default. $st_* variables are also exported when used with :FIELDS

=head1 BUGS

This is the best approximation of CORE::stat() and File::stat::stat()
that module can go.

In exchange of '_' support, BSD::stat now peeks and pokes too much of
perlguts in terms tat BSD::stat uses such variables as PL_statcache
that does not appear in "perldoc perlapi" and such.

Very BSD specific.  It will not work on any other platform.

=head1 SEE ALSO

L<chflags/2>
L<stat/2>
L<File::stat>
L<perlfunc/-x>
L<perlfunc/stat>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BSD::stat

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BSD-stat>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BSD-stat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BSD-stat>

=item * Search CPAN

L<http://search.cpan.org/dist/BSD-stat/>

=back

=head1 AUTHOR

Dan Kogai E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2001-2012 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
