#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.


=head1 NAME

C<CfgTie::TieNamed> -- A tool to help configure the name daemon (BIND DNS server)

=head1 SYNOPSIS

This is a PERL module to help make it easy to configure the DNS name server

=head1 DESCRIPTION

This is a tie hash to the NAMED configuration files.  You use it as follows:

   tie %named, 'CfgTie::TieNamed','/path/to/named.boot';
   $named = CfgTie::TieNamed->new('/path/to/named.boot');

These will set up a hash (I<named>) to the named configuration files.  It will
used the specified F<named.boot> file.

   tie %named, 'CfgTie::TieNamed';
   $named = CfgTie::TieNamed->new();

These will set up a hash (I<named>) to the named configuration files.  The
files will be automatically determined from the system startup scripts.

=head2 Examples

Lets say you would like to name a bunch of machines (like modems) with a base
name and a number.  The number part needs to be the same as the same as the
last number in the IP address.  You know these go in a domain like,
"wikstrom.pilec.rm.net" which is a zone for your name server:

      tie %DNS, 'CfgTie::TieNamed';
      my $Tbl = $DNS->{'primary'}->{'wikstrom.pilec.rm.net'};
      my $N=10; #Ten modems;
      my $prefix="usr2-port";
      my $ip_start=11;
      for (my $i = 0; $i < $N; $i++)
      {
         #Insert the address record in the table
         $Tbl->{$prefix.$i}->{'A'} = "127.221.19.".($i+$ip_start);
      }

      #Finally make sure that the reverse name space is up to date
      (tied %DNS)->RevXRef('wikstrom.pilec.rm.net','19.221.127.in-addr.arpa');


Even the address to name mapping will be kept up to date.
        

=head2 The basic structure of the named configuration table

=over 1

=item C<bogusns>

A list of name server addresses to ignore.

=item C<cache>

See L<named(8)> for a description

=item C<check-names>

=item C<directory>

This specifies the working directory of the F<named> server, and is used in
determining the location of the associated files.

=item C<forwarders>

A list of other servers' addresses on the site that can be used for recursive
look up.

=item C<limit>

Controls operational parameters of the F<named> server.  See below.

=item C<options>

The list of options the F<named> server should adhere to.

=item C<primary>

This maps to a an associative array of name spaces we are primary for.  See
below for more details on this is handled.

=item C<secondary>

This maps to a an associative array of name spaces we are secondary for.

=item C<sortlist>

See L<named(8)> for a description

=item C<xfrnets>

The list of networks which are allowed to request zone transfers.  If not
present, all hosts on all networks are.

=back

Others may be set as well, but they are for backwards compatibility and should
be changed to the more appopriate form.  See L<named(8)> for more information.

=head2 Extra methods for the configuration table

These are various methods you can use.  Of course, you will need an object
reference you can use for the remaining methods.  Note that if you tied the
variable, you will want to use code sorta like:
C<my $Obj = tied %CfgTie::TieNamed;>

C<RevSpaces> Is the list of the reverses addresses spaces that the server is
primary for (except loopback)

C<FwdSpaces> Is the list of name spaces the server is primary for (except the
loopback and reverse name spaces)

C<RevXRef($>I<fwd>C<,$>I<rev>C<)> This will check that reverse look up is up
to date with the primary look up.  It will add reverse entries as appropriate
(if there is one missing, or the value is correct).  It will not change a
reverse entry if there are multiple names with the same address entry.
I<rev> is optional, but this method will return (with a 0) if it is not
specified and there is more than one reverse name space.
I<fwd> is optional, but this method will return (with a 0) if it is not
specified and there is more than one primary name space.
Returns the number of entries changed or added.

I<Note:> This also derives any other methods from the C<CfgTie::Cfgfile> module
(L<CfgTie::Cfgfile>).

=head2 The basic structure of a primary name space table

The C<$named->E<gt>C<{primary}> entry refers to a associative arrays.  The
keys are the domain names that are to be server.  ie,

   my %mydom = $name->{primary}->{'mydomain.com'};

These associations in turn refer to a table of names and their respective
attributes.  The keys to this table are the machine names.  

The values associated keys are hash references to domain name records.  This
in turn refers to another (confused yet?) associative array.  The keys of
this table are the DNS attribute names.  The values associated with the key
are list references, usually a set of possible values for the given attribute
and name pair.  The most common ones are:

=over 1

=item C<A>

This is a list reference to all of the physical addresses the given machine
name has.

=item C<NS>

This is a list reference to all of the servers that can serve as domain name
servers.

=item C<CNAME>

This is a list reference to all of the real names the given machine
name has.

=item C<SOA>

Has a list reference with the following structure
C<HOSTDATAFROM MAILADDR SERIAL REFRESH RETRY EXPIRE MinTTL>
The Serial number is automatically updated for each table that is changed.
The format is guessed (from various date formats include YYYYMMDD, YYYYDDD,
and others), and properly incremented or set.

=item C<PTR>

This is a list reference to the real name of a given machines address.

=item C<TXT>

Each element of this list refers to a string describing the domain or name.

=item C<WKS>

=item C<HINFO>

=back

=head2 Extra methods table

C<DblLinks> This looks for entries with both a C<A> and a C<CNAME> entry.
I<Keep> controls whether to keep the C<A> or the C<CNAME> entry; the default
is to keep the C<A> entry (and delete the C<CNAME> entry).  Returns a count
of all the records that were modified.

I<Note:> This also derives any other methods from the C<CfgTie::Cfgfile> module
(L<CfgTie::Cfgfile>).

=head1 See Also

L<CfgTie::Cfgfile>,
L<CfgTie::TieAliases>, L<CfgTie::TieGeneric>,   L<CfgTie::TieGroup>,
L<CfgTie::TieHost>,    L<CfgTie::TieMTab>,      L<CfgTie::TieNet>,
L<CfgTie::TiePh>,
L<CfgTie::TieProto>,   L<CfgTie::TieRCService>, L<CfgTie::TieRsrc><
L<CfgTie::TieServ>,
L<CfgTie::TieShadow>,  L<CfgTie::TieUser>

=head1 Caveats

Much of the information is cached and the file is updated at the end.  The
C<named> process will sent the C<SIGHUP> signal to restart and reload the
configuration files.

The reverse name file can not be automatically created... Only modified.

The SOA records in the named configuration files are not easy to change.

Changing the file name or directory currently does not move the files in the
file system

=head1 Author

Randall Maas (L<randym@acm.org>)

=cut

package CfgTie::TieNamed;
use CfgTie::Cfgfile;
use CfgTie::TieRCService;
use CfgTie::filever;
use Secure::File;
use vars qw($VERSION @ISA);
use AutoLoader 'AUTOLOAD';
@ISA=qw(AutoLoader CfgTie::Cfgfile);
$VERSION='0.41';
my %servs;
tie %servs, 'CfgTie::TieRCService';
my $serv = $servs{'named'};
1;

__END__

sub cfg_end
{
   #Tell the name server to restart
   (tied $serv)->reload();
}

# This reads in a named boot file.

# Key is the domain, value is a hash reference to settings for that domain.

sub scan
{
   #This scans the named.boot file
   my $self = shift;

   if (!exists $self->{Path})
     {
        # Hunt it down in the default place
           if (-e '/etc/named.boot') {$self->{Path}='/etc/named.boot';}
        else {die "can't find the path to the named boot file!\n";}
        #Should look elsewhere, like the start up files
     }

   my $dir='./';
   my $F = new Secure::File '<'.$self->{Path};
   return unless defined $F;

   while (<$F>)
    {
       if (/^\s*directory\s+([^\s\n;]+)\/?\s*/i)
         {
            #This sets the working directory for all of the following files.
            $dir = $1;
            $self->{Contents}->{directory}=[$1];
         }
       elsif (/^\s*primary\s+([^;]+)\s+([^;\n\s]+)/i)
         {
            #We have a set of primary domains that map to a particular file
            foreach my $I (split(/\s+/,$1))
             {
                my %newtie;
                my $x = $dir.'/'.$2;
                if (exists $self->{RCS})
                  {
                     my $xobj = Rcs->new();
                     &CfgTie::filever'RCS_path($xobj, $x);

                     $x = $xobj;
                  }
                tie %newtie,'CfgTie::TieNamed_primary', $x, $I;
                $self->{Contents}->{primary}->{$I} = \%newtie;
             }
         }
       elsif (/^\s*limit\s+([^\s\n;]+)\s+([^;\n]*)/i)
         {
            $self->{Contents}->{limit}->{$1} = [split /\s+/, $2];
         }
       elsif (/^\s*([^;\n\s]+)\s+([^;\n]*)/i && $1 && $2)
         {
            #Miscellaneous additional options
            my $l1 = lc($1);
            my $a;
            if (exists $self->{Contents}->{$l1})
              {$a =$self->{Contents}->{$l1};}
             else
              {$a = [];}


            $self->{Contents}->{$l1} = [@{$a}, split(/\s+/, $2)];
         }
    }
   $F->close;
}


sub makerewrites
{
   my $self = shift;
   my $Sub;
   my $Rules = "\$Sub = sub {\n   \$_=shift;\n";
   foreach my $I (keys %{$self->{Queue}})
    {
       if (!defined $self->{Queue}->{$I} || !length $self->{Queue}->{$I})
         #Build a deletion rule
         {$Rules.="   if(/^\\s*$I\\s+/i){return;}\n";}
        else
         {
            #Build a change value rule
            #  If we match the pattern, keep the comments, build up a space
            #  delineated version (reusing most of the previous stuff), but
            #  not keeping the actual value part.. Place our own settings there
            $Rules.="   if(/^\\s*($I)\\s+[^;\\n]*(;[^\\n]*)?/i)\n   ".
                    "{my \$Ret =\"\$1 ". join(' ',@{$self->{Queue}{$I}}).
                    "\;\n    ".
                    "if (defined \$2) {\$Ret .=\$2;}\n   return \$Ret.\"\\n\";}\n";
         }
    }
   $Rules .="\n   \$_;\n};\n";
   $@='';
   eval $Rules;
   if (defined $@ && length $@) {die "rewrite rules compilation failed: $@";}
   return $Sub;
}

sub STORE
{
   my $self = shift;
   my ($key,$val)=@_;
   my $lkey=$key;
      if ($lkey eq 'limit')
        {
           #Basically
           my ($key2, @rest) = @{$val};
           $self->{Contents}->{$key2} = [@rest];
           $self->{delegate}->Queue_Store("limit\\s+$key2",[@rest]);
        }
   elsif ($lkey eq 'primary')
        {
        }
    else
        {$self->{delegate}->STORE($key,$val);}
}

#sub TIEHASH
#{
#   my $self =shift;
#   my $Node ={};
#   my $Ret = bless $Node, $self;
#   $Ret->{delegate} = CfgTie::Cfgfile->new($Ret, @_);
#   $Ret;
#}

# from p325
#sub AUTOLOAD
#{
#   my $self=shift;
#   return if $AUTOLOAD =~ /::DESTROY$/;

#   #Strip the package name
#   $AUTOLOAD =~ s/^CfgTie::TieNamed:://;

#   if ($AUTOLOAD eq 'start' || $AUTOLOAD eq 'stop' || $AUTOLOAD eq 'restart'||
#       $AUTOLOAD eq 'reload'|| $AUTOLOAD eq 'status')
#     {
#        return (tied $serv)->$AUTOLOAD(@_);
#     }

   #Pass the message along
#   $self->{delegate}->$AUTOLOAD(@_);
#}

#List the reverses addresses spaces we primary (except loopback)
sub RevSpaces($)
{
   my $self=shift;

   # Get the goodies of the real deal
#   if (exists $self->{delegate}) {$self = $self->{delegate};}

   my $P=$_;
   my @Ret;
   foreach $_ (keys %{$self->{Contents}->{primary}})
    {
       if (/^0.0.127\.in-addr\.arpa$/i) {next;}
       if (/\.in-addr\.arpa$/i) {push @Ret, $_;}
    }
   $_=$P;
   @Ret;
}

#List the name spaces that we primary (except loopback and the reverse)
sub FwdSpaces($)
{
   my $self=shift;

   my $P=$_;
   my @Ret;
   foreach $_ (keys %{$self->{Contents}->{primary}})
    {
       if (/\.in-addr\.arpa$/i) {next;}
       push @Ret,$_;
    }
   $_=$P;
   @Ret;
}

#Parameter one is to strip off the base name portion of the address
#Parameter two is the reverse look up hash
#The rest is the list
#Description
# This goes thru the list of entries and tries to dosome very flexible
# pattern matching to be sure that the reverse names match...  It will avoid
# any addresses that have multiple names, since there is no clear rule set on
# how this should be handled
#Return Value
# The number of entries modified.
sub Check_Bidir 
{
   my $self = shift; my $fwd = shift; my $RevN = shift;

   # Get the goodies of the real deal
#   if (exists $self->{delegate}) {$self = $self->{delegate};}

   my $Rev = $self->{Contents}->{primary}->{$RevN};
   my %Count;
   my %ShouldBe;
   my $PatPRecs;
   eval "\$PatPRecs = sub {my \$A=shift; if (\$A=~s/\.$fwd\.\$//i) {\$A;}}";
   die $@ if $@;

   while (scalar @_)
    {
       my $Addr = pop @_;
       my $I = pop @_;

       my ($N) = @{$Rev->{$Addr}->{PTR}};
       $_=lc($N);

       #Strip off the base
       #Skip it if it is talking about some other addresss range
       $_=&$PatPRecs($_);
       if (!$_) {next;}

       my $P = $_;
       #Strip off on the other side too
       $_ = &$PatPRecs(lc($I));
       if (!$_) {$_=lc($I);}
       if ($_ eq $P) {next;} #They match

       if (!exists $Count{$Addr}) {$Count{$Addr}=0;} else {$Count{$Addr}++;}
       $ShouldBe{$Addr}=$_.".$fwd.";
    }

   my $Cnt=0;
   foreach my $Addr (keys %Count)
    {
       if ($Count{$Addr}) {next;} #Skip those with lots and lots of xreferences
       #print "$Addr:Reverse name mismatch. Should be:", $ShouldBe{$Addr},"\n";
       $Rev->{$Addr}->{PTR} = $ShouldBe{$Addr};
       $Cnt++;
    }
   if ($Cnt)
     {(tied %{$Rev})->Comment_Add("Corrected several reverse lookup entries");}
   $Cnt;
}

#Determines the addresses of the machines in our class
#Parameter one is to strip off the class portion of the address
#Return Value
# The a list (address and 
sub OurClass_machines ($$$)
{
   my ($self, $PriName,$RevName)=@_;

   # Get the goodies of the real deal
   if (exists $self->{delegate}) {$self = $self->{delegate};}

   my @Ret;
   my $Cnt=0;

   #Make the pattern to clean up the addresses for decent matching
   my @RevAddr = split /\./, $RevName;
   #Strip off the in-addr and the arpa
   pop @RevAddr; pop @RevAddr;
   my $AddrPat = join('\\.',reverse @RevAddr);

   #This pattern strips off the class C stuff for regular address
   my $PatARecs; 
   eval "\$PatARecs =sub {my \$A=shift; if(\$A=~ s/^$AddrPat\\.//) {\$A}};";
   die $@ if $@;

   my $RevNameZ=".$RevName.";
   my $Rev = $self->{Contents}->{primary}->{$RevName};
   my $Pri = $self->{Contents}->{primary}->{$PriName};

   foreach my $Name (keys %{$Pri})
    {
       #If the primary side does not have an A record, don't worry about it
       if (!exists $Pri->{$Name}->{A}) {next;}

       ($_) = @{$Pri->{$Name}->{A}};

       #Skip it if it is talking about some other addresss range
       $_=&$PatARecs($_);
       if (!$_) {next;}

       my $Addr = $_;
       my $KAddr = $Addr;


       if (exists $Rev->{$Addr.$RevNameZ}) {$KAddr = $Addr.$RevNameZ;}
       if (!exists $Rev->{$KAddr} || !exists $Rev->{$KAddr}->{PTR})
         {
            #print "Reverse for $Name ($KAddr) doesn't exist!  Will be $Name\n";
            $Rev->{$KAddr}->{PTR} = $Name;
            $Cnt++;
            next;
         }
       push @Ret, $Name, $KAddr;
    }
   if ($Cnt)
     {(tied %{$Rev})->Comment_Add("Add some missing reverse lookup entries");}
   ($Cnt, @Ret);
}

sub RevXRef
{
   my ($self,$fwd,$rev)=@_;
   if (!defined $rev)
     {
        #The reverse name space was not specified... see if we can determine
        # it
        my @Revs = RevSpaces($self);
        if (!scalar @Revs) {return 0;} #Bad
        if (scalar @Revs > 1) {return 0;} #Bad;
        ($rev) = @Revs;
     }
   if (!defined $fwd)
     {
        #The forwad name space was not specified... see if we can determine
        # it
        my @Fwds = FwdSpaces($self);
        if (!scalar @Fwds) {return 0;} #Bad
        if (scalar @Fwds > 1) {return 0;} #Bad;
        ($fwd) = @Fwds;
     }

   #This pattern strips off the class stuff for the reversed addesses:
#   my $PatRevName= {s/\.$rev\.$//i};

   my ($Cnt,@R) = OurClass_machines($self,$fwd,$rev);
   $Cnt + Check_Bidir($self, $fwd, $rev, @R);
}

#Stuff for the config
sub HTML
{
   my ($self,$class)=@_;
   my $Ret="<table";
   if (defined $class) {$Ret .= " classname=$class";}
   $Ret .=">";
   foreach my $I (sort keys %{$self})
    {
       my $i = lc($I);
       # Skip the more complex ones...
       if ($i eq 'limit' || $i eq 'primary') {next;}
       $Ret .= "<tr><th align=right>$I</th><td>".$self->{$I}."</td></tr>\n";
    }
   if (exists $self->{limit})
     {
        $Ret .= "<tr><th align=right>Limits</th><td><table>".
         join "\n",
          map {"<tr><th align=right>$_</th><td>".$self->{limit}->{$_}.
               "</td></tr>";} (sort keys %{$self->{limit}});
        $Ret .="</table></td></tr>\n";
     }
   if (exists $self->{primary})
     {
        $Ret .= "<tr><th align=right>Domains:</th><td>".
         join "\n",
          map {"<a href=\"primary/$_/\">$_</a><br>"}
           (sort keys %{$self->{primary}});
        $Ret .="</td></tr>\n";
     }
   "$Ret</table>\n";
}

package CfgTie::TieNamed_primary;
@ISA=qw(CfgTie::Cfgfile);
#A tie hash for a single primary file...

my @days_per_month=(31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

sub SerialNum_next($)
{
   # A routine to guess the human format of the serial number and come up with
   # the next one.  The minimal rule here is that the returned value will be
   # no matter what, greater than the previous one.
   # We are allowed 9 digits in base 10.
   my $SN = shift;

   my ($sec,$min,$hour,$MDay,$Month,$Year,$WDay,$YDay,$isDST)=localtime;

   #Try YEAR-MONTH-DayOfMonth-Rev
   #  We have to make general calendar boundary conditions, plus be at an
   #  earlier date than now.
   if ($SN =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d)$/ &&
       $2 <= 12 && $3 <= $days_per_month[$2-1] &&
       ($1 < $Year ||
         ($1 == $Year && ($2 < $Month+1||($2==$Month+1&&$3<=$MDay+1)))))
     {
        # We passed the first part of the boundary conditions...
        my $NewSn = $Year.($Month+1).($MDay+1)."0";
        while ($NewSN <= $SN) {$NewSN++;}
        return $NewSN;
     }

   #Okay, try YEAR-WEEK-DayOfWeek-Rev
   my $Week;
   if ($YDay < $WDay) {$Week = 0;}
    else {$Week  = ($YDay-$WDay)/7;}

   if ($SN =~ /^(\d\d\d\d)(\d\d)(\d)(\d\d)$/ &&
       $2 <= 52 && $3 <= 7 &&
       ($1 < $Year ||
         ($1 == $Year && ($2 < $Week+1||($2==$Week+1&&$3<=$WDay+1)))
       ))
     {
        # We passed the first part of the boundary conditions...
        my $NewSn = $Year.($Week+1).($WDay+1)."00";
        while ($NewSN <= $SN) {$NewSN++;}
        return $NewSN;
     }

   #Okay try YEAR-DayOfYear-Rev
   if ($SN =~ /^(\d\d\d\d)(\d\d\d)(\d\d)$/ &&
       $2 <= 366  &&
       ($1 < $Year || ($1 == $Year && $2 <= $YDay+1)))
     {
        # We passed the first part of the boundary conditions...
        my $NewSn = $Year.($YDay+1)."000";
        while ($NewSN <= $SN) {$NewSN++;}
        return $NewSN;
     }

   #Didn't match anything... write a new one out.
   return $SN+1;
}

sub addrec
{
   my ($self,$key,$attr,$_val) = @_;

   #Convert the value to list notation
   my $val;
   if (lc($attr) eq 'txt')
     {$val = [$_val];}
    else
     {$val = [split(/\s+/,$_val)];}

   #If there is data already here we just append the data to the list
   if (!exists $self->{Contents} || !exists $self->{Contents}->{$key} ||
       !exists $self->{Contents}->{$key}->{$attr})
     {$self->{Contents}->{$key}->{$attr}=$val;}
    else
     {
       $self->{Contents}->{$key}->{$attr}=[
         @{$self->{Contents}->{$key}->{$attr}},@{$val}];
     }
}

sub scan
{
   my ($self, $defdom) = @_;
   my $Node;

   $defdom .='.'; #Need a terminating null
   $self->{Domain} = $defdom;

   #Scan the file in.
   my $F = new Secure::File '<'.$self->{'Path'};
   goto SKIPREAD unless defined $F;

   while ($<F>)
    {
       #Scan a simple line Grab thring things
       if (/^\s*([^\n;\s]*)\s+IN\s+(\w+)\s+([^\(;\n]+)\s*\(/i)
         {
            # We are in multiple line mode -- temporarilty
            #$1 is not required to be defined... it can be implied
            my ($attr,$val,$dom)=($2,$3);
            if (!defined $1 || $1 eq '@' || !length $1)
              {$dom = $defdom;}
             else
              {$dom=$1;}

            #Now read in the remaining lines
            LINE: while (<F>)
             {
                if (/^\s*([^\n;\s\)]*)\s*\)/)
                  {
                     if (defined $1) {$val.=" $1";}
                     last LINE;
                  }
                if (/^\s*([^\n;\s]+)/) {$val.=" $1";}
             }
            &addrec($self,$dom,$attr,$val);
         }
       elsif (/^\s*([^\n;\s]*)\s+IN\s+(\w+)\s+([^(;\n]+)\s*/i)
         {
            #We are in single entry mode
            #$1 is not required to be defined... it can be implied
            my $dom;
            if (!defined $1 || $1 eq '@'|| !length $1)
              {$dom = $defdom;}
             else
              {$dom=$1;}

            &addrec($self,$dom,$2,$3);
         }
    }
   $F->close;

     SKIPREAD:

   ## Now for the fun part. We've built up the database... now we need to
   # convert it to a form we can trap and monitor;

   my $K1 = $self->{Contents};
   my $K2;

   foreach my $Machine (keys %{$K1})
    {
       my %K3;
       tie %K3, 'CfgTie::TieNamed_sub', $self, $Machine,
         $K1->{$Machine};
       $K2->{$Machine} = \%K3;
    }
   $self->{Contents} = $K2;
}

sub makerewrites
{
   my $self = shift;
   local $Sub;
   my $Rules = "\$Sub= sub {\n   \$_=shift; my \$S=shift;\n";
   my $Q = $self->{Queue};
   my $SOA;
   #Hunt down any changes to the SOA records...
   my @SKeys = grep /\\s\+SOA/, (keys %{$Q});

   if (!scalar @SKeys)
     {
        #No SOA records of note.. lets make our own.
        if (exists $self->{Domain})
          {
             my @A = @{$self->{Contents}->{$self->{Domain}}->{SOA}};
             my $D = $self->{Domain};
             $D =~ s/\./\\\./g; #Make sure the periods are literals
             #Bump the SOA serial number to indicate changes
             my $NSN =  SerialNum_next $A[2];

             #It is right there...
             $Rules .= '   if (s/^\s*(@|'.$D.
                     ')(\s+IN\s+SOA\s+)[^\(\n\s;]+\s+[^\(\n\s;]+\s+'.
                     '[^\s\n\(;]+/do{$1.$2."'.$A[0].' '. $A[1].' '.$NSN.
                     '"}/iex) {return $_;}'."\n";

             # A parenthesis too soon
             $Rules .= '   if (s/^\s*(@|'.$D.
                     ')(\s+IN\s+SOA\s+)[^\(\n\s;]+\s+[^\(\n\s;]+\s+'.
                     '([\(;])/do{$1.$2."'.$A[0].' '. $A[1].' ".$3}/iex) '.
                     '{$S->[0]="SOA"; $S->[1]=2; return $_;}'."\n";

             $Rules .= '   if (s/^\s*(@|'.$D.
                     ')(\s+IN\s+SOA\s+)[^\(\n\s;]+\s+([\(;])/do{$1.$2."'.
                     $A[0].' ".$3}/iex) '.
                     '{$S->[0]="SOA"; $S->[1]=1; return $_;}'."\n";

             $Rules .= '   if (s/^\s*(@|'.$D.
                     ')(\s+IN\s+SOA\s+[\(;])/$1$2/i)'.
                     '{$S->[0]="SOA"; $S->[1]=0; return $_;}'."\n";

             #Now we are in the parenthesis and need to figure out what to do
             $Rules .=
             'if ($S->[0]eq"SOA") {'.
             '  if ($S->[1]==0){'.
             '    if (s/^(\s*)[^\)\s;]+\s+[^\s\);]+\s+[^\s\);]+/do{$1."'.
                     $A[0].' '.$A[1].' '.$NSN.'"}/ex) '.
             '    {$S->[0]=""; return $_;} '."\n".

             '    if (s/^(\s*)[^\)\s;]+\s+[^\s\);]+/do{$1."'.$A[0].' '.
                    ' '.$A[1].'"}/ex) '.
             '    {$S->[1]=2; return $_;} '."\n".

             '    if (s/^(\s*)[^\)\s;]+/do{$1."'.$A[0].'"}/ex) '.
             '    {$S->[1]=1;} return $_;}'."\n".
             ' elsif ($S->[1]==1){'.
             '    if (s/^(\s*)[^\)\s;]+\s+[^\s\);]+/do{$1."'.$A[1].' '.
                   $NSN.'"}/ex) '.
             '    {$S->[0]=""; return $_;} '."\n".

             '    if (s/^(\s*)[^\)\s;]+/do{$1."'.$A[1].'"}/ex) '.
             '    {$S->[1]=2;} return $_;}'."\n".
             ' elsif ($S->[1]== 2 && s/^(\s*)[^\(\s\n]+/do{$1."'.$NSN.
                '"}/ex)   {$S->[0]=""; return $_;}}'."\n";

           }
     }
    else
     {
        #For each of these that exists make the proper rules...
        foreach my $I (@SKeys)
         {
            my @A = @{$self->{Queue}->{$I}->{SOA}};
            #Bump the SOA serial number to indicate changes
            $A[2] =  SerialNum_next $A[2];
         }
     }

   foreach my $I (keys %{$Q})
    {
          if (!defined $Q->{$I} || !length $Q->{$I})
            #Build a deletion rule
            {$Rules.="   if(/^\\s*$I\\s+/i){return;}";}
       elsif (ref($Q->{$I}) eq 'HASH') {next;}
       else
         {
            #Build a change value rule
            $Rules.='   if (s/^(\s*'.$I.'\s+)[^;\n]+/$1'.
                    join(',',@{$self->{Queue}{$I}}).'/) {return $_;}'."\n";
         }
    }
   $Rules .="\n   \$_;\n};\n";
   $@='';
   eval $Rules;
   if (defined $@ && length $@) {die "rewrite rules compilation failed: $@";}
   return $Sub;
}

#sub TIEHASH
#{
#   my ($self,$fileobj,$defdom,@rest) =@_;
#   my $Node = {base =>$defdom,};
#   my $Ret = bless $Node, $self;
#   $Ret->{delegate} = CfgTie::Cfgfile->new($Ret, $fileobj,$defdom,@rest);
#   $Ret;
#}

sub FETCH
{
   my ($self, $key)=@_;

   #If it is about to fetch something that doesn't exist.... tie it!
   if ($self->{delegate}->EXISTS($key))
     {return $self->{delegate}->FETCH($key);}

   my %K;
   tie %K, 'CfgTie::TieNamed_sub', $self->{delegate}, $key, {};
   $self->{delegate}->STORE($key,\%K);

   \%K;
}

# from p325
sub AUTOLOAD
{
   my $self=shift;
   return if $AUTOLOAD =~ /::DESTROY$/;

   #Strip the package name
   $AUTOLOAD =~ s/^CfgTie::TieNamed_primary:://;

   #Pass the message along
   $self->{delegate}->$AUTOLOAD(@_);
}

sub DblLinks ($$)
{
   my ($self,$Keep) = @_;
   #Keep is allowed to be either CNAME or A... so lets filter it down
   my $Del;
      if (!defined $Keep)       {$Del = 'CNAME';}
   elsif (lc($Keep) eq 'cname') {$Del = 'A';}
   else                         {$Del = 'CNAME';}

   my $DB = $self->{delegate};
   my $Cnt = 0;
   foreach my $I (keys %{$DB})
    {
       #Skip those with only one of the two records defined...
       if (!exists $DB->{$I}->{A})    {next;}
       if (!exists $DB->{$I}->{CNAME}){next;}

       delete $DB->{$I}->{$Del};
       $Cnt++;
    }
   $Cnt;
}

#Stuff for DNS table
sub HTML
{
   my ($self,$class)=@_;
   my $Ret="<table";
   if (defined $class) {$Ret .= " classname=$class";}
   $Ret .=">";
   foreach my $I (sort keys %{$self})
    {
       my $S = $self->{$I};
       $Ret .="<tr><th align=right><a href=\"$I\">$I</a></th><td>";
       #Try to add the link to the thingy it is...
          if (exists $S->{A})     {$Ret .= "<code>".$S->{A}."</code>";}
       elsif (exists $S->{CNAME})
            {$Ret .= "<a href=\".$S->{CNAME}.\">".$S->{CNAME}."</a>";}
       elsif (exists $S->{PTR})
            {$Ret .= "<a href=\".$S->{PTR}.\">".$S->{PTR}."</a>";}

       $Ret .= "</td>";
       if (exists $S->{TXT}) {$Ret.="<td><i>".$S->{TXT}."</i></td>";}
       $Ret .= "</tr>\n";
    }
   "$Ret</table>\n";
}
#Need the ability to change the file without damaging it.

#Need to further break down the lines that get scanned... basically
#each one is going to be slightly different

package CfgTie::TieNamed_sub;

sub TIEHASH
{
   my ($self, $parent, $base, $data)=@_;
   return bless {base => lc($base), Contents => $data,
     parent=> $parent},
     $self;
}

sub STORE
{
   #Our main little routine... basically we track when the thing is stored
   #to, update ourselves accordingly, and make sure we know so later we can
   #update the proper files
   my ($self,$key,$_val) =@_;
   my $val;
   if (!ref $_val) {$val=[$_val];} else {$val=$_val;}

   my $e = exists $self->{Contents}->{$key};

   $self->{Contents}->{$key}=$val; #The store bit.

   if ($e)
     {
        #And tell our big one
        $self->{parent}->Queue_Store($self->{base}.'\s+IN\s+'.$key, $val);
     }
    else
     {
        #Be cheap
        $self->{parent}->STORE_cheap($self->{base}.' IN '.$key.' '.
                join(' ',@{$val})."\n");
     }
}

sub FETCH
{
   my ($self,$key)=@_;
print $key, "\n";
   $self->{Contents}->{$key};
}

sub FIRSTKEY
{
   my $self=shift;
   my $a = scalar keys %{$self->{Contents}};
   each %{$self->{Contents}};
}

sub NEXTKEY  { each %{$_[0]->{Contents}} }
sub EXISTS   { exists $_[0]->{Contents}->{$_[1]} }
sub DELETE   { delete $_[0]->{Contents}->{$_[1]} }
sub CLEAR    { %{$_[0]->{Contents}} = () }

sub HTML ($$)
{
   my ($self,$class)=@_;

   my $Ret;
   if (defined $class)
     {$Ret = "<table class=$class border=0>";}
    else
     {$Ret = "<table border=0>";}

   my %T = map {$_,1} (keys %{$self->{Contents}});

   #Do some things in order
   foreach my $I (A PTR CNAME TXT MX NS)
    {
       if (!exists $T{$I}) {next;}
       delete $T{$I}; # Keep it from happening later...
       $Ret .="<tr><th align=right>$I</th><td>".$self->{Contents}->{$I}.
               "</td></tr>\n";
    }

   foreach my $I (keys %T)
    {
       $Ret .="<tr><th align=right>$I</th><td>".$self->{Contents}->{$I}.
               "</td></tr>\n";
    }
   $Ret = "</table>\n";
}
1;


