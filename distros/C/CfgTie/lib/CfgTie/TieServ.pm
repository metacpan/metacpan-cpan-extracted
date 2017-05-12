#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieServ;
use CfgTie::Cfgfile;
use Secure::File;
use vars qw($VERSION @ISA);
use AutoLoader 'AUTOLOAD';
@ISA=qw(AutoLoader);
$VERSION='0.41';
my (%by_name,%by_port);
1;

__END__

=head1 NAME

CfgTie::TieServ -- A HASH tie that allows access the service port database

=head1 SYNOPSIS

	tie %serv,'CfgTie::TieServ';
	print $serv{'smtp'};

=head1 DESCRIPTION

This is a straight forward HASH tie that allows us to access the service
port database sanely.

=head2 Ties

There are two ties available for programers:

=over 1

=item C<tie %serv,'CfgTie::TieServ'>

C<$serv{$name}> will return a HASH reference of the named service
information

=item C<tie %serv_port,'CfgTie::TieServ_port'>

C<$serv_port{$port}> will return a HASH reference for the specified service
port.

=back

=head2 Structure of hash

Any given serv entry has the following information assoicated with it:

=over 1

=item C<Name>

Service name

=item C<Aliases>

A list reference for other names for this service

=item C<Port>

The port number

=item C<Protocol>

The protocol name

=back

Additionally, the programmer can set any
other associated key, but this information will only available to running
PERL script.

=head1 See Also

L<CfgTie::Cfgfile>,  L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,
L<CfgTie::TieHost>,   L<CfgTie::TieNamed>, L<CfgTie::TieNet>,
L<CfgTie::TiePh>,     L<CfgTie::TieProto>, L<CfgTie::TieShadow>,
L<CfgTie::TieUser>

=head1 Caveats

The current version does cache some service information.

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

   #See if it has already been cached
   if (exists $self->{' allscan'})
     {
	my $a = keys %by_name;
	$a = scalar each %by_name;
	if ($a ne ' allscan') {return $a;}
	return scalar each %by_name;
     }

   #Rewind outselves to the beginning.
   setservent 1;

   NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #See if it has already been cached
   if (exists $self->{' allscan'})
     {
	my $a = scalar each %by_name;
	if ($a ne ' allscan') {return $a;}
	return scalar each %by_name;
     }

   #Use the API

   #Get the next serv id in the database.
   # Get the information from the system and store it for later
   my @x = getservent;
   if (! scalar @x)
     {
	 $self->{' allscan'}=1; 
       return;
     }

   tie %{$by_name{$x[0]}}, 'CfgTie::TieServ_rec', @x;
   $by_port{$x[2]}=$by_name{$x[0]};
   return $x[0]; #Corresponds to the name
}

sub HTML
{
   my $self=shift;

   my %A;
   for(my $I = FIRSTKEY($self); $I; $I = NEXTKEY($self))
   {
      my $B= CfgTie::Cfgfile::td($by_name{$I}->{port}).
     CfgTie::Cfgfile::td($by_name{$I}->{protocol});
       foreach my $J ($I, @{$by_name{$I}->{aliases}})
        {
	   $A{$J} = "<tr>".
	      CfgTie::Cfgfile::th("<a href=\"net/service/$I\">$J</a>").$B."</tr>\n";
       }
   }

   my $R="<tr><th class=\"cfgattr\">Name</th><th class=\"cfgattr\">Port</th>".
       "<th class=\"cfgattr\">Protocol</th></tr>\n";
   foreach my $K (sort {lc($a) cmp lc($b)} keys %A) {$R .= $A{$K};}
   CfgTie::Cfgfile::table("Network services",$R,3);
}

sub EXISTS
{
   my ($self,$name) = shift;
   if (exists $by_name{$name}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getservbyname $name, AF_INET;
   if (! scalar @x) {return 0;}


   tie %{$by_name{$x[0]}}, 'CfgTie::TieServ_rec', @x;
   $by_port{$x[2]}=$by_name{$x[0]};
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   #check out our cache first
   if (exists $by_name{$name}) {return $by_name{$name};}

   my %X;
   tie %X, 'CfgTie::TieServ_rec', getservbyname($name, AF_INET);
   return bless %X;
}

#Bug creating, deleting servs is not supported yet.
1;

package CfgTie::TieServ_port;

sub TIEHASH
{
   my $self = shift;
   my $node = {};
   return bless $node, $self;
}

sub FIRSTKEY
{
   my $self = shift;

   #See if it has already been cached
   if (exists $self->{' allscan'})
     {
	my $a = keys %CfgTie::TieServ::by_port;
	$a = scalar each %CfgTie::TieServ::by_port;
	if ($a ne ' allscan') {return $a;}
	return scalar each %CfgTie::TieServ::by_port;
     }

   #Rewind outselves to the beginning.
   setservent 1;

   NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #See if it has already been cached
   if (exists $self->{' allscan'})
     {
	my $a = scalar each %CfgTie::TieServ::by_port;
	if ($a ne ' allscan') {return $a;}
	return scalar each %CfgTie::TieServ::by_port;
     }

   #Use the API

   #Get the next serv id in the database.
   # Get the information from the system and store it for later
   my @x = getservent;
   if (! scalar @x)
     {
	 $self->{' allscan'}=1; 
       return;
     }

   tie %{$CfgTie::TieServ::by_name{$x[0]}}, 'CfgTie::TieServ_rec', @x;
   $CfgTie::TieServ::by_port{$x[2]}=$CfgTie::TieServ::by_name{$x[0]};
   return $x[2]; #Corresponds to the name
}

sub HTML
{
   my $self=shift;

   my %A;
   for(my $I = FIRSTKEY($self); $I; $I = NEXTKEY($self))
   {
       my $S=$CfgTie::TieServ::by_port{$I};
      my $B=CfgTie::Cfgfile::td($I);
      my $C=CfgTie::Cfgfile::td($S->{protocol});
      $A{$I} = "<tr>".$B.
	CfgTie::Cfgfile::td("<a href=\"net/serv/".
			    $S->{name}."\">".$S->{name}."</a>, ".
	       join(', ', @{$S->{aliases}})).
		$C.
	    "</tr>\n";
   }

   my $R="<tr><th class=\"cfgattr\">Port</th><th class=\"cfgattr\">Names</th>".
       "<th class=\"cfgattr\">Protocol</th></tr>\n";
   foreach my $K (sort {$a <=> $b} keys %A) {$R .= $A{$K};}
   CfgTie::Cfgfile::table("Network services",$R,3);
}


sub EXISTS
{
   my ($self,$port) = shift;
   if (exists $CfgTie::TieServ::by_port{$port}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getservbyport $port, AF_INET;
   if (! scalar @x) {return 0;}

   &CfgTie::TieServ_rec'TIEHASH(0,@x);
   return 1;
}

sub FETCH
{
   my ($self,$port) = @_;

   #check out our cache first
   if (exists $CfgTie::TieServ::by_port{$port})
    {return $CfgTie::TieServ::by_port{$port};}

   my %X;
   tie %X, 'CfgTie::TieServ_rec', getservbyport($port, AF_INET);
   return bless %X;
}

#Bug creating and modifying servs is not supported yet.

package CfgTie::TieServ_rec;
# A package used by both CfgTie::TieServ_port and CfgTie::TieServ to retain
# record information about a service port.  This is the only way to access
# servmod.

sub TIEHASH
{
   # Ties a single serv to a register...
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
   $Node->{name} =$Name;
   ($Aliases, $Node->{port}, $Node->{protocol}) = @_;
   $Node->{aliases} = [split /[\s,]+/,$Aliases];

   #Cross reference the names
   my $I;
   foreach $I ($Name, $Node->{aliases})
    {$CfgTie::TieServ::by_name{$I} = $Node;}

   return bless $Node, $self;
}

sub HTML
{
   my $self=shift;
   CfgTie::Cfgfile::table
       (
	$self->{name},
	CfgTie::Cfgfile::trx("Name:",$self->{name}).
	CfgTie::Cfgfile::trx("Port:",$self->{port}).
	CfgTie::Cfgfile::trx("Protocol:",$self->{protocol}).
	CfgTie::Cfgfile::trx("Aliases:",join(', ',@{$self->{aliases}})),2
	);
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
   my ($self,$key) = @_;
   $key = lc($key);

   if (exists $self{$key}) {return $self{$key};}
}

sub STORE
{
   # Changes a setting for the specified serv... we basically call servmod
   my ($self,$key,$val) = @_;

   #Extra setting that will be lost... 8(
   $self{$key}=$val;
}

sub DELETE
{
   #Deletes a serv setting
   my ($self, $key) = @_;

   #Just remove our local copy
   delete $self{$key};
}

