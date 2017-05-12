#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


package CfgTie::TieShadow;
use CfgTie::filever;

=head1 NAME

CfgTie::TieShadow -- an associative array of user names to password information

=head1 SYNOPSIS

This module makes the shadow database available as a regular hash.

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the shadow
password database sanely.

=head2 Ties

This tie is available for programmers:

C<tie %shadow,'CfgTie::TieShadow'>

C<$shadow{$name}> will return a hash reference of the named shadow information


=head2 Structure of hash

Any given shadow entry has the following information associated with it (the
keys are case-insensitive):

=over 1

=item C<Name>

Login name

=item C<Password>

The encrypted password

=item C<Last>

Last time it was changed

=item C<Min>

The minimum number of days before a change is allowed

=item C<Max>

Maximum number of days before a change in passwords is required

=item C<Warn>

The number of days before expiration that they will receive a warning

=item C<Inactive>

The number of days before an account is inactive

=item C<Expires>

The date the account expires on

=item C<Inactive>

The number of days after a password expires that the account is considered
inactive and expires

=back

Each of these entries can be modified (even deleted), and they will be
reflected in the overall system.  Additionally, the programmer can set any
other associated key, but this information will only available to the running
Perl script.

=head2 Additional Routines

=over 1

=item C<&CfgTie::TieShadow'status()>

=item C<&CfgTie::TieShadow_id'status()>

Will return C<stat> information on the shadow database.

=back

=head2 Miscellaneous

C<$CfgTie::Tiehadow_rec'usermod> contains the path to the program F<usermod>.
This can be modified as required.

C<$CfgTie::TieShadow_rec'useradd> contains the path to the program F<useradd>.
This can be modified as required.

C<$CfgTie::TieShadow_rec'userdel> contains the path to the program F<userdel>.
This can be modified as required.

=head1 Files

F</etc/passwd>
F</etc/group>
F</etc/shadow>


=head1 See Also

L<CfgTie::Cfgfile>,  L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,
L<CfgTie::TieHost>,  L<CfgTie::TieNamed>,  L<CfgTie::TieNet>,
L<CfgTie::TiePh>,    L<CfgTie::TieProto>,  L<CfgTie::TieServ>,
L<CfgTie::TieShadow>, L<CfgTie::TieUser>

L<group(5)>,
L<passwd(5)>,
L<shadow(5)>,
L<usermod(8)>,
L<useradd(8)>,
L<userdel(8)>

=head1 Caveats

The current version does cache some shadow information.

=head1 Author

Randall Maas (L<randym@acm.org>)

=cut

my $Chg_FS = 1; #By default we want to update the file system when the shadow
# Id changes

sub status
{
  # the information for the /etc/shadow file
  stat '/etc/shadow';
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
   setpwent;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next shadow id in the database.
   # Get the information from the system and store it for later
   my @x = getpwent;
   if (! scalar @x) {return;}

   &CfgTie::TieShadow_rec'TIEHASH(0,@x);
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = @_;
   my $lname =lc($name);
   if (exists $CfgTie::TieShadow_rec'by_name{$lname}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getpwnam $name;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieShadow_rec'by_name{$lname}}, 'CfgTie::TieShadow_rec',@x;
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   if (!defined $name) {return;}

   my $lname = lc($name);

   #check out our cache first
   if (&EXISTS($self,$lname)) {return $CfgTie::TieShadow_rec'by_name{$lname};}
}

#Bug creating shadows is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   shadowadd or shadowmod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my $self = shift;
   my $name = shift;

   #Basically delete the shadow now.
   system "$CfgTie::TieShadow_rec'shadowdel $name";

   #Remove it from our cache
   if (exists $CfgTie::TieShadow_rec'by_name{$name})
     {delete $CfgTie::TieShadow_rec'by_name{$name};}
}

package CfgTie::TieShadow_id;

sub status
{
  # the information for the /etc/shadow file
  stat '/etc/shadow';
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
   setpwent;

   &NEXTKEY($self);
}

sub NEXTKEY
{
   my $self = shift;

   #Get the next shadow id in the database.
   # Get the information from the system and store it for later
   my @x = getpwent;
   if (! scalar @x) {return;}

   &CfgTie::TieShadow_rec'TIEHASH(0,@x);
   return $x[2]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$id) = @_;
   if (exists $CfgTie::TieShadow_rec'by_id{$id}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getpwuid $id;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieShadow_rec'by_name{$x[0]}}, 'CfgTie::TieShadow_rec',@x;
   $CfgTie::TieShadow_rec'by_id{$id} = $CfgTie::TieShadow_rec'by_name{$x[0]};
   return 1;
}

sub FETCH
{
   my ($self,$id) = @_;

   #check out our cache first
   if (&EXISTS($self,$id)) {return $CfgTie::TieShadow_rec'by_id{$id};}
}

#Bug creating shadows is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   shadowadd or shadowmod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my ($self,$id) = @_;

   if (!exists $CfgTie::TieShadow_rec'by_id{$id})
     {
        #Try to look up the shadow id
        &FETCH($self,$id);
     }
      
   if (exists $CfgTie::TieShadow_rec'by_id{$id})
     {
        #Basically delete the shadow now.
        system "$CfgTie::TieShadow_rec'shadowdel $CfgTie::TieShadow_rec'by_id{$id}->{Name}";

        #Remove it from out cache
        delete $CfgTie::TieShadow_rec'by_id{$id};
     }
}



package CfgTie::TieShadow_rec;
# A package used by both shadow_id and shadow to retain record information about
# a person.  This is the only way to access shadowmod.

#Two hashes are used for look up
# $by_name{$name}
# $by_id{$id}

sub TIEHASH
{
   # Ties a single shadow to a register...
   my ($self,$Name,@Rest) = @_;
   my $Node;
   my $lname = lc($Name);

   if (scalar @Rest)
     {
        ($Node->{password},$Node->{id},   $Node->{groupid},
         $Node->{quota}, $Node->{comment}, $Node->{gcos}, $Node->{home},
         $Node->{shell}) = @Rest;
     }

   if (defined $Name)    {$Node->{name}=$Name;}

   return bless $Node, $self;
}

sub FIRSTKEY
{
   my $self = shift;
   my $a = keys %{$self};
   return scalar each %{$self};
}

sub NEXTKEY
{
   my $self = shift;
   return scalar each %{$self};
}

sub scan_lasts
{
   #Get the last time the read their email

   my $L = new Secure::File "</var/log/maillog";
   while (<$L>)
    {
       if(/([\d\w\s:]+)\s\w+\s\w+\[\d+\]:\sLogout\sshadow\s(\w+).*/)
           {$Last{lc($2)} = $1;}
     }

   $L->close;
}

sub EXISTS
{
   my ($self,$key) = @_;
   my $lkey=lc($key);

   if ($lkey eq 'last' && !exists $self->{'last'})
     {
        #Try to recover it from our shadow, but avoid scanning the last
        #file if we can -- it takes a *long* time
        if (!exists $Last{lc($self->{name})} && !defined $scanned_last)
          {
             &scan_lasts();
             $scanned_last=1;
          }
        if (exists $Last{lc($self->{name})})
          {$self->{'last'} = $Last{lc($self->{name})};}
     }
   return exists $self->{$lkey};
}

sub FETCH
{
   my $self = shift;
   my $key = shift;
   my $lkey = lc($key);

   if ($lkey eq 'priority')
     {
        #Get the priority setting from the system
        return getpriority PRIO_shadow,$self->{Node}->{Id};
     }
   elsif ($lkey eq 'last' && !exists $self->{$lkey}) {&EXISTS($self,$lkey);}

   if (exists $self->{$lkey}) {return $self->{$lkey};}
}

# Maps the changes to a particular setting to a flag on the command line
my $shadowmod_opt =
 {
   comment => '-c',
   home    => '-d',
   expire  => '-e',
   inactive=> '-f',
   name    => '-l',
   shell   => '-s',
   group1  => '-g',
   groups  => '-G',
   id      => '-u',
 };

my $shadowmod_opt2 =
 {
   id      => '-o',
 };

my $shadowmod = '/usr/sbin/shadowmod';  #Hard path to shadowmod
my $shadowdel = '/usr/sbin/shadowdel';  #Hard path to shadowdel

sub STORE
{
   # Changes a setting for the specified shadow... we basically call shadowmod
   my ($self,$key,$val) = @_;
   my $lkey = lc($key);

   if ($lkey eq 'groups')
     {
        #Handle the groups thing...

        #$val is a list reference....
        my ($i,@g) = @{$val};

        system "$shadowmod $self->{name} -g $i -G ". join(',', @g);
     }
   elsif (exists $shadowmod_opt->{$lkey})
     {
        #This is something for shadow mod!
        my ($FSUp, @FSet)=(0);

        if (defined $CfgTie::TieShadow'Chg_FS && $shadow'Chg_FS == 1 &&
            $lkey eq 'id')
          {
             #We are supposed to change all of the files in the system to
             #have the new new one.
             #We have a race condition: someone else may change soemthing in
             #the file system, so we may not get everything, but we try to
             #be reasonable

             # Now we need to identify all of the files.. this may take a
             # long time
             @FSet= &CfgTie::filever'find_by_user ('/', $self->{id});

             if (@FSet && scalar @FSet) {$FSUp = 1;}
          }

        my $X = $shadowmod_opt2->{$lkey};
        if (!defined $X) {$X='';}

        #Change the system tables
        system "$shadowmod ".$shadowmod_opt->{$lkey}." $val $X ".$self->{name}.
                "\n";
        #If bad things should throw exception

        if ($FSUp) {chown $val,-1, @FSet;}

        $self->{$lkey} = $val;
     }
    else
     {
        #Extra setting that will be lost... 8(
        $self->{$lkey}=$val;
     }
}

sub DELETE
{
   #Deletes a shadow setting
   my ($self, $key) = @_;
   my $lkey=lc($key);

      if ($key eq 'authmethod')
        {
           system "$shadowmod -A DEFAULT ".$self->{name};
        }
   elsif (exists $shadowmod_opt->{$key})
        {
           #This is something for shadow mod!
           system "$shadowmod ".$shadowmod_opt->{$lkey}." ".$self->{name};
        }
   else
        {
           #Just remove our local copy
           delete $self->{$lkey};
        }
}


