#!/usr/bin/perl -Tw
#Copyright 1998-1999, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieNet;

=head1 NAME

CfgTie::TieNet -- A module to tie in the net database

=head1 SYNOPSIS

        tie %net,'CfgTie::TieNet'

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the net database
sanely.

=head2 Ties

There are two ties available for programmers:

=over 1

=item C<tie %net,'CfgTie::TieNet'>

C<$net{$name}> will return a hash reference of the named net information

=item C<tie %net_addr,'CfgTIe::TieNet_addr'>

C<$net_addr{$addr}> will return a hash reference for the specified network
address.

=back

=head2 Structure of hash

Any given net entry has the following information assoicated with it:

=over 1

=item C<Name>

net name

=item C<Aliases>

A list reference for other names for this net

=item C<AddrType>

The type of address

=item C<Addr>

The address

=back

Additionally, the programmer can set any other associated key, but this
information will only available to the running Perl script.

=head1 See Also

L<CfgTie::Cfgfile>,
L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>, L<CfgTie::TieGroup>,
L<CfgTie::TieHost>,    L<CfgTie::TieNamed>,   L<CfgTie::TiePh>,
L<CfgTie::TieProto>,   L<CfgTie::TieServ>,    L<CfgTie::TieShadow>,
L<CfgTie::TieUser>

=head1 Caveats

The current version does cache some net information.

=head1 Author

Randall Maas (L<randym@acm.org>)

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
   setnetent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next net id in the database.
   # Get the information from the system and store it for later
   my @x = getnetent;
   if (! scalar @x) {return;}

   &CfgTie::TieNet_rec'TIEHASH(0,@x);
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = shift;
   if (exists $CfgTie::TieNet_rec'by_name{$name}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getnetbyname $name;
   if (! scalar @x) {return 0;}

   &CfgTie::TieNet_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   #check out our cache first
   if (exists $CfgTie::TieNet_rec'by_name{$name})
     {return $CfgTie::TieNet_rec'by_name{$name};}

   my %X;
   tie %X, 'CfgTie::TieNet_rec', getnetbyname $name;
   return bless %X;
}

#Bug creating, deleting nets is not supported yet.
1;

package CfgTie::TieNet_addr;

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
   setnetent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next net id in the database.
   # Get the information from the system and store it for later
   my @x = getnetent;
   if (! scalar @x) {return;}

   &CfgTie::TieNet_rec'TIEHASH(0,@x);
   return $x[5]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$addr) = shift;
   if (exists $CfgTie::TieNet_rec'by_addr{$addr}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getnetbyaddr $addr, AF_INET;
   if (! scalar @x) {return 0;}

   &CfgTie::TieNet_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self,$addr) = @_;

   #check out our cache first
   if (exists $CfgTie::TieNet_rec'by_addr{$addr})
     {return $CfgTie::TieNet_rec'by_addr{$addr};}

   my %X;
   tie %X, 'CfgTie::TieNet_rec', getnetbyaddr($addr, AF_INET);
   return bless %X;
}

#Bug creating and modifying nets is not supported yet.

package CfgTie::TieNet_rec;
# A package used by both net_addr and net to retain record information about
# a hoost.  This is the only way to access netmod.

#Two hashes are used for look up
# $by_name{$name}
# $by_addr{$addr}

sub TIEHASH
{
   # Ties a single net to a register...
   my $self = shift;
   my $Name = shift;
   my $Node;

   if (exists $by_name{$Name})
     {
        #Just update our record...
        $Node = $by_name{$Name};
     }
#    else  create it

   my $Aliases;
   $Node->{Name} =$Name;
   ($Aliases, $Node->{AddrType}, $Node->{Addr}) = @_;
   $Node->{Aliases} = [split ',',$Aliases];

   #Cross reference the names
   my $I;
   foreach $I ($Name, $Node->{Aliases})
    {$by_name{$I} = $Node;}

   $by_addr{$Node->{Addr}} = $Node;

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
   # Changes a setting for the specified net... we basically call netmod
   my ($self,$key,$val) = @_;

        #Extra setting that will be lost... 8(
        $self{$key}=$val;
}

sub DELETE
{
   #Deletes a net setting
   my ($self, $key) = @_;

           #Just remove our local copy
           delete $self{$key};
}
1;
