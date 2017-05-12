#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::filever;

=head1 NAME

CfgTie::filever -- a simple module for substituting newer versions into a file system.

=head1 SYNOPSIS

This module allows a newer version of file to be safely placed into the file system.

=head1 DESCRIPTION

This is a set of utilities for manipulating files.

=head2 C<File's_Rotate> (I<$Old, $New>)

This is the file space equivalent to the variable exchange or swap.  The
I<old> file will be renamed (with a .old extension) and the I<new> file will
be renamed to I<old>.  This is extremely useful for many semi-critical
functions, where modifying the file directly will cause unpredictable results.
Instead, the preferred method is to modify I<old> sending the results to
I<new> in the background and then doing a I<very> quick switcheroo.

It preserves the permissions and ownership of the original file.

If this routine fails, it will make an attempt to restore things to their
original state and return.

B<Return Value>: 0 on success, -1 on error;

=head2 C<Roll(>I<path>,I<depth>,I<sep>C<)>

This convert the specified files into a backup file (the original file is
renamed, so you had better have something to put there).

=over 1

=item I<Depth>

(optional) Controlls the number of backup copies

=item I<Sep>

(optional) Controlls the seperator between the main name and the backup
number

=back

The defaults for I<depth> and I<sep> are controlled by following two variables
in the package:

=over 1

=item C<RollDepth>

Controlls the number of of older versions that are kept around as backup
copies.
I<[Default: 4]>

=item C<RollSep>

Controls the separator between the file name and the backup number.
I<[Default: >C<~>I<]>

=back

=head2 C<RCS_path (>I<RCSObj>,I<path>C<)>

For the given RCS object, this sets the working directory and the file.

=head2 find_by_user

This function attempts to locate all of the files in the system that are owned
by the specified users.  It takes the following parameters:

=over 1

=item C<Base>

C<Base> can be a string to the base path or a reference to a list of base
paths to search.

=back

Return Value:

=over 1

=item C<undef> if there was an error

=item otherwise the list of file that matched

=back

=head1 Author

Randall Maas (L<randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

my $RollDepth = 4;
my $RollSep = '~';

sub Rotate
{
   my($Old, $New) =  @_;
   if (!defined $Old) {die "Rotate: old not defined, but $New is!\n";}
   if ($Old eq $New) {return;}

   my @S =stat $Old;
   #If the old file does exist we need to do a bit of work (we use stat
   #since the other bits of information are relevant too)
   if (scalar @S)
     {
        #Migrate us to some backup copies, use one more than default so we
        #can unroll
        &Roll($Old,$RollDepth+1);

        # Modify the permissions of the new file to match that of the old one.
        if (!chmod($S[2], $New) ||

        # Modify the ownership of the new file to match that of the old one.
            !chown($S[4], $S[5], $New)||

            !rename($New, $Old))
          {
             die "bad things happened: $New doesn't exist? $!\n";
             &Unroll($Old,$RollDepth+1);
             return -1;
          }
     }
    else
     {
        rename ($New,$Old) || return -1;
     }
    0;
}


sub Roll
{
   my ($File,$Num,$Sep) =@_;
   if (!defined $File) {die "File not defined!\n";}
   if (!defined $Sep) {$Sep = $RollSep;}
   if (!defined $Num) {$Num = $RollDepth;}

   if ($Num < 1) {return;}

   my $Base = $File.$Sep;
   for (my $I=$Num-1; $I; $I--)
    {rename $Base.$I,$Base.($I+1);}

   link $File, $Base."1";
   #rename $File, $Base."1";
}

sub Unroll
{
  my ($File,$Num,$Sep) =@_;
  if (!defined $Sep) {$Sep = $RollSep;}
  if (!defined $Num) {$Num = $RollDepth;}

  if ($Num < 1) {return;}

  my $Base = $File.$Sep;
  rename $Base.'1',$File;
  for (my $I=1; $I < $RollDepth; $I++)
   {rename $Base.($I+1),$Base.$I;}
}

sub RCS_path($$)
{
   my ($RCSObj, $Path) = @_;
   if ($Path =~ /^(.+)\/([^\/]+)$/)
     {
        $RCSObj->workdir($1);
        $RCSObj->file($2);

        #Make the working directory and archive directory make sense
        my $t = $RCSObj->rcsdir;
        if (!defined $t || (substr($t,0,1) ne '/' && substr($1,0,1) ne '.'))
          {$RCSObj->rcsdir($1.'/'.$t);}

     }
    else
     {
        $RCSObj->file($Path);
     }
}

use FileHandle;

sub open($)
{
   local($name)=@_;
   #Save the environment so we can restore it
   my $E=\%ENV;

   #Erase the path, and other environment information
   %ENV=();
   $ENV{'PATH'}='/bin:/sbin';
   my $F=eval ('new FileHandle $name');

   #Restore the environment
   %ENV=%{$E};
   $F;
}

sub system($)
{
   my $F= &filever::open($_[0]."|");
   $F->close;
}


my @UID_paths; # Holder of file paths that match 

sub UID_worker
{
   # A worker to check to see if the specified files owner matches any in our
   # set
   my @S = stat $_;
   if (exists $UIDs_to_watch{$S[4]}) {push @UID_paths, $File::Find::name;}
}

sub find_by_user
{
   my $Base = shift;

   if (!scalar @_) {return ();}

   use File::Find;
   my %User;
   tie %User, 'user';

   #Convert all of the user names and such to ids
   %UIDs_to_watch=();
   foreach my $I (@_)
    {
       if (exists $User{$I})
         {$UIDs_to_watch{$User{$I}->{Id}}=1;}
        else
         {$UIDs_to_watch{$I} = 1;}
    }

   #Call find to executie it
   @UID_paths=();
   if (not ref $Base)
     {find(\&UID_worker, $Base);}
    else
     {find(\&UID_worker, @{$Base});}
   return @UID_paths;
}

1;
