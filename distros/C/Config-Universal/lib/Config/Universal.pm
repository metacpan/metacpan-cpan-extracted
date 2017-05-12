#
#  Universal::Config
#
#  Maintained by  Hartmut Vogler (hartmut.vogler@t-systems.com,it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
package Config::Universal;
use 5.005;
use strict;


=head1 NAME

Config::Universal - Universal object oriented config file reader

=begin __INTERNALS

=head1 PORTABILITY

At this time, it is only tested on Linux, but perhaps it is
writen in nativ perl, it should be no problem to use it on
other platforms.

=back

=end __INTERNALS

=head1 SYNOPSIS

  use Config::Universal;

  my $conf=new Config::Universal();
  $conf->ReadConfigFile("my.conf") && die ("ReadConfigFile failed");
  my $varval=$conf->GetVarValue("myvarname");
  
=head1 DESCRIPTION

This module is designed to read object structured config files.

=head1 METHODS

=over 4

=cut

use vars qw($VERSION); 

$VERSION = '0.5';


=item C<new>(PARAM)

Constructor allows the following parameters:

   - none at this time -

=cut

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=\%param;

   $self=bless($self,$type);
   if (!defined($self->{'Var'})){
      $self->{'Var'}={};
   }
   if (!defined($self->{'FQ'})){
      $self->{'FQ'}={};
   }
   return($self);
}

=item C<ReadConfigFile>($filename)

This method reads the config file. If this fails, the method
returns a non zero value.

=cut

sub ReadConfigFile
{
   my $self=shift;

   $self->{'Var'}={};
   $self->{'FQ'}={};
   $self->{'Obj'}=0;
   foreach my $filename (@_){
      my $result=$self->_ReadConfigFile($filename);
      return($result) if ($result);
   }
   #
   #Objekte im FQ Hash erfassen
   #
   foreach my $objtype (keys(%{$self->{Var}})){
      next if ($objtype eq '%GLOBAL%');
      foreach my $objname (keys(%{$self->{Var}->{$objtype}})){
         my $fqname=$self->{Var}->{$objtype}->{$objname}->{'$FQNAME$'};
         $self->{FQ}->{$fqname}={obj=>$self->{Var}->{$objtype}->{$objname}};
      }
   }
   #
   # Parent-Struktur erfassen
   #
   foreach my $obj (values(%{$self->{FQ}})){
      if (defined($obj->{obj}->{'$PARENT$'})){
         $obj->{parent}=$self->{FQ}->{$obj->{obj}->{'$PARENT$'}}->{obj};
      }
   }
   #
   # Transferieren und Entfernen der Struktur Variablen.
   #
   foreach my $obj (values(%{$self->{FQ}})){
      $obj->{FQNAME}=$obj->{obj}->{'$FQNAME$'};
      $obj->{TYPE}=$obj->{obj}->{'$TYPE$'};
      $obj->{NAME}=$obj->{obj}->{'$NAME$'};
      $obj->{LINE}=$obj->{obj}->{'$LINE$'};
      delete($obj->{obj}->{'$FQNAME$'});
      delete($obj->{obj}->{'$PARENT$'});
      delete($obj->{obj}->{'$NAME$'});
      delete($obj->{obj}->{'$LINE$'});
      delete($obj->{obj}->{'$TYPE$'});
   }
   #
   # objecte dereferenzieren
   #
   my %objtypes;
   map({$objtypes{$_}=1} $self->GetObject());
   foreach my $obj (values(%{$self->{FQ}})){
      foreach my $v (keys(%{$obj->{obj}})){
         if (defined($objtypes{$v})){
            my @objlist=();
            my @namelist=($obj->{obj}->{$v});
            @namelist=@{$namelist[0]} if (ref($namelist[0]) eq "ARRAY");
            foreach my $name (@namelist){
               my $obj=$self->GetObject($v,$name);
               if (!defined($obj)){
                  printf STDERR ("ERROR: can't resolv referenz to ".
                                 "object '$name' with type '$v'".
                                 "at \n");
                  exit(1);
               }
               push(@objlist,$obj);
            }
            $obj->{obj}->{$v}=\@objlist;
         }
      }
   }

   return(0);
}

sub _ReadConfigFile
{
   my $self=shift;
   my $configfilename=shift;

   if (open(F,"<$configfilename")){
      my $line=0;
      my $buffer="";
      my $currentname=undef;
      my $mode=undef;
      my @param=();
      my $errormsg=undef;
      my %config=();
      my %globalconfig=();
      my %cfgbuf=();
      my @curcfgbuf=\%cfgbuf;
      my $objlevel=0;
      while(my $l=<F>){
         next if ($l=~m/^\s*#.*$/ && $buffer eq "");
         $l=~s/\s*$//;
         $line++;
         $buffer.=$l;
         if ($l=~m/\\$/){
            $buffer=~s/\\$//;
            next;
         }
         $buffer=~s/\\"/\0/g;
         while($buffer ne ""){
            my $vari;
            if ($buffer=~m/^\s*{/){
               $buffer=~s/^\s*{//;
               $self->{'Obj'}++;
               my $objectname=undef;
               if ($mode eq ""){
                  $objectname="*:".$self->{'Obj'};
               }
               elsif($mode eq "Name"){
                  if ($param[0] eq "'%GLOBAL%'" || $param[0]=~m/[\s:\.\@]/){
                     printf STDERR ("ERROR: invalid class '$param[0]' ".
                                    "in $configfilename at $line\n");
                     exit(1);
                  }
                  $objectname=$param[0].":".$param[0].
                              sprintf("%02d",$self->{'Obj'});
                  $mode="";
               }
               elsif($mode eq "NameQuoteStartDataQuoteEnd"){
                  if ($param[0] eq "'%GLOBAL%'" || $param[0]=~m/[\s:\.\@]/){
                     printf STDERR ("ERROR: invalid class '$param[0]' ".
                                    "in $configfilename at $line\n");
                     exit(1);
                  }
                  if ($param[1]=~m/[\s\.\@:]/){
                     printf STDERR ("ERROR: invalid object name '$param[1]' ".
                                    "in $configfilename at $line\n");
                     exit(1);
                  }
                  $objectname=$param[0].":".$param[1]; 
                  $mode="";
               }
               else{
                  $errormsg="unexpected object open '$mode'";
               }
               if (!defined($errormsg) && $objectname ne ""){
                  my ($objtype,$shortname)=$objectname=~m/^(.*):([^:]+$)/;
                  my $obj={'$NAME$'=>$shortname};
                  $obj->{'$LINE$'}="$configfilename:$line";
                  $obj->{'$TYPE$'}=$objtype if ($objtype ne "*");
                  my @parents=grep({defined($_->{'$TYPE$'})} @curcfgbuf);
                  if ($#parents!=-1){
                     $obj->{'$PARENT$'}=join(".",map({$_->{'$NAME$'}} 
                                                     reverse(@parents)));
                  }
                  $obj->{'$FQNAME$'}=$obj->{'$PARENT$'};
                  $obj->{'$FQNAME$'}.="." if ($obj->{'$FQNAME$'} ne "");
                  $obj->{'$FQNAME$'}.=$shortname;
                  if ($objtype ne "*" &&
                      defined($self->{FQ}->{$obj->{'$FQNAME$'}})){
                     $errormsg="fullqualivied name '$obj->{'$FQNAME$'}' ".
                               "already in use";
                  }
                  else{
                     if ($objtype ne "*"){
                        $self->{FQ}->{$obj->{'$FQNAME$'}}=1;
                     }
                     $curcfgbuf[0]->{$objtype.":".$obj->{'$FQNAME$'}}=$obj;
                     unshift(@curcfgbuf,$obj);
                     $objlevel++;
                     @param=();
                  }
               }
            }
            elsif (!defined($errormsg) &&
                   $buffer=~m/^\s*}/){
               $buffer=~s/^\s*}//;
               $errormsg="unterminated command sequenz" if ($mode ne "");
               $objlevel--;
               if ($objlevel<0){
                  $errormsg="unexpected object close";
               }
               shift(@curcfgbuf);
            }
            elsif (!defined($errormsg) &&
                   $buffer=~m/^\s*"/ && ($mode=~m/Data$/)){
               $buffer=~s/^\s*"//;
               $errormsg="unexpected quote" if ($mode=~m/QuoteEnd/);
               if ($buffer=~/^\s*\,/){
                  $buffer=~s/^\s*\,//;
                  $mode.="ArraySep";
               }
               else{ 
                  $mode.="QuoteEnd";
               }
            }
            elsif (!defined($errormsg) &&
                   (($vari)=$buffer=~m/^([^"]*)/) && ($mode=~m/QuoteStart$/)){
               $buffer=~s/^([^"]*)//;
               $vari=~s/\0/"/g;
               push(@param,$vari);
               $mode.="Data";
            }
            elsif (!defined($errormsg) &&
                   (($vari)=$buffer=~m/^\s*([a-zA-Z0-9_]+)/)){
               $buffer=~s/^\s*([a-zA-Z0-9_]+)//;
               push(@param,$vari);
               $mode.="Name";
            }
            elsif (!defined($errormsg) &&
                   $buffer=~m/^\s*=/){
               $buffer=~s/^\s*=//;
               $mode.="Setvar";
            }
            elsif (!defined($errormsg) &&
                   ($buffer=~m/^\s*"/) && 
                   (($mode=~m/Setvar$/) || ($mode=~m/ArraySep$/) ||
                    ($mode=~m/Name$/))){
               $errormsg="unexpected \""      if (!($mode=~m/Setvar$/) &&
                                                  !($mode=~m/ArraySep$/)
                                                   && $mode ne "Name");
               $buffer=~s/^\s*"//;
               $mode.="QuoteStart";
            }
            elsif (!defined($errormsg) &&
                   (my ($incfile)=$buffer=~m/^\@INCLUDE\s+\"(.+)\"/)){
               $buffer=~s/^\@INCLUDE\s+\".+\"//;
               if ($mode eq "" && $objlevel==0){
                  my $result=$self->_ReadConfigFile($incfile);
                  return($result) if ($result); 
               }
               else{
                  $errormsg="\@INCLUDE not allowed in control structur";
               }
            }
            else{
               $errormsg="syntax error";
            }
            if (defined($errormsg)){
               printf STDERR ("LINE:  '$l'\n");
               printf STDERR ("ERROR: $errormsg in line $line\n");
               exit(1);
            }
            if ($mode eq "NameSetvarQuoteStartDataQuoteEnd" ||
                $mode=~m/^NameSetvarQuoteStartDataArraySep.*QuoteEnd$/){
               my $variname=shift(@param);
               my $cfgwork=$curcfgbuf[0];
               $cfgwork=\%globalconfig if ($objlevel==0);
               if ($#param==0 && $variname ne "alias"){
                  $cfgwork->{$variname}=$param[0];
               }
               else{
                  $cfgwork->{$variname}=[@param];
               }
               $mode="";
               @param=();
            }
         }
      } 
      MergeObjects(\%cfgbuf,\%globalconfig,$self->{Var});
      if ($objlevel!=0){
         printf STDERR ("ERROR: unexpected eof in '$configfilename' ".
                        "at $line\n");
         exit(1);
      }
      close(F);
      return(0);
   }
   return(int($!));
}

sub MergeObjects
{
   my $src=shift;
   my $globalconfig=shift;
   my $dst=shift;

   while(my $obj=FetchObject($src,{},undef,undef)){
      foreach my $key (keys(%{$obj})){
         my ($class,$name)=split(/:/,$key);
         if ($class ne "*"){
            $dst->{$class}->{$name}=$obj->{$key};
         }
      }
   }
   foreach my $key (keys(%{$globalconfig})){
      $dst->{'%GLOBAL%'}->{$key}=$globalconfig->{$key};
   }
}

sub FetchObject
{
   my $src=shift;
   my $buf=shift;
   my $parent=shift;
   my $name=shift;
   my $hname=undef;
   my %mybuf=%{$buf};

   foreach my $key (keys(%{$src})){
      if ((ref($src->{$key}) eq "HASH")){
         $hname=$key;
      }
      else{
         $mybuf{$key}=$src->{$key};
      }
   } 
   if ($hname){
      my $tempobj=FetchObject($src->{$hname},\%mybuf,$src,$hname);
      return($tempobj);
   }
   delete($parent->{$name}) if (defined($parent));
   return(undef) if (!defined($name));
   return({$name=>\%mybuf});
}



sub FindFreeObjectName
{
   my $config=shift;
   my $class=shift;
   my $basename=shift;
   my $c=0;
   my $name;

   while(1){
      $name=sprintf("%s:%s%02d",$class,$basename,$c);
      last if (!IsKeyInUse($config,$name));
      $c++;
   }
   return($name);
}

sub IsKeyInUse
{
   my $cfgpoint=shift;
   my $k=shift;
   foreach my $chkkey (keys(%{$cfgpoint})){
      return(1) if ($chkkey eq $k);
      if (ref($cfgpoint->{$chkkey}) eq "HASH"){
         return(1) if (IsKeyInUse($cfgpoint->{$chkkey},$k));
      }
   }
   return(0);
}


=item C<GetVarValue>()

=item C<GetVarValue>($varname)

With no $varname, the list of global variables (out of object structurs)
from configfile is returned. If the $varname is specified, the value 
of the given name is returned.

=cut

sub GetVarValue
{
   my $self=shift;
   my $varname=shift;   # if not spezified, the list of global vars ar returned
   if (!defined($varname)){
      return(keys(%{$self->{Var}->{'%GLOBAL%'}}));
   }
   if (defined($self->{Var}->{'%GLOBAL%'}->{$varname})){
      return($self->{Var}->{'%GLOBAL%'}->{$varname});
   }
   return("undef");
}  

=item C<FindParentObject>($object|$objectname)

Returns the parent object of a given object (by name or by
hash-referenz)

=cut

sub FindParentObject
{
   my $self=shift;
   my $obj=shift;

   if (ref($obj) eq "HASH"){
      foreach my $p (values(%{$self->{FQ}})){
         return($p->{parent}) if ($p->{obj} eq $obj);
      }
   }
   else{
      if (defined($self->{FQ}->{$obj})){
         $self->{FQ}->{$obj}->{parent};
      }
   }
   return();
}

=item C<ObjectInfo>($objname|$object,'FQNAME'|'NAME'|'TYPE','LINE')

Returns the spezifed deltail information for the given object (by name or by
hash-referenz)
   LINE       = definition position of object in configfile
   FQNAME     = full qualified name of the object
   NAME       = the short name of object
   TYPE       = object type
   
=cut

sub ObjectInfo
{
   my $self=shift;
   my $obj=shift;
   my $var=shift;


   if (ref($obj) eq "HASH"){
      foreach my $p (values(%{$self->{FQ}})){
         return($p->{$var}) if ($p->{obj} eq $obj);
      }
   }
   else{
      if (defined($self->{FQ}->{$obj})){
         return($self->{FQ}->{$obj}->{$var});
      }
   }
   return(undef);
}


=item C<FindSubordinate>($objname|$object,[TYPERESTRICTION])

Returns all subordnate objects with the given objecttype restriction
TYPERESTRICTION. If no TYPERESTRICTION is spezified, all subordnate
are returned. If no subordnates are found, an empty array is returend.

=cut

sub FindSubordinate
{
   my $self=shift;
   my $obj=shift;
   my @type=@_;
   my $rootobj=undef;

   if (ref($obj) eq "HASH"){
      foreach my $p (values(%{$self->{FQ}})){
         $rootobj=$p->{obj} if ($p->{obj} eq $obj);
      }
   }
   else{
      if (defined($self->{FQ}->{$obj})){
         $rootobj=$self->{FQ}->{$obj}->{obj};
      }
   }
   return(undef) if (!defined($rootobj));
   sub getsub
   {
      my $sobj=shift;
      my @fobj;
      foreach my $p (values(%{$self->{FQ}})){
         if (defined($p->{parent}) && $p->{parent} eq $sobj){
            push(@fobj,getsub($p->{obj}),$p->{obj});
         }
      }
      return(@fobj);
   }
   return(getsub($rootobj)) if ($#type==-1);
   return(grep({ my $t=$self->ObjectInfo($_,'TYPE');
                 my $bk=0;
                 map({$bk=1 if ($t eq $_);}@type);
                 $bk;
               } getsub($rootobj)));
}


=item C<GetObject>()

=item C<GetObject>($objecttype)

=item C<GetObject>($objecttype,$objectname)

With no paramaters, the method returns the list of available
object types in current config.

If the $objecttype is specified, the list of objectnames in the
given $objecttype is returned.

If $objecttype and $objectname is specified, the value ob the
described variable is returned.

=cut

sub GetObject
{
   my $self=shift;
   my $class=shift; 
   my $objname=shift;   # if not spezified, the list of objects are returned

   if (!defined($class)){
      return(grep(!/^\%GLOBAL\%$/,keys(%{$self->{Var}})));
   }
   if (!defined($objname)){
      if (defined($self->{Var}->{$class})){
         return(sort(keys(%{$self->{Var}->{$class}})));
      }
      else{
         return(undef);
      }
   }
   else{
      if (defined($self->{Var}->{$class}) &&
          defined($self->{Var}->{$class}->{$objname})){
         return($self->{Var}->{$class}->{$objname});
      }
      else{
         if (defined($self->{Var}->{$class})){
            # find alias
            foreach my $objname (keys(%{$self->{Var}->{$class}})){
               if (grep(/^$objname$/,@{$self->{Var}->{$class}->{$objname}->{alias}})){
                  return($self->{Var}->{$class}->{$objname});
               }
            }
            return(undef);
         }
         else{
            return(undef);
         }
      }
   }
}

=head1 SAMPLES

General you should use only lowercase characters for variable, objecttypes
and objectnames. Of curse there are upper case characters are useable too,
but the only use of lower case creates a better readable config.
The simples kind of configuration are simple variables.

   #
   # remarks starting with #
   #
   server="myserver"
   ipadress="192.168.2.2","192.168.1.2"
   
The next level of configuration is to create objects. A object
has always one type and sometimes a name. If no name is given,
Config::Universal create a uniq name at the given objecttype.

   server "myserver" {
      ipadress="192.168.2.2","192.168.1.2"
   }
   server{
      ipadress="164.168.2.2","164.168.1.2"
   }

Config::Universal makes it posible, to use object inheritance. At the 
following sample, every server object has the variable os="linux".

   {
      os="linux"
      server "servera" {
         ipadress="192.168.2.2","192.168.1.2"
      }
      server "serverb" {
         ipadress="164.168.2.2","164.168.1.2"
      }
   }

It is posible to include an outher configfile, but a include directrive
ist only outsite object structures alowed.

   server "myserver" {
      ipadress="192.168.2.2","192.168.1.2"
   }
   @INCLUDE "/etc/one.other.conf"

If at one object no name is spezifed, an automatic name is generated.
If this mode is used, the name of the object can be diffrent between
each run ob ReadConfigFile()!

   server "myserver" {
      ipadress="192.168.2.2","192.168.1.2"
      disk{
         name="/dev/hda"
      }
      disk{
         name="/dev/hdb"
      }
   }

References objects would be automaticly checked and dereferenced. The
corespondenting variable would have a array reference with the hash
references to the adressed objects. The object names must be always
spezified full qualified!

   server "myserver" {
      eventhandler="ev1","myserver.ev2"
      eventhandler "ev2"{
         name="/etc/ev2"
      }
   }
   eventhandler "ev1"{
      name="/etc/ev1"
   }

=head1 AUTHORS

Config::Universal by Hartmut Vogler.

=head1 COPYRIGHT

The Config::Universal is Copyright (c) 2005 Hartmut Vogler. Germany.
All rights reserved.

=cut


1;
