#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


package CfgTie::TieHost;

=head1 NAME

C<CfgTie::TieHost> -- This accesses the hosts tables.

=head1 SYNOPSIS

This is an associative array that allows the hosts tables to be configured
easily.

        tie %host,'CfgTie::TieHost';

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the host database
sanely.

=head2 Ties

There are two ties available for programmers:

=over 1

=item C<tie %host,'CfgTie::TieHost'>

C<$host{$name}> will return a hash reference of the named host information.

=item C<tie %host_addr,'CfgTie::TieHost_addr'>

C<$host_addr{$addr}> will return a hash reference for the specified host.

=back

=head2 Structure of hash

Any given host entry has the following information assoicated with it:

=over 1

=item C<Name>

Host name

=item C<Aliases>

Other names for this host

=item C<AddrType>

The type of address 

=item C<Length>

=item C<Addrs>

A list reference of addresses.  You will need something like

       ($a,$b,$c,$d) = unpack('C4',$Addr);

to get the address out sanely.

=back

Additionally, the programmer can set any other associated key, but this
information will only be available to a running Perl script.

=head1 See Also

L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>, L<CfgTie::TieGroup>,
L<CfgTie::TieMTab>,    L<CfgTie::TieNamed>,   L<CfgTie::TieNet>,
L<CfgTie::TiePh>,      L<CfgTie::TieProto>,   L<CfgTie::TieRCService>,
L<CfgTie::TieRsrc>,    L<CfgTie::TieServ>,    L<CfgTie::TieShadow>,
L<CfgTie::TieUser>

L<host(5)>

=head1 Caveats

The current version does cache some host information.

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

sub TIEHASH
{
   my $self = shift;
   my $node = {};
   return bless $node, $self;
}

sub FIRSTKEY
{
   my $self = shift;

   #Rewind outselves to the beginning.
   sethostent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next host id in the database.
   # Get the information from the system and store it for later
   my @x = gethostent;
   if (! scalar @x) {return;}

   &CfgTie::TieHost_rec'TIEHASH(0,@x);
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = shift;
   if (exists $CfgTie::TieHost_rec'by_name{$name}) {return 1;}

   # Get the information from the system and store it for later
   my @x = gethostbyname $name;
   if (! scalar @x) {return 0;}

   &CfgTie::TieHost_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   #check out our cache first
   if (exists $CfgTie::TieHost_rec'by_name{$name})
     {return $CfgTie::TieHost_rec'by_name{$name};}

   my %X;
   tie %X, 'CfgTie::TieHost_rec', gethostbyname $name;
   return bless %X;
}

1;
#Bug creating, deleting hosts is not supported yet.

package CfgTie::TieHost_addr;

sub TIEHASH
{
   my $self = shift;
   my $node = {};
   return bless $node, $self;
}

sub FIRSTKEY
{
   my $self = shift;

   #Rewind outselves to the beginning.
   sethostent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next host id in the database.
   # Get the information from the system and store it for later
   my @x = gethostent;
   if (! scalar @x) {return;}

   &CfgTie::TieHost_rec'TIEHASH(0,@x);
   return $x[5]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$addr) = shift;
   if (exists $CfgTie::TieHost_rec'by_addr{$addr}) {return 1;}

   # Get the information from the system and store it for later
   my @x = gethostbyaddr $addr, AF_INET;
   if (! scalar @x) {return 0;}

   &CfgTie::TieHost_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self,$addr) = @_;

   #check out our cache first
   if (exists $CfgTie::TieHost_rec'by_addr{$addr})
      {return $CfgTie::TieHost_rec'by_addr{$addr};}

   my %X;
   tie %X, 'CfgTie::TieHost_rec', gethostbyaddr($addr, AF_INET);
   return bless %X;
}

#Bug creating and modifying hosts is not supported yet.

package CfgTie::TieHost_rec;
# A package used by both host_addr and host to retain record information about
# a hoost.  This is the only way to access hostmod.

#Two hashes are used for look up
# $by_name{$name}
# $by_addr{$addr}

sub TIEHASH
{
   # Ties a single host to a register...
   my $self = shift;
   my $Name = shift;
   my $Node;

   if (exists $by_name{$Name})
     {
        #Just update our record...
        $Node = $by_name{$Name};
     }
#    else  create it

   my ($Aliases,@Addrs);
   $Node->{Name} = $Name;
   ($Aliases, $Node->{AddrType}, @Addrs) = @_;
   $Node->{Aliases} = [split ',',$Aliases];
   $Node->{Addrs}   = \@Addrs;

   #Cross reference the names
   my $I;
   foreach $I ($Name, $Node->{Aliases})
    {$by_name{$I} = $Node;}

   #Cross reference the addresses
   foreach $I (@Addrs)
    {$by_addr{$I} = $Node;}

   return bless $Node, $self;
}

sub FIRSTKEY
{
   my $self = shift;
   my $a = keys %self;
   return scalar each %self;
}

sub NEXTKEY
{
   my $self = shift;
   return scalar each %self;
}

sub EXISTS
{
   my ($self,$key) = shift;
   return exists $self{$key};
}

sub FETCH
{
   my $self = shift;
   my $key = shift;

   if (exists $self{$key}) {return $self{$key};}
}

sub STORE
{
   # Changes a setting for the specified host... we basically call hostmod
   my ($self,$key,$val) = @_;

        #Extra setting that will be lost... 8(
        $self{$key}=$val;
}

sub DELETE
{
   #Deletes a host setting
   my ($self, $key) = @_;

           #Just remove our local copy
           delete $self{$key};
}
1;
