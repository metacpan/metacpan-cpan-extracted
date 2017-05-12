#!/usr/bin/perl -Tw
#Copyright 1998-1999, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieProto;

=head1 NAME

CfgTie::TieProto, CfgTie::TieProto_num -- Ties the protocol number file to a
 PERL hash

=head1 SYNOPSIS

	tie %proto, 'CfgTie::TieProto';
	print $proto{'tcp'};

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the protocol
number database sanely.

=head2 Ties

There are two ties available for programmers:

=over 1

=item C<tie %proto,'CfgTie::TieProto'>

C<$proto{$name}> will return a hash reference of the named protocol
information

=item C<tie %proto_num,'CfgTie::TieProto_num'>

C<$proto_num{$num}> will return a hash reference for the specified protocol
number.

=back

=head2 Structure of hash

Any given proto entry has the following information assoicated with it:

=over 1

=item C<Name>

proto name

=item C<Aliases>

A list reference for other names for this proto

=item C<Number>

The protocol number

=back

Additionally, the programmer can set any other associated key, but this
information will only be available to the running Perl script.

=head1 See Also

L<CfgTie::Cfgfile>, L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,   L<CfgTie::TieHost>, L<CfgTie::TieNamed>,
L<CfgTie::TieNet>,     L<CfgTie::TiePh>,   L<CfgTie::TieProto>,
L<CfgTie::TieServ>,    L<CfgTie::TieShadow>,  L<CfgTie::TieUser>

=head1 Caveats

The current version does cache some proto information.

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
   setprotoent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next proto id in the database.
   # Get the information from the system and store it for later
   my @x = getprotoent;
   if (! scalar @x) {return;}

   &CfgTie::TieProto_rec'TIEHASH(0,@x);
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = shift;
   if (exists $CfgTie::TieProto_rec'by_name{$name}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getprotobyname $name;
   if (! scalar @x) {return 0;}

   &CfgTie::TieProto_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   #check out our cache first
   if (exists $CfgTie::TieProto_rec'by_name{$name})
     {return $CfgTie::TieProto_rec'by_name{$name};}

   my %X;
   tie %X, 'CfgTie::TieProto_rec', getprotobyname $name;
   return bless %X;
}

#Bug creating, deleting protos is not supported yet.
1;

package CfgTie::TieProto_num;

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
   setprotoent 1;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next proto id in the database.
   # Get the information from the system and store it for later
   my @x = getprotoent;
   if (! scalar @x) {return;}

   &CfgTie::TieProto_rec'TIEHASH(0,@x);
   return $x[5]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$num) = shift;
   if (exists $CfgTie::TieProto_rec'by_num{$num}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getprotobynumber $num;
   if (! scalar @x) {return 0;}

   &CfgTie::TieProto_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self,$num) = @_;

   #check out our cache first
   if (exists $CfgTie::TieProto_rec'by_num{$num})
     {return $CfgTie::TieProto_rec'by_num{$num};}

   my %X;
   tie %X, 'CfgTie::TieProto_rec', getprotobynumber $num;
   return bless %X;
}

#Bug creating and modifying protos is not supported yet.

package CfgTie::TieProto_rec;
# A package used by both proto_num and proto to retain record information about
# a hoost.  This is the only way to access protomod.

#Two hashes are used for look up
# $by_name{$name}
# $by_num{$num}

sub TIEHASH
{
   # Ties a single proto to a register...
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
   ($Aliases, $Node->{Number}) = @_;
   $Node->{Aliases} = [split ',',$Aliases];

   #Cross reference the names
   my $I;
   foreach $I ($Name, $Node->{Aliases})
    {$by_name{$I} = $Node;}

   $by_num{$Node->{Number}} = $Node;

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
   # Changes a setting for the specified proto... we basically call protomod
   my ($self,$key,$val) = @_;

   #Extra setting that will be lost... 8(
   $self{$key}=$val;
}

sub DELETE
{
   #Deletes a proto setting
   my ($self, $key) = @_;

   #Just remove our local copy
   delete $self{$key};
}
1;
