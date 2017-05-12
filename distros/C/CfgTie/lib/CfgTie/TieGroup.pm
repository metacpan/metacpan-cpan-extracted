#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

package CfgTie::TieGroup;
require CfgTie::filever;
require CfgTie::Cfgfile;

=head1 NAME

CfgTie::TieGroup -- an associative array of group names and ids to information

=head1 SYNOPSIS

Makes the groups database available as regular hash

        tie %group,'CfgTie::TieGroup'
        $group{'myfriends'}=['jonj', @{$group{'myfriends'}];

or

        tie %group,'CfgTie::TieGroup', 'mygroupfile'

=head1 DESCRIPTION

This is a straight forward hash tie that allows us to access the user group
database sanely.

It cross ties with the user package and the mail packages

=head2 Ties

There are two ties available for programmers:

=over 1

=item C<tie %group,'CfgTie::TieGroup'>

C<$group{$name}> will return a hash reference of the named group information.

=item C<tie %group_id,'CfgTie::Group_id'>

C<$group_id{$id}> will return a HASH reference for the specified group.

=back

=head2 Structure of hash

Any given group entry has the following information assoicated with it:

=over 1

=item C<name>

=item C<id>

=item C<members>

A list reference to all of the users that are part of this group.

=item C<_members>

A list reference to all of the users that are explicitly listed in the
F</etc/group> file.

=back


Plus an (probably) obsolete fields:

=over 1

=item C<Password>

This is the encrypted password, but will probably be obsolete.

=back

Each of these entries can be modified (even deleted), and they will be
reflected in the overall system.  Additionally, the programmer can set any
other associated key, but this information will only be available to a running
Perl script.

=head2 Additional Routines

=over 1

=item C<(tied %MyHash)->files()>

Returns a list of files employed.

=item C<&CfgTie::TieGroup'status()>

=item C<&CfgTie::TieGroup_id'status()>

Will return C<stat> information on the group database.


=back

=head2 Miscellaneous

C<$CfgTie::TieGroup_rec'groupmod> contains the path to the program F<groupmod>.
This can be modified as required.

C<$CfgTie::TieGroup_rec'groupadd> contains the path to the program F<groupadd>.
This can be modified as required.

C<$CfgTie::TieGroup_rec'groupdel> contains the path to the program F<groupdel>.
This can be modified as required.

=head1 Files

F</etc/passwd>
F</etc/group>
F</etc/gshadow>
F</etc/shadow>

=head1 See Also

L<CfgTie::Cfgfile>,      L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,
L<CfgTie::TieHost>,      L<CfgTie::TieMTab>,    L<CfgTie::TieNamed>,
L<CfgTie::TieNet>,       L<CfgTie::TiePh>,      L<CfgTie::TieProto>,
L<CfgTie::TieRCService>, L<CfgTie::TieRsrc>,    L<CfgTie::TieServ>,
L<CfgTie::TieShadow>,    L<CfgTie::TieUser>

L<group(5)>,
L<passwd(5)>,
L<shadow(5)>,
L<groupmod(8)>,
L<groupadd(8)>,
L<groupdel(8)>

=head1 Caveats

The current version does cache some group information.

=head1 Author

Randall Maas (L<mailto:randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

sub status
{
  # the information for the /etc/group file
  stat '/etc/group';
}

sub TIEHASH
{
   my $self = shift;
   if (@_)
     {
	 return CfgTie::TieGroup_file->TIEHASH(@_);
     }
   my $node = {};
   return bless $node, $self;
}

sub FIRSTKEY
{
   my $self = shift;

   #Rewind outselves to the beginning.
   setgrent;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next group id in the database.
   # Get the information from the system and store it for later
   my @x = getgrent;
   if (!scalar @x) {return;}

   tie %{$CfgTie::TieGroup_rec'by_name{$x[0]}}, 'CfgTie::TieGroup_rec',@x;
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = @_;
   my $lname =lc($name);
   if (exists $CfgTie::TieGroup_rec'by_name{$lname}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getgrnam $name;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieGroup_rec'by_name{$lname}}, 'CfgTie::TieGroup_rec',@x;
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;
   if (!defined $name) {return undef;}
   my $lname = lc($name);

   #check out our cache first
   if (EXISTS($self,$lname))
     {return $CfgTie::TieGroup_rec'by_name{$lname};}

   return undef;
}

#Bug creating groups is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   groupadd or groupmod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my $self = shift;
   my $name = shift;

   #Basically delete the group now.
   CfgTie::filever::system("$CfgTie::TieGroup_rec'groupdel $name");

   #Remove it from our cache
   if (exists $CfgTie::TieGroup_rec'by_name{$name})
     {delete $CfgTie::TieGroup_rec'by_name{$name};}
}

sub HTML($$)
{
   my ($self,$CodeRef)=@_;
   my %A;
   for (my $I=FIRSTKEY($self); $I; $I=NEXTKEY($self,$I))
    {
       my $U=FETCH($self,$I);
       #See if the caller wants us to pass
       if (defined $CodeRef && !&$CodeRef($U)) {next;}
       $A{$I} = CfgTie::Cfgfile::trx(
		"<a href=\"group/$I\">$I</a>",
		join(', ',
		   map {"<a href=\"user/$_\">$_</a>"} (sort @{$U->{'members'}}))
		);
    }
   my $Us;
   foreach my $I (sort keys %A) {$Us.=$A{$I};}
   CfgTie::Cfgfile::table('Groups', $Us, 2);
}

package CfgTie::TieGroup_id;

sub status
{
  # the information for the /etc/group file
  stat '/etc/group';
}


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
   setgrent;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next group id in the database.
   # Get the information from the system and store it for later
   my @x = getgrent;
   if (! scalar @x) {return;}

   tie %{$CfgTie::TieGroup_rec'by_name{$x[0]}}, 'CfgTie::TieGroup_rec',@x;
   return $x[2]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$id) = @_;
   if (!defined $id) {return 0;}

   if (exists $CfgTie::TieGroup_rec'by_id{$id}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getgrgid $id;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieGroup_rec'by_name{$x[0]}}, 'CfgTie::TieGroup_rec',@x;
   $CfgTie::TieGroup_rec'by_id{$id} = $CfgTie::TieGroup_rec'by_name{$x[0]};

   return 1;
}

sub FETCH
{
   my ($self,$id) = @_;

   #check out our cache first
   if (EXISTS($self,$id))
     {return $CfgTie::TieGroup_rec'by_id{$id};}

   return undef;
}

#Bug creating groups is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   groupadd or groupmod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my ($self,$id) = @_;

   if (!exists $CfgTie::TieGroup_rec'by_id{$id})
     {
        #Try to look up the group id
        &FETCH($self,$id);
     }
      
   if (exists $CfgTie::TieGroup_rec'by_id{$id})
     {
        #Basically delete the group now.
        CfgTie::filever::system("$CfgTie::TieGroup_rec'groupdel ".
		$CfgTie::TieGroup_rec'by_id{$id}->{Name});

        #Remove it from out cache
        delete $CfgTie::TieGroup_rec'by_id{$id};
     }
}



package CfgTie::TieGroup_rec;
# A package used by both group_id and group to retain record information about
# a person.  This is the only way to access groupmod.

#Two hashes are used for look up
# $by_name{$name}
# $by_id{$id}

use CfgTie::TieUser;
my %Users;
tie %Users, 'CfgTie::TieUser';
sub uniq ($)
{
   my $L=shift;
   my @Ret=();
   my $J;
   foreach my $I (sort @{$L})
    {if (!defined $J || $J ne $I) {$J=$I; push @Ret,$I;}}
   [@Ret];
}

sub new {TIEHASH(@_);}
sub TIEHASH
{
   # Ties a single group to a register...
   my ($self,$Name,@Rest) = @_;
   my $Node={};
   my $lname = lc($Name);

   if (scalar @Rest)
     {
        ($Node->{password},$Node->{id}, $Node->{_members})=@Rest;
	$Node->{_members}=[split(/\s*(?:,|\s)\s*/, $Node->{_members})];
     }

   if (defined $Name)    {$Node->{name}=$Name;}

   return bless $Node, $self;
}

sub FIRSTKEY ($)
{
   my $self = shift;
   EXISTS($self,'members');
   my $a = keys %{$self};
   return scalar each %{$self};
}

sub NEXTKEY
{
   my $self = shift;
   return scalar each %{$self};
}

sub EXISTS ($$)
{
   my ($self,$key) = @_;
   my $lkey=lc($key);

   if (exists $self->{$lkey}) {return 1;}
   if ($lkey eq 'members' && defined $self->{id})
     {
	my @Mems=@{$self->{_members}};
        foreach my $I (keys %Users)
	 {
	    if (exists $Users{$I}->{'groupid'} &&
		$Users{$I}->{'groupid'} == $self->{id})
	      {push @Mems, $I;}
	 }
	$self->{members}=uniq(\@Mems);
	return 1;
     }

   return 0;
}

sub FETCH
{
   my ($self,$key) = @_;
   my $lkey = lc($key);
   if (EXISTS($self,$lkey)) {return $self->{$lkey};}
   return undef;
}

# Maps the changes to a particular setting to a flag on the command line
$groupmod_opt =
 {
   name => '-n',
   id   => '-g',
 };

$groupmod = '/usr/sbin/groupmod';  #Hard path to groupmod
$groupdel = '/usr/sbin/groupdel';  #Hard path to groupdel

sub STORE
{
   # Changes a setting for the specified group... we basically call groupmod
   my ($self,$key,$val) = @_;
   my $lkey = lc($key);

   if ($lkey eq 'groups')
     {
        #Handle the groups thing...

        #$val is a list reference....
        my ($i,@g) = @{$val};

        CfgTie::filever::system("$groupmod $self->{Name} -g $i -G ".
		join(',', @g));
     }
   if (exists $groupmod_opt{$lkey})
     {
        #This is something for group mod!
        CfgTie::filever::system("$groupmod $groupmod_opt{$lkey} $val ".
		$self->{Name});
     }
    else
     {
        #Extra setting that will be lost... 8(
        $self->{$lkey}=$val;
     }
}

sub DELETE
{
   #Deletes a group setting
   my ($self, $key) = @_;
   my $lkey=lc($key);

      if ($lkey eq 'authmethod')
        {
           CfgTie::filever::system("$groupmod -A DEFAULT $self->{name}");
        }
   elsif (exists $groupmod_opt->{$lkey})
        {
           #This is something for group mod!
           CfgTie::filever::system("$groupmod $self->{name} ".
		$groupmod_opt->{$lkey});
        }
   else
        {
           #Just remove our local copy
           delete $self->{$lkey};
        }
}


sub trx   {CfgTie::Cfgfile::trx(@_);}
sub table {CfgTie::Cfgfile::table(@_);}
sub HTML($)
{
   # A routine to HTMLize the user
   my $self=shift;

   my %Keys2 = map {$_,1} (keys %{$self});

   delete $Keys2{name};
   delete $Keys2{id};
   delete $Keys2{password};
   delete $Keys2{members};
   delete $Keys2{_members};
   #Members is dynamically computed...
   EXISTS($self, 'members');

   my $A='';
   foreach my $I (sort keys %Keys2)
    {$A.=trx($I,$self->{$I});}
   table($self->{name},
      trx("Name:",$self->{name}).
      trx("Id:",$self->{id}).
      trx("Members:",
	join(', ',
	   map {"<a href=\"user/$_\">$_</a>"} (sort @{$self->{'members'}})))
	.$A
    );
}

package CfgTie::TieGroup_file;
use CfgTie::Cfgfile;
@ISA=qw(CfgTie::Cfgfile);

sub files
{
   $self->{'Path'};
}

sub status
{
   # the information for the file
   stat $self->{'Path'};
}

sub scan
{
   my $self=shift;

   #Check to see what the path is
   if (!exists $self->{'Path'})
   {
      return;
   }

   my $F= new Secure::File "<".$self->{'Path'};
   return unless defined $F;

   while (<$F>)
   {
       #Chop of the comments
       s/\s*#.*$//;
       my @x = split /:/;
       if (@x && defined $x[0] && length $x[0])
         {
	    $self->{Contents}->{$x[0]}={
                 'name'   =>$x[0],
                 'passwd' =>$x[1],
                 'id'     =>$x[2],
                 'members'=>[split(/(?:\s+|\,)/, $x[3])]
              };
         }
   }

   $F->close;
}

sub format($$)
{
   "$_[1]: ".join(',',@{$_[1]})."\n";
}
