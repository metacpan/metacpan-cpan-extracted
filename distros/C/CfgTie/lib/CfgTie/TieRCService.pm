#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


package CfgTie::TieRCServ_rec;
use POSIX;
use CfgTie::filever;
use Secure::File;
my %ServScript;
1;

=head1 NAME

CfgTie::TieRCService -- A module to manage Unix services

=head1 SYNOPSIS

   my %RC;
   tie %RC, 'CfgTie::TieRCService';

=head1 DESCRIPTION

This is a straightforward interface to the control scripts in @file{/etc/rc?.d}
This package helps manage these system services.  The tie hash is structured
like so:

   {
       $Service_Name => $Service_Ref,
   }

C<$Service_Ref> is a hash reference; the details will be covered in the next
section.  C<(tied $Service_Ref)> can also be treated as an object to control
the service.  That is covered in the I<Service Methods> section.

While fetching from the structure, and deleting services is supported (and
reflected to the system), directly storing new services is not.  Currently
the method to do this is:

	(tied %RC)->add('mynewservice');

This will add the new service (to be managed as well as available) to the
run-levels.  The start and kill scripts will be linked into each appropriate
run-level.  The script should already exist (in the proper format) in
F</etc/rc.d/init.d> or equivalent.

=head2 The Service hash reference 

   {
      levels   => [], 
      defaults => [],
      category => [],
      pid  => $pid,
      path =>,
      description =>,
      start_priority=>,
      stop_priority =>,
   }

C<levels> refers to a list used to determine if the service is present for a
given run-level.
The scope of changes this list is I<system-wide>.  It is persistent across
boots.
Example:
    
    my $listref = (tied %{$RC{'atd'}})->levels();

    if ($L < scalar @{$listref} && $listref->[$L])
      {print "present at run level $L\n";}


=head2 Service Methods

C<new($service_name,$path)> I<path> is optional, and may refer either to the
folder containing the relevant control script, or may refer to the control
script itself.

C<start>  will start the service (if not already started).
The scope of this action is I<system-wide>.
Example: C<$Obj->E<gt>C<start();>


C<stop> will stop the service (if running).
The scope of this action is I<system-wide>.
Example: C<$Obj->E<gt>C<stop();>

C<restart> will restart the service, effectively stopping it (if it is
running) and then starting it.
The scope of this action is I<system-wide>.
Example: C<$Obj->E<gt>C<restart();>

C<status>
The scope of this action is limited to a single I<session>.

C<reload>
The scope of this action is I<system-wide>.

=head1 Caveats

This can not create a new service start/kill script.  At best this can only
modify an existing one, or link it into the init folders.

=head1 BUGS

Requires C</sbin/chkconfig> to work.

=head1 Author

Randall Maas (L<randym@acm.org>)


=cut

package CfgTie::TieRCService;

# Still need a tiehash, ability to add it to a run level, change its order
# in the runlevel, remove it from the runlevel

#All of the service name to information is stored in

sub scan ($)
{
   my $T= shift;
   my $F =CfgTie::filever::open("/sbin/chkconfig --list|");
   return unless $F;
   while (<$F>)
    {
	#We do this in the most flexible way we can think of... to allow for
	# future changes to chkconfig

	#Split the line up into its parts
	my ($Serv,@R) = split /\s+/;
	if (!$Serv) {next;}
	my @B=(0,0,0,0,0,0,0,0,0,0);
	
	#Scan each part into an explicit run-level (used as an index) and the
	#off/on which will be implicitly ignored 
	foreach my $I (@R)
        {if ($I=~/^(\d+):on/i) {$B[$1]=1;}}
	
	#Store
	tie %{$T->{$Serv}}, 'CfgTie::TieRCServ_rec', $Serv, \@B;
    }
   $F->close;
}

sub TIEHASH
{
   my $self=shift;
   my $Node={};
   #Currently requires chkconfig to work
   if (!-e "/sbin/chkconfig") {return;}
   return bless $Node, $self;
}

sub DELETE
{
   my $self=shift;
   my $key=shift;
   if (!exists $Services{$key}) {return;}
   CfgTie::Cfgfile::system("/sbin/chkconfig --del $key");
}

sub add
{
   my $self=shift;
   my $key =shift;
   CfgTie::filever::system("/sbin/chkconfig --add $key");
   scan(\%Services);
}

sub EXISTS ($$)
{
   my ($self,$key)=@_;
   return exists $Services{$key};
}

sub FETCH
{
   my $self=shift;
   my $key = shift;
   return $Services{$key};
}

sub trx {CfgTie::Cfgfile::trx(@_);}
sub table {CfgTie::Cfgfile::table(@_);}
sub num2chk($)
{
   my @Ret;
   foreach my $I (@{$_[0]})
    {
       if ($I) 
         {push @Ret, "<font face=\"Wingdings\">x</font>";}
        else
         {push @Ret, "<font face=\"Wingdings\"> </font>";}
    }
}

sub HTML ($)
{
    my $A="";
    foreach my $I (sort keys %Services)
     {$A.= trx("<a href=\"runlevel/$I\">$I</a>",@{$Services{$I}->{levels}});}

   table("Run levels",
   "<tr><th>Service</th><th>0</th><th>1</th><th>2</th><th>3</th><th>4</th>".
   "<th>5</th><th>6</th><th>7</th><th>8</th><th>9</th></tr>\n$A",11);
}

package CfgTie::TieRCServ_rec;

sub proc_sig($$)
{
   my $pid = proc_id($_[0]);

   if (defined $pid)
     {
        kill $_[1], $pid;
        return 1;
     }
    return -1;
}

sub scan_for_script($$)
{
   my ($serv, $path) = @_;
   $FNum++;
   opendir FNum, $path;
   my @RCfiles = grep {/^$serv$/} (readdir(FNum));
   closedir FNum;
   if (!scalar @RCfiles) {return;}
   my ($R) = @RCfiles;
   $R;
}

sub scan_rcscript($)
{
   my $self=shift;
   my $F = new Secure::File "<".$self->{'path'};
   while (<$F>)
    {
       if (/^\s*\#\s*chkconfig\s*:\s*(\d+)/i) 
         {
	    my @A=(0,0,0,0,0,0,0,0,0,0);
            for (my $I=0; $I< length $1; $I++)
             {$A[substr($1,$I,1)]=1;}
	    $self->{defaults}=\@A;
         }
       elsif (/^\s*\#\s*description\s*:\s*([^\s].*)$/i)
         {
	    my $A=$1;
	    #read the continuation in as neccessary
	    while ($A=~/\\\s*$/)
	     {
		$A=~s/\s*\\\s*$//;
	        my $B =<$F>;
	        if ($B=~/#\s*([^\s].*)$/i) {$A.=' '.$1;}
	     }
	    $self->{description}=$A;
         }
    }
   $F->close();
}

sub TIEHASH
{
   my ($self,$name,$levels)=@_;
   my $Node =
 	{
	    levels=>$levels,'name'=>$name,
	};

   return bless $Node, $self;
}

sub proc_id($)
{
   my $key = shift;

   if (!defined $key || !-e "/var/run/$key.pid") {return undef;}

   #use the canonically process ID
   my $F = new Secure::File "</var/run/$key.pid" or return undef;
   my ($I,$pid);
   while (<$F>)
    {
       if (/^(\d+)$/) {$pid=$1;}
    }
   $F->close;
   return $pid;
}

sub _stat($)
{
   my $self=shift;
   if (!defined $self) {return undef;}
   return stat("/var/run/".$self->{'name'}.".pid");
}

sub EXISTS ($$)
{
   my ($self,$key)=@_;
   my $lkey=lc($key);
   if (exists $self->{$lkey}) {return 1;}
   if ($lkey eq 'pid')
     {
        my $pid = proc_id($self->{'name'});
        if (defined $pid)
	  {
	      $self->{pid} =$pid;
	      return 1;
          }
     }
   elsif ($lkey eq 'path')
    {
       my $Path="/etc/rc.d/init.d/";
       my $A;
       if (-e $Path) {$A = scan_for_script($self->{'name'},$Path);}
       if (!defined $A)
	 {
	    $Path="/etc/init.d/";
            if (-e $Path) {$A = scan_for_script($self->{'name'},$Path);}
            if (!defined $A) {return 0;}
         }
       $self->{path}=$Path.'/'.$A;
       return 1;
    }
   elsif ($lkey eq 'description' || $lkey eq 'defaults')
    {
       if (!exists $self->{path}) {EXISTS($self,'path');}
       if (!exists $self->{path}) {return 0;}
       scan_rcscript($self);
       return exists $self->{$lkey};
    }
   elsif ($lkey eq 'stat')
     {
        my @A= _stat($self);
        if (scalar @A) {$self->{'stat'}=[@A]; return 1;}
     }
   return 0;
}

sub FIRSTKEY
{
    EXISTS($_[0],'pid');
   my $a = keys %{$_[0]};
   return scalar each %{$_[0]};
}

sub NEXTKEY
{return scalar each %{$_[0]};}

sub FETCH
{
   my ($self,$key)=@_;
   my $lkey =lc($key);
   if (EXISTS($self,$lkey)) {return $self->{$lkey};}
   undef;
}

sub trx   {CfgTie::Cfgfile::trx(@_);}
sub table {CfgTie::Cfgfile::table(@_);}
sub HTML ($)
{
   my $self=shift;
   #Levels it currently is in
   #Description
    EXISTS($self, 'description');
   #Defaults
    EXISTS($self, 'defaults');
   #Name
   #Process Id
    EXISTS($self, 'pid');
    EXISTS($self, 'stat');

   #Set up the current run levels and their default settings:
   my $A= table(undef,
		trx('Levels:',@{$self->{levels}}).
		trx('Defaults:', @{$self->{defaults}}),
		10);

   table("Run levels",
   "<tr><th>Service</th><th>0</th><th>1</th><th>2</th><th>3</th><th>4</th>".
   "<th>5</th><th>6</th><th>7</th><th>8</th></tr>\n$A",10);

   my $B='';
   if (exists $self->{'pid'}) {$B.= trx("Process Id:", $self->{'pid'});}
   if (exists $self->{'stat'})
     {
	$B.= trx("Started on:",
		POSIX::strftime("%a %b %e %H:%M:%S %Y",
				localtime($self->{'stat'}->[9])));
     }
   
   table($self->{'name'},
	 trx("Name:",       $self->{'name'}).
	 trx("Description:",$self->{'description'}).
	 trx("Run Levels",  $A). #Insert both tables there 
	 $B
	 );
}

sub STORE ($$)
{
   my ($self,$key,$value)=@_;

   if (lc($key) ne 'level') {return;}

   #Identify the run levels that were enabled
   my $A;
   my $J=0;
   foreach my $I (@{$value})
   {
      if ($I == 0 || $self->{levels}->[$J] != 0 || $J >9) {$J++; next;}
      $A.=$J;
      $J++;
   }

   #Identify the run levels that were disabled
   my $B;
   $J=0;
   foreach my $I (@{$value})
   {
      if ($I != 0 || $self->{levels}->[$J] == 0|| $J >9) {$J++; next;}
      $B.=$J;
      $J++;
   }

   #Now commit theses.. First add it to some levels.
   if (defined $A && $A && length $A)
   {
     CfgTie::Cfgfile::system("/sbin/chkconfig --level $A ".$self->{'name'}.
			     " on");
   }

   #Next remove it from some levels.
   if (defined $B && $B && length $B)
   {
     CfgTie::Cfgfile::system("/sbin/chkconfig --level $B ".$self->{'name'}.
			     " off");
   }
}

sub newt
{
   my ($self,$serv,$path) = @_;

   if (!defined $serv) {return bless $node, $self;}
   if (defined $path)
     {
        #if the path is bad, just let it be there, but invalid..
        #Or if it points to a real file...
        if (!-e $path || !-d $path)
          {
             #The user specified a file; take the user at his word
             $node->{Path}=$path;
             return bless $node, $self;
          }

        if (-e "$path/$serv")
          {
             $node->{Path}="$path/$serv";
             return bless $node, $self;
          }

        if (-e "$path$serv")
          {
             $node->{Path}="$path$serv";
             return bless $node, $self;
          }

        my $R = scan_for_script $serv, $path;
        if (defined $R) {$node->{Path}=$R;}

        return bless $node, $self;
     }

   if (!exists $ServScript{$serv})
     {
        if (-e "/etc/rc.d/init.d/$serv")
          {$ServScript{$serv} = "/etc/rc.d/init.d/$serv";}
         else
          {
             my $RCBase;
                if (-d "/etc/rc2.d/")
                  {$RCBase = "/etc/rc2.d/";}
             elsif (-d "/etc/rc.d/rc2.d")
                  {$RCBase = "/etc/rc.d/rc2.d/";}
             else {return bless $node, $self;}

             my $R = scan_for_script $serv, $RCBase;
             if ($R) {$ServScript{$serv} = $R;}
          }
      }

   if (exists $ServScript{$serv}) {$node->{Path} = $ServScript{$serv};}
   return bless $node,$self;
}

BEGIN
{
   #basically create the various verbs... 
   my $X="package CfgTie::TieRCServ_rec;\n";

   foreach my $I ('start','stop','restart', 'status')
    {
       $X.= "sub $I(\$)\n{\n".
            "   my \$self = shift;\n".
	    "   delete \$self->{pid};\n".
	    "   delete \$self->{'stat'};\n".
            "   if (exists \$self->{path})\n".
            "     {return system(\$self->{path}.\" $I\");}\n".
            "}\n\n";
    }
   eval $X;
}

sub reload($)
{
   my $self=shift;
   delete $self->{pid};
   delete $self->{status};
   if (-x "/usr/sbin/".$self->{'name'}.".reload")
     {
        return system("/usr/sbin/".$self->{'name'}.".reload");
     }
    else
     {
        #Get its pid
        if (proc_sig($self->{'name'}, 'HUP') == -1)
          {
             restart $self;
          }
     }
}

package CfgTie::TieRCService;
use CfgTie::filever;
use Secure::File;
my %Services;
scan (\%Services);
1;
