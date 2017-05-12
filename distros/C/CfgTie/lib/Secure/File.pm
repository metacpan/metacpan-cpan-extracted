#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

=head1 NAME

C<Secure::File> -- A module to open or create files within suid/sgid files

=head1 SYNOPSIS

    use Secure::File;
    my $SF = new Secure::File;
    $SF->open();

    my $NF = new Secure::File, 'myfile';


=head1 DESCRIPTION

C<open>  This checks that both the effective and real  user / group ids have
sufficient permissions to use the specified file.  (Standard C<open> calls only
check the effective ids).  C<Secure::File> also checks that the file we
open, really is the same file we checked ids on.

If the file already exists, C<open> will fail.

=head1 WARNING <==============================================================>

B<DO NOT TRUST THIS MODULE>.  Every effort has been made to make this module
useful, but it can not make a secure system out of an insecure one.  It can not
read the programers mind.  

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut


package Secure::File;
use IO::File;
use Carp;
@ISA=qw(IO::File);
1;

sub new
{
   my $self=shift;

   #Call the parent class new; we basically use IO::File's create
   my $class=ref($self) || $self || "IO::File";
   my $R = $class->SUPER::new();

   #If it doesn't work, we give up and return to the caller.
   return unless defined $R;

   #If the caller passed some open() parameters, we will need to open the
   #file as well
   if (@_)
   {
      return unless $R->open(@_);
   }
   return $R;
}

sub open
{
    @_ >= 2 && @_ <= 4 or croak 'usage: $fh->open(FILENAME [,MODE [,PERMS]])';
   my $self= shift;
   my $class=ref($self) || $self || "IO::File";
   my @S = open_precheck(@_);

   my $file = shift;
   my $mode='';
   if ($file=~s/^([<>]\s*)//) {$mode=$1;}
   if (! File::Spec->file_name_is_absolute($file)) {
     $file = File::Spec->catfile(File::Spec->curdir(),$file);
   }

   my $x;

   if (@_ > 2) {
	my $perms;
        ($mode, $perms) = @_[2, 3];
        if ($mode =~ /^\d+$/) {
            defined $perms or $perms = 0666;
            $x=sysopen($self, $file, $mode, $perms);
        }
	else
	{
           $file = IO::Handle::_open_mode_string($mode) . " $file\0";
   	   $x = open($self, $file);
	}
    }
   else
     {
	$x =open($self, $mode.$file);
     }

   carp "Secure::File: Couldn't open $file" unless $x;
   if ($mode =~ /^[>\sw]+$/ || ($mode =~ /^\d+$/ && $mode & O_WRONLY) ||
	(!@S && ($mode =~ /w/ || ($mode =~ /^\d+$/ && $mode & O_RDWR))))
     {
	return $x;
     }
   return 0 unless @S;
   if ($self->handle_check(@S))
     {
        return $self;
     }
   $self->close();
   return 0;
}

sub open_precheck($$)
{
   my $name=shift;
   if ($name =~ /^<\s*([^\s]+)$/)
        {
	   r_check($1);
	}
   elsif ($name =~ /^>\s*([^\s]+)$/)
        {
	   w_check($1);
        }
   elsif (@_ && defined $_[0] && (($_[0]=~/^\d+$/ && ($_[0] & O_WRONLY))
		|| lc($_[0]) eq 'w'))
        {
	   w_check($name);
	}
   elsif (defined $_[0] && (($_[0] =~ /r/i && $_[0] =~ /w/i) ||
			    ($_[0] =~ /^\d+$/ && ($_[0] & O_RDWR))))
        {
	   rw_check($name);
        }
   else
        {
	   r_check($name);
        }
}

sub r_check
{
    #Check to see if the real user has read privileges
    my @S=stat($_[0]);
    if (!@S) {return;}
    return @S if -R _;
}

sub w_check
{
    #Check to see if the real user has write privileges
    my @S=stat($_[0]);
    if (!@S)
      {
         if ($_[0] =~ /^(.*)\/[^\/]+$/)
	   {
	      @S=stat($1);
	      return @S if -W _;
	   }
         return;
      }
    return @S if -W _;
}

sub rw_check
{
    #Check to see if the real user has read/write privileges
    my @S=stat($_[0]);
    if (!@S) {return;}
    return undef if !-R _;
    return @S    if  -W _;
}

sub handle_check
{
   #Check to be sure that the inode has not changed!
   my $Handle = shift;

   #Get the information on the file
   my @S2 = $Handle->stat;

   #If the file doesn't exist, return false;
   return 0 unless @S2;

   #Return true if and only if the file has the same ID:
   # That is: its dev, rdev, inode all match
   if ($_[0] != $S2[0] || $_[1] != $S2[1] || $_[6] != $S2[6]) {return 0;}
   1;
}
