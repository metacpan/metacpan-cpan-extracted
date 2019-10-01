package App::GitFind::FileStatLs;

# Perl standard modules
use strict;
use warnings;
use Carp;
use Fcntl ':mode';
use POSIX qw(strftime);


require 5.006;
our $VERSION = '0.000002';

use parent 'Exporter';
our @EXPORT      = qw(ls_stat format_mode);
our @EXPORT_OK   = qw(stat_attr);
our %EXPORT_TAGS = ( all  => [@EXPORT, @EXPORT_OK] );

=head1 NAME

App::GitFind::FileStatLs - Provide stat information in ls -l format

=head1 SYNOPSIS

B<NOTICE:> This is a copy of L<File::Stat::Ls> with modifications, as found at
L<https://github.com/cxw42/File-Stat-Ls>.

  use App::GitFind::FileStatLs;

  my $obj = App::GitFind::FileStatLs->new;
  my $ls = $obj->ls_stat('/my/file/name.txt');
    # E.g., " -r-xr-xr-x 1 root other 4523 Jul 12 09:49 /my/file/name.txt"

=head1 MODIFICATIONS

In L</ls_stat ($fn)>:

=over

=item *

Never take a class parameter, i.e., cannot be called as
C<< App::GitFind::FileStatLs->ls_stat >> or
C<< App::GitFind::FileStatLs->new->ls_stat >>.

=item *

Do not call C<lstat> a second time.

=item *

Change output format

=back

General:

=over

=item *

Update documentation

=item *

Lazily load L<Carp>

=back

=head1 DESCRIPTION

This class contains methods to convert stat elements into ls format.
It exports two methods: C<format_mode> and C<ls_stat>.
The C<format_mode> is borrowed from L<Stat::lsMode> class by
Mark Jason Dominus. The C<ls_stat> will build a string formatted as
the output of 'ls -l'.

=cut

=head2 new ()

Input variables:

  None

Variables used or routines called:

  None

How to use:

   my $obj = new App::GitFind::FileStatLs;      # or
   my $obj = App::GitFind::FileStatLs->new;     # or

Return: new empty or initialized App::GitFind::FileStatLs object.

=cut

sub new {
    my $caller        = shift;
    my $caller_is_obj = ref($caller);
    my $class         = $caller_is_obj || $caller;
    my $self          = bless {}, $class;
    my %arg           = @_;   # convert rest of inputs into hash array
    foreach my $k ( keys %arg ) {
        if ($caller_is_obj) {
            $self->{$k} = $caller->{$k};
        } else {
            $self->{$k} = $arg{$k};
        }
    }
    return $self;
}

=head1 METHODS

This class defines the following common methods, routines, and
functions.

=head2 Exported Tag: All

The C<:all> tag includes all the methods or sub-rountines
defined in this class.

  use App::GitFind::FileStatLs qw(:all);

It includes the following sub-routines:

=cut

# ------ partial inline of Stat::lsMode v0.50 code
# (see http://www.plover.com/~mjd/perl/lsMode/
# for the complete module)
#
#
# Stat::lsMode
#
# Copyright 1998 M-J. Dominus
# (mjd-perl-lsmode@plover.com)
#
# You may distribute this module under the same terms as Perl itself.
#
# $Revision: 1.2 $ $Date: 2004/08/05 14:17:43 $

=head2 format_mode ($mode)

Input variables:

  $mode - the third element from stat

Variables used or routines called:

  None

How to use:

   my $md = $self->format_mode((stat $fn)[2]);

Return: string with permission bits such as -r-xr-xr-x.

=cut

sub format_mode {
    my $s = ref($_[0]) ? shift : (App::GitFind::FileStatLs->new);
    my $mode = shift;
    my %opts = @_;

    my @perms = qw(--- --x -w- -wx r-- r-x rw- rwx);
    my @ftype = qw(. p c ? d ? b ? - ? l ? s ? ? ?);
    $ftype[0] = '';
    my $setids = ($mode & 07000)>>9;
    my @permstrs = @perms[($mode&0700)>>6, ($mode&0070)>>3, $mode&0007];
    my $ftype = $ftype[($mode & 0170000)>>12];

    if ($setids) {
      if ($setids & 01) {         # Sticky bit
        $permstrs[2] =~ s/([-x])$/$1 eq 'x' ? 't' : 'T'/e;
      }
      if ($setids & 04) {         # Setuid bit
        $permstrs[0] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
      if ($setids & 02) {         # Setgid bit
        $permstrs[1] =~ s/([-x])$/$1 eq 'x' ? 's' : 'S'/e;
      }
    }

    join '', $ftype, @permstrs;
}

=head2 ls_stat ($fn)

Input variables:

  $fn - file name

Variables used or routines called:

  None

How to use:

   my $ls = ls_stat($fn);
   # NOT $self->ls_stat($fn) --- not supported

Return: the ls string such as one of the following:

  -r-xr-xr-x   1 root     other         4523 Jul 12 09:49 uniq
  drwxr-xr-x   2 root     other         2048 Jul 12 09:50 bin
  lrwxrwxrwx   1 oracle7  dba             40 Jun 12  2002 linked.pl -> /opt/bin/linked2.pl

The output B<includes> a trailing newline.

=cut

sub ls_stat {
    my $fn = shift;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = lstat $fn;
    my $dft = "%b %d  %Y";
    my $ud = getpwuid($uid);
    my $gd = getgrgid($gid);
    my $fm = format_mode($mode);
    my $mt = strftime $dft,localtime $mtime;
    my $link_to = (($mode & S_IFLNK) == S_IFLNK ? " -> @{[readlink $fn]}" : "");
    my $fmt = "%10s %3d %7s %4s %12d %12s %-s%s\n";
    return sprintf $fmt, $fm,$nlink,$ud,$gd,$size,$mt,$fn,$link_to;
}

=head2 stat_attr ($fn, $typ)

Input variables:

  $fn - file name for getting stat attributes
     ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = stat($fn);
  $typ - what type of object that you want it to return.
    The default is to return a hash containing filename, longname,
    and a hash ref with all the element from stat.
    SFTP - to return a Net::SFTP::Attributes object

Variables used or routines called:

  ls_stat

How to use:

   my $hr = $self->stat_attr($fn);  # get hash ref
   my %h  = $self->stat_attr($fn);  # get hash

Return: C<$hr> or C<%h> where the hash elements depend on the type.
The default is to get a hash array with the following elements:

  filename - file name
  longname - the ls_stat string for the file
  a        - the attributes of the file with the following elements:
             dev,ino,mode,nlink,uid,gid,rdev,size,atime,mtime,
             ctime,blksize,blocks

If the type is SFTP, then it will only return a
L<Net::SFTP::Attributes> object with the following elements:

  flags,perm,uid,gid,size,atime,mtime

=cut

sub stat_attr {
    my $s = ref($_[0]) ? shift : (App::GitFind::FileStatLs->new);
    my ($fn,$typ) = @_;
    (require Carp, Carp::croak "ERR: no file name for stat_attr.\n") if ! $fn;
    return undef if ! $fn;
    my $vs  = 'dev,ino,mode,nlink,uid,gid,rdev,size,atime,mtime,';
       $vs .= 'ctime,blksize,blocks';
    my $v1  = 'flags,perm,uid,gid,size,atime,mtime';
    my $ls = ls_stat $fn;  chomp $ls;
    my @a = (); my @v = ();
    my $attr = {};
    if ($typ && $typ =~ /SFTP/i) {
        @v = split /,/, $v1;
        @a = (stat($fn))[1,2,4,5,7,8,9];
        %$attr = map { $v[$_] => $a[$_] } 0..$#a ;
        # 'SSH2_FILEXFER_ATTR_SIZE' => 0x01,
        # 'SSH2_FILEXFER_ATTR_UIDGID' => 0x02,
        # 'SSH2_FILEXFER_ATTR_PERMISSIONS' => 0x04,
        # 'SSH2_FILEXFER_ATTR_ACMODTIME' => 0x08,
        $attr->{flags} = 0;
        $attr->{flags} |= 0x01;
        $attr->{flags} |= 0x02;
        $attr->{flags} |= 0x04;
        $attr->{flags} |= 0x08;
        return wantarray ? %{$attr} : $attr;
    } else {
        @v = split /,/, $vs;
        @a = stat($fn);
        %$attr = map { $v[$_] => $a[$_] } 0..$#a ;
    }
    my %r = (filename=>$fn, longname=>$ls, a=>$attr);
    # foreach my $k (keys %r) { print "$k=$r{$k}\n"; }
    # foreach my $k (keys %a) { print "$k=$a{$k}\n"; }
    # print "X: " . (wantarray ? %r : \%r) . "\n";
    return wantarray ? %r : \%r;
}

1;

=head1 SEE ALSO (some of docs that I check often)

L<Data::Describe>, L<Oracle::Loader>, L<CGI::Getopt>, L<File::Xcopy>,
L<Oracle::Trigger>, L<Debug::EchoMessage>, L<CGI::Getopt>, L<Dir::ls>, etc.

=head1 AUTHOR

Copyright (c) 2005 Hanming Tu.  All rights reserved.
Portions Copyright (c) 2019 D3 Engineering, LLC.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
