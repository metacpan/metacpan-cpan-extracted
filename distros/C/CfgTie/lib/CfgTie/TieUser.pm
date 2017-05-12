#!/usr/bin/perl -Tw
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


package CfgTie::TieUser;
require CfgTie::filever;
require CfgTie::Cfgfile;
require Secure::File;

=head1 NAME

CfgTie::TieUser -- an associative array of user names and ids to information

=head1 SYNOPSIS

makes the user database available as a regular hash.

        tie %user,'CfgTie::TieUser'
        print "randym's full name: ", $user{'randym'}->{gcos}, "\n";

=head1 DESCRIPTION

This is a straightforward hash tie that allows us to access the user database
sanely.

It cross ties with the groups packages and the mail packages

=head2 Ties

There are two ties available for programmers:

=over 1

=item C<tie %user,'CfgTie::TieUser'>

C<$user{$name}> will return a hash reference of the named user information.

=item C<tie %user_id,'CfgTie::TieUser_id'>

C<$user_id{$id}> will return a hash reference for the specified user.

=back

=head2 Structure of hash

Any given user entry has the following information associated with it (the
keys are case-insensitive):

=over 1

=item C<Name>

Login name

=item C<GroupId>

The principle group the user belongs to.

=item C<Id>

The user id number that they have been assigned.  It is possible for many
different user names to be given the same id.  However, changing the id for
the user (i.e., setting it to a new one) has one of two effects.  If
C<user'Chg_FS> is set 1, then all the files in the system owned by that id
will changed to the new id in addition to changing the id in the system table.
Otherwise, only the system table will be modified.

=item C<Comment>

=item C<Home>

The user's home folder

=item C<LOGIN_Last>

This is the information from the last time the user logged in.  It is an
array reference to data like:

        [$time, $line, $from_host]

=item C<Shell>

The user's shell

=item C<AuthMethod>

The authentication method if other than the default.  (Note: This can be set,
but currently can't get fetched.)

=item C<ExpireDate>

The date the account expires on.
(Note: this can be set, but currently can't be fetched.)

=item C<Inactive>

The number of days after a password expires.
(Note: this can be set, but currently can't be fetched.)

=item C<Priority>

The scheduling priority for that user.
(Note: this requires that C<BSD::Resource> be installed.)

=item C<Quota>

=item C<RUsage>

The process resource consumption by the user.
Note: This requires that C<BSD::Resource> be installed.

Returns a list reference of the form:

   [$usertime, $systemtime, $maxrss,  $ixrss,   $idrss,  $isrss,  $minflt,
    $majflt,   $nswap,      $inblock, $oublock, $msgsnd, $msgrcv, $nsignals,
    $nvcsw, $nivcsw]

=back


Plus two (probably) obsolete fields:

=over 1

=item C<Password>

This is the encrypted password, but will probably be obsolete.

=item C<GCOS>

I<General Electric Comprehensive Operating System> or
I<General Comprehensive Operating System>
field

This is now the user's full name under many Unix's, incl. Linux.

=back

Each of these entries can be modified (even deleted), and they will be
reflected in the overall system.  Additionally, the programmer can set any
other associated key, but this information will only be available to the
running Perl script.

=head2 Configuration Variables

=head2 Additional Routines

=over 1

=item C<&CfgTie::TieUser'stat()>

=item C<&CfgTie::TieUser_id'stat()>

Will return C<stat>-like statistics information on the user database.

=back

=head2 Adding or overiding methods for user records

Lets say you wanted to change the default HTML handling to a different method.
To do this you need only include code like the following:

   package CfgTie::TieUser_rec;
   sub HTML($)
   {
      my $self=shift;
      "<h1>".$Self->{name}."</h1>\n".
      "<table border=0><tr><th align=right>\n".
        join("</td></tr>\n<tr><th align=right>",
          map {$_."</th><td>".$self->{$_}} (sort keys %{$self})
       </td></tr><lt></table>C<\n>";
   }

If, instead, you wanted to add your own keys to the user records, 
C<CfgTie::TieUser::add_scalar(>I<$Name>,I<$Package>C<)>
Lets you add scalar keys to user records.  The I<Name> specifies the key name
to be used; it will be made case-insensitve.  The I<Package> specifies the name
of the package to be used when tie'ing the key to a value.  (The C<TIESCALAR>
is passed the user id as a parameter).

C<CfgTie::TieUser::add_hash(>I<$Name>,I<$Package>C<)>
Lets you add hash keys to user records.  The I<Name> specifies the key name
to be used; it will be made case insensitve.  The I<Package> specifies the name
of the package to be used when tie'ing the key to a value.  (The C<TIEHASH>
is passed the user id as a parameter).

=head2 Miscellaneous

C<$CfgTie::TieUser_rec'usermod> contains the path to the program F<usermod>.
This can be modified as required.

C<$CfgTie::TieUser_rec'useradd> contains the path to the program F<useradd>.
This can be modified as required.

C<$CfgTie::TieUser_rec'userdel> contains the path to the program F<userdel>.
This can be modified as required.

Not all keys are supported on all systems.

This may transparently use a shadow tie in the future.

=head2 When the changes are reflected to /etc/passwd

=head1 Files

F</etc/passwd>
F</etc/group>
F</etc/shadow>

=head1 See Also

L<CfgTie::Cfgfile>, L<CfgTie::TieAliases>,  L<CfgTie::TieGeneric>,
L<CfgTie::TieGroup>,L<CfgTie::TieHost>,     L<CfgTie::TieMTab>,
L<CfgTie::TieNamed>,L<CfgTie::TieNet>,      L<CfgTie::TiePh>,
L<CfgTie::TieProto>,L<CfgTie::TieRCService>,L<CfgTie::TieRsrc>,
L<CfgTie::TieServ>, L<CfgTie::TieShadow>

L<group(5)>,
L<passwd(5)>,
L<shadow(5)>,
L<usermod(8)>,
L<useradd(8)>,
L<userdel(8)>

=head1 Caveats

The current version does cache some user information.

=head1 Author

Randall Maas (L<randym@acm.org>)

=cut

my $Chg_FS = 1; #By default we want to update the file system when the user
# Id changes

sub stat($)
{
  # the information for the /etc/passwd file
  stat '/etc/passwd';
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

   #Get the next user id in the database.
   # Get the information from the system and store it for later
   my @x = getpwent;
   if (!scalar @x) {return;}

   &CfgTie::TieUser_rec'TIEHASH(0,@x);
   return $x[0]; #Corresponds to the name
}

sub EXISTS
{
   my ($self,$name) = @_;
   my $lname =lc($name);
   if (exists $CfgTie::TieUser_rec'by_name{$lname}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getpwnam $name;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieUser_rec'by_name{lc($x[0])}}, 'CfgTie::TieUser_rec',@x;
   return 1;
}

sub FETCH
{
   my ($self, $name) = @_;

   if (!defined $name) {return;}

   my $lname = lc($name);

   #check out our cache first
   if (EXISTS($self,$lname))
     {return $CfgTie::TieUser_rec'by_name{$lname};}
}

#Bug creating users is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   useradd or usermod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my $self = shift;
   my $name = shift;

   #Basically delete the user now.
   CfgTie::filver::system("$CfgTie::TieUser_rec'userdel $name");

   #Remove it from our cache
   if (exists $CfgTie::TieUser_rec'by_name{$name})
     {delete $CfgTie::TieUser_rec'by_name{$name};}
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
		"<a href=\"user/$I\">$I</a>",
		$U->{'gcos'},
		"<a href=\"mailto:$I\">$I</a>"
		);
    }
   my $Us;
   foreach my $I (sort keys %A) {$Us.=$A{$I};}
   CfgTie::Cfgfile::table('Users',
	"<th class=\"cfgattr\">login</th><th class=\"cfgattr\">Full Name</th>".
	 "<th class=\"cfgattr\">mailto:</th></tr>\n".$Us, 3);
}

sub add_scalar($$)
{
   my ($name,$package) =@_;
   $name=lc($name);
   $CfgTie::TieUser_rec::SDelegates->{$name}=$package;
}

sub add_hash($$)
{
   my ($name,$package) =@_;
   $name=lc($name);
   $CfgTie::TieUser_rec::HDelegates->{$name}=$package;
}

package CfgTie::TieUser_id;

sub status
{
  # the information for the /etc/passwd file
  stat '/etc/passwd';
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

   #Get the next user id in the database.
   # Get the information from the system and store it for later
   my @x = getpwent;
   if (! scalar @x) {return;}

   &CfgTie::TieUser_rec'TIEHASH(0,@x);
   return $x[2]; #Corresponds to the id
}

sub EXISTS
{
   my ($self,$id) = @_;
   if (exists $CfgTie::TieUser_rec'by_id{$id}) {return 1;}

   # Get the information from the system and store it for later
   my @x = getpwuid $id;
   if (! scalar @x) {return 0;}

   tie %{$CfgTie::TieUser_rec'by_name{lc($x[0])}}, 'CfgTie::TieUser_rec',@x;
   $CfgTie::TieUser_rec'by_id{$id} = $CfgTie::TieUser_rec'by_name{$x[0]};
   return 1;
}

sub FETCH
{
   my ($self,$id) = @_;

   #check out our cache first
   if (EXISTS($self,$id)) {return $CfgTie::TieUser_rec'by_id{$id};}
}

#Bug creating users is not supported yet.
sub STORE
{
   my ($self,$key,$val) = @_;
#   useradd or usermod, depending
}

#Bug need to consider how vigorously we delete things -r ? /var/mail/me, etc
sub DELETE
{
   my ($self,$id) = @_;

   if (!exists $CfgTie::TieUser_rec'by_id{$id})
     {
        #Try to look up the user id
        FETCH($self,$id);
     }
      
   if (exists $CfgTie::TieUser_rec'by_id{$id})
     {
        #Basically delete the user now.
        CfgTie::filever::system
	 ("$CfgTie::TieUser_rec'userdel $CfgTie::TieUser_rec'by_id{$id}->{Name}");

        #Remove it from out cache
        delete $CfgTie::TieUser_rec'by_id{$id};
     }
}



package CfgTie::TieUser_rec;
# A package used by both user_id and user to retain record information about
# a person.  This is the only way to access usermod.

#Two hashes are used for look up
# $by_name{$name}
# $by_id{$id}

#Delegate keys
# This are looked up by a delegate system that we basically add on
my $HDelegates={};
my $SDelegates={};

#Extended keys
my $EKeys = {'last'=>[],login_last=>[]};

sub new {&TIEHASH(@_);}

sub TIEHASH
{
   # Ties a single user to a register...
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

   #Add in the delegates
   foreach my $I (keys %{$HDelegates})
   {tie %{$Node->{$I}}, $HDelegates->{$I}, $Node->{id};}
   foreach my $I (keys %{$SDelegates})
   {tie $Node->{$I}, $SDelegates->{$I}, $Node->{id};}

   return bless $Node, $self;
}

sub FIRSTKEY
{
   my $self = shift;
   my $a = keys %{$self};
   NEXTKEY($self,undef);
}

sub NEXTKEY ($$)
{
   my ($self,$prev) = @_;
   my $a = scalar each %{$self};
   if ($a) {return $a;}

###The following is busted

   #Should also return something from the extended keys if not already set.
   #if (!exists $EKeys->{$prev}) {my $a = keys %{$EKeys};}
   #while ($a = scalar each %{$EKeys})
   # {
   #    if (exists $self->{$a}) {next;}
   #    return $a;
   # }
   return $a;
}

#Modified from PERL Cookbook:
my $lastlog_fmt="L a16 A16"; #on sunos "L A8 A16"
sub lastlog_FETCH($)
{
   use User::pwent;
   use IO::Seekable qw(SEEK_SET);

   my $LASTLOG= new Secure::File "</var/log/lastlog";
   return unless defined $LASTLOG;

   my $User = shift;
   my $U = ($User =~ /^\d+$/) ? getpwuid($User) : getpwnam($User);
   if (!$U) {goto ret_from_here;}

   my $R;
   my $sizeof = length(pack($lastlog_fmt,()));
   if ($LASTLOG->seek($U->uid + $sizeof,SEEK_SET) &&
       $LASTLOG->read($buffer, $sizeof) == $sizeof)
     {
        #time line host
        $R = [unpack($lastlog_fmt, $buffer)];
     }

  ret_from_here:
   $LASTLOG->close;
   $R;
}

sub scan_lasts
{
   #Get the last time the read their email
   my $L = new Secure::File "</var/log/maillog";
   while (<$L>)
    {
       if(/([\d\w\s:]+)\s\w+\s\w+\[\d+\]:\sLogout\suser\s(\w+).*/)
           {$Last{lc($2)} = $1;}
     }

   $L->close;
}

sub EXISTS
{
   my ($self,$key) = @_;
   my $lkey=lc($key);

   #first, check to see if it is a forbidden key
   if ($lkey eq 'delegate') {return 0;}

   #Next, check the delegates
   if (exists $self->{delegate}->{$lkey}) {return 1;}

   #otherwise check the rest
      if ($lkey eq 'login_last' && !exists $self->{'login_last'})
        {
           my $R = lastlog_FETCH($self->{name});
           if (undef $R) {return 0;}
           $self->{'login_last'} = $R;
        }
   elsif ($lkey eq 'last' && !exists $self->{'last'})
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
   my ($self,$key) = @_;
   my $lkey = lc($key);

   #Check the delegated stuff
   if (exists $self->{delegate}->{$lkey})
     {return $self->{delegate}->{$lkey}->FETCH($key);}

   if (!exists $self->{$lkey}) {EXISTS($self,$lkey);}

   if (exists $self->{$lkey}) {return $self->{$lkey};}
}

# Maps the changes to a particular setting to a flag on the command line
my $usermod_opt =
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

my $usermod_opt2 =
 {
   id      => '-o',
 };

my $usermod = '/usr/sbin/usermod';  #Hard path to usermod
my $userdel = '/usr/sbin/userdel';  #Hard path to userdel

sub STORE
{
   # Changes a setting for the specified user... we basically call usermod
   my ($self,$key,$val) = @_;
   my $lkey = lc($key);

   #Check the delegated stuff
   if (exists $self->{delegate}->{$lkey})
     {return $self->{delegate}->{$lkey}->STORE($key,$val);}

   if ($lkey eq 'groups')
     {
        #Handle the groups thing...

        #$val is a list reference....
        my ($i,@g) = @{$val};

        CfgTie::filever::system("$usermod $self->{name} -g $i -G ". join(',', @g));
     }
   elsif (exists $usermod_opt->{$lkey})
     {
        #This is something for user mod!
        my ($FSUp, @FSet)=(0);

        if (defined $user'Chg_FS && $user'Chg_FS == 1 && $lkey eq 'id')
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

        my $X = $usermod_opt2->{$lkey};
        if (!defined $X) {$X='';}

        #Change the system tables
        CfgTie::filever::system("$usermod ".$usermod_opt->{$lkey}." $val $X ".
			$self->{name}."\n");
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
   #Deletes a user setting
   my ($self, $key) = @_;
   my $lkey=lc($key);

      if ($lkey eq 'authmethod')
        {
           CfgTie::filever::system("$usermod -A DEFAULT ".$self->{name});
        }
   elsif (exists $usermod_opt->{$lkey})
        {
           #This is something for user mod!
           CfgTie::filever::system("$usermod ".$usermod_opt->{$lkey}." ".
		$self->{name});
        }
   else
        {
           #Just remove our local copy
           delete $self->{$lkey};
        }
}

sub trx {CfgTie::Cfgfile::trx(@_);}

sub HTML($)
{
   # A routine to HTMLize the user
   my $self=shift;

   my %Keys2 = map {$_,1} (keys %{$self});
   $Keys2{'last'}=1;

   delete $Keys2{gcos};
   delete $Keys2{name};
   delete $Keys2{id};
   delete $Keys2{groupid};
   delete $Keys2{password};
   my ($G) = getgrgid($self->{groupid});
   my $A='';
   foreach my $I (sort keys %Keys2) {$A.=trx($I,$self->{$I});}

   CfgTie::Cfgfile::table($self->{gcos},
     trx("Full Name:",  $self->{gcos}).
     trx("Login (UID):",$self->{name}." (".$self->{id}.")").
     trx("Group (GID):","<a href=\"group/$G\">".$G."</a> (".
	$self->{groupid}.")").$A);
}

## --- Support for optional user prioritization --------------------------------
package CfgTie::TieUser_priority;
if (eval("use BSD::Resource;"))
  {
     #Add the BSD stuff in
     $CfgTie::TieUser_rec::SDelegate{'priority'}='CfgTie::TieUser_priority';
     $CfgTie::TieUser_rec::SDelegate{'rusage'}='CfgTie::TieUser_rusage';
  }
      
sub TIESCALAR
{return bless {id=>$_[1]}, $_[0];}

sub FETCH
{
   #Get the priority setting from the system
   getpriority(PRIO_USER,$_[0]->{id});
}

sub STORE
{
   my ($self,$val)=@_;

   #Pass the priority setting onto the system
   setpriority(PRIO_USER,$self->{id},$val);
}

## --- Support for optional user resources -------------------------------------
package CfgTie::TieUser_rusage;
sub TIEHASH
{return bless {id=>$_[1]}, $_[0];}

#Get the consumption data from the system
sub FETCH { [getrusage($_[0]->{id})]; }

## --- Support for optional Quotas --------------------------------------------
package CfgTie::TieUser_quota;
#This part attempts to tie in the quota package.  It is not guaranteed to
#succeed.  Quota from CPAN is recommended because of its completenes of API
#and broad range of platforms supported.

if (eval("use Quota;"))
  {
     #Add the quota stuff in
     $CfgTie::TieUser_rec::HDelegate{'usage'}='CfgTie::TieUser_quota_usage';
     $CfgTie::TieUser_rec::HDelegate{'limits'}='CfgTie::TieUser_quota_limits';
     $CfgTie::TieUser_rec::HDelegate{'timeleft'}='CfgTie::TieUser_quota_timeleft';
    }

my $DB={usage=>{},timeleft=>{},limits=>{}};
1;

sub Query($$)
{
   #A wrapper around the Quota::query routine... converts into our internal
   #usage form

   my ($uid,$dev) = @_;

   #Get the information
   my ($Block_Curr, $Block_Soft, $Block_Hard, $Block_TimeLeft,
       $INode_Curr, $INode_Soft, $INode_Hard, $INode_TimeLeft) =
	 Quota::query($dev,$uid);


   #Now store it in a form we can use
   $DB->{usage}->   {$uid}->{$dev} =[$Block_Curr,    $INode_Curr];
   $DB->{timeleft}->{$uid}->{$dev} =[$Block_TimeLeft,$INode_TimeLeft];
   $DB->{limits}->  {$uid}->{$dev} =[$Block_Soft,$Block_Hard,$INode_Soft,$INode_Hard];
}

sub Exists ($$$)
{
   my($self,$key,$path) = @_;

   #Convert the path into q form that can be used in a query
   #(The representation will vary with each system)
   my $dev = Query::getqcarg($key);

   if (!exists $DB->{$key}->{$self->{uid}}->{$dev})
      {Query($self->{uid},$dev);}
   
   return exists $DB->{$key}->{$self->{uid}}->{$dev};
}

sub Fetch ($$$)
{
   my($self,$key,$path) = @_;

   #Convert the path into q form that can be used in a query
   #(The representation will vary with each system)
   my $dev = Query::getqcarg($key);

   if (!exists $DB->{$key}->{$self->{uid}}->{$dev})
      {Query($self->{uid},$dev);}
   

   if (exists $DB->{$key} && exists $DB->{$key}->{$self->{uid}}->{$dev})
   {
       return $DB->{$key}->{$self->{uid}}->{$dev};
   }
   undef;
}

package CfgTie::TieUser_quota_limits;
sub new(@_)     {TIEHASH(@_);}
sub TIEHASH     {return bless {uid=>$_[1]}, $_[0];}
sub EXISTS ($$) {CfgTie::TieUser_quota::Exists($_[0],'limits',$_[1]);}
sub FETCH ($$)  {CfgTie::TieUser_quota::Fetch($_[0],'limits',$_[1]);}

sub STORE ($$)
{
   my ($self,$key,$val)=@_;

   #Convert the path into q form that can be used in a query
   #(The representation will vary with each system)
   #The key is the path
   my $dev = Query::getqcarg($key);
  
   #clear out the keys
   delete $limits{$self->{uid}};

   Quota::setqlim($dev, $self->{uid}, @{$val});
}

package CfgTie::TieUser_quota_usage;
sub new(@_)     {TIEHASH(@_);}
sub TIEHASH     {return bless {uid=>$_[1]}, $_[0];}
sub EXISTS ($$) {CfgTie::TieUser_quota::Exists($_[0],'usage',$_[1]);}
sub FETCH ($$)  {CfgTie::TieUser_quota::Fetch ($_[0],'usage',$_[1]);}

package CfgTie::TieUser_quota_timeleft;
sub new(@_)     {TIEHASH(@_);}
sub TIEHASH     {return bless {uid=>$_[1]}, $_[0];}
sub EXISTS ($$) {CfgTie::TieUser_quota::Exists($_[0],'timeleft',$_[1]);}
sub FETCH ($$)  {CfgTie::TieUser_quota::Fetch ($_[0],'timeleft',$_[1]);}

package CfgTie::TieUser_file;
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
