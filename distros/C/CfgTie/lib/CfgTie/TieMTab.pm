#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

=head1 NAME

C<CfgTie::TieMTab> -- an associative array of mount entries

=head1 SYNOPSIS

makes the mount table available as a regular hash:

    tie %MTab, 'CfgTie::TieMTab';
    tie %MTab, 'CfgTie::TieMTab_dev';

=head1 DESCRIPTION

The keys are path and devices. 

The values are always list references.  The lists are one of two forms.  For
local path, the list is of the form:

    [$device, $path, $type, $options]

Other paths not in the mount table are of the form

    [$device]

The form of I<device> varies from system to system.  It is usually the device
specified in the mount table.  NFS and other network mounts are of the form
I<host:path>.  C<amd> devices are different, and (at the time of this writing)
their form isn't known.

=head1 Caveats

This requires C<Quota> to work.  You can get it from CPAN.

=head1 Files

=over 1

=item F</etc/mtab>

(on many machines)

=item F</proc/mounts>

(on Linux machines)

=back

=head1 See Also

L<Quota::>

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

package CfgTie::TieMTab;

my $Ok=0;

if (eval("use Quota;")) {$Ok=1;}

my (%by_dev,%by_path);
1;

sub TIEHASH
{
   # Fail the tie has if the Quota package wasn't tied in
   if (!$Ok) {return undef;}
   my $self=shift;

   #Scan the mount table now
   MTab_scan();

   return bless {},$self;
}

sub EXISTS
{
   my ($self, $path)=@_;
   if (exists $by_path{$path}) {return 1;}

   #Try to look up remotely things...
   my $dev = Quota::getdev($path);

   #If it failed, it does not exist
   if (!defined $dev) {return 0;}

   if (!exists $by_dev{$dev}) {$by_dev{$dev}=[$dev];}

   return 1;
}

sub FETCH
{
   my ($self,$path)=@_;

   if (exists $by_path{$path}) {return $by_path{$path};}

   #Try to look up remotely things...
   my $dev = Quota::getdev($path);

   #If it failed, it does not exist
   if (!defined $dev) {return undef;}

   if (!exists $by_dev{$dev}) {$by_dev{$dev}=[$dev];}

   $by_dev{$dev};
}

sub MTab_scan()
{
   Quota::setmntent();
   while (my @A=Quota::getmntent())
    {
       $by_dev {$A[0]}=\@A;
       $by_path{$A[1]}=\@A;	 
    }
   Quota::endmntent();
}

package CfgTie::TieMTab_dev;

sub TIEHASH
{
   # Fail the tie has if the Quota package wasn't tied in
   if (!$Ok) {return undef;}
   my $self=shift;

   #Scan the mount table now
   if (!scalar keys %CfgTie::TieMTab::by_dev) {MTab_scan();}

   return bless {},$self;
}

sub EXISTS {exists $CfgTie::TieMTab::by_dev{$_[1]};}
sub FETCH  {$CfgTie::TieMTab::by_dev{$_[1]};}
