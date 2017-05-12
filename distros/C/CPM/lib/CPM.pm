package CPM;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION="1.51";

use IO::Socket;
use Net::SNMP;
use Net::Address::IP::Local;
use Net::Ping;
use Net::SMTP_auth;
use LWP::UserAgent;
use XML::Simple;


sub new{
  my $class=shift;
  my $self={@_};
  bless($self, $class);
  $self->_init;
  return $self;
}

sub _init{
  my $self=shift;
  
  if (defined ($self->{-config})){$self->{config}=$self->{-config};}
  else{ $self->{config}='config.xml';}
  $self->{xml}=XMLin($self->{config},('forcearray',['device','range']));
  $self->{url}=$self->{xml}->{call}.'?login='.$self->{xml}->{id}->{user}.'&nppas='.$self->{xml}->{id}->{pass};
  return $self;
}

sub saveconfig{
  my $self=shift;
  my $out=XML::Simple::XMLout($self->{xml},('keeproot',1,xmldecl=>'<?xml version="1.0" encoding="UTF-8"?>')) || die "can't XMLout: $!";

  open (OUTFILE, '>'.$self->{config}) || die "can't open output file: $!";
  binmode(OUTFILE, ":utf8");
  print OUTFILE $out;
  close OUTFILE;
  return $self;
}

sub request
# Make an SNMP request to read any OID (i.e Serial and Model)
{
  my $self=shift;
  my $oid=shift;
  my %properties=@_; # rest of params by hash
  
  my $type='none';
  $type=$properties{'-type'} if defined $properties{'-type'};

  my $session=Net::SNMP->session(-hostname=>$self->{target});
  if (!defined($session)) {return "TimeOut";}
  my $result = $session->get_request( varbindlist => [$oid]);
  $session->close;
  if(!defined($result->{$oid})){return "UnknownOID";}
  else{
     if($type eq 'MAC')
     {
       $result->{$oid}=~s/\A0x//;
       $result->{$oid}=~s/.{2}/$&:/g;
       $result->{$oid}=~s/:\Z//;
       return uc($result->{$oid});
     }
     elsif($type eq 'SN')
     {
             if(length($result->{$oid})<5){return "UnknownOID";}
             elsif($result->{$oid}=~/X{5,}/){return "UnknownOID";}
             else{
                  if($result->{$oid}=~/0x.*/){$result->{$oid}=_hex2ascii($result->{$oid});}
		  $result->{$oid}=~s/\W*//g;
                  return $result->{$oid};
             }
     }
     else{
             if($result->{$oid}=~/0x.*/){$result->{$oid}=_hex2ascii($result->{$oid});}
             return $result->{$oid};
     }
  }
}

sub requesttable
# Make an SNMP walk request
{
  my $self=shift;
  my $baseoid=shift;
  # Start a sesion connect to the host
  my $session=Net::SNMP->session(-hostname=>$self->{target});
  if (!defined($session)) {return "TimeOut";}
  # make a get-request
  my $result = $session->get_table(-baseoid=>$baseoid);
  my $values=$session->var_bind_list;
  my @koids = keys(%{$values});
  my $string='';
  foreach my $v(@koids)
  {
   $string.=$result->{$v}.'. ';
  }
  $session->close;
  if($result)
  {
    return $string;
  }
  else
  {
    return "UnkownObject";
  }
}

sub _osocket
# Open a socket on the 9100 port looking for JetDirects
{
  my $self=shift;
  my $sock = new IO::Socket::INET (
             PeerAddr => $self->{target},
             PeerPort => '9100',
             Proto => 'tcp',
  );
  if(!defined $sock){return -1;}
  else {close($sock);return 1}
}

sub _ping
# Check by ping
{
  my $self=shift;
  my $ping = Net::Ping->new();
  #return $ping->ping($self->{target},1);
  return $ping->ping($self->{target});
}

sub _hex2ascii
# Translate Hex to Ascii removing 0x0115 HP character
{
  my $str=shift||return;
  $str=~s/0x0115//;
  $str=~s/([a-fA-F0-9]{2})/chr(hex $1)/eg;
  $str=~s/\A0x.{2}//;
  #And eliminate Non Printable Chars 
  my @chars = split(//,$str);
  $str="";
  foreach my $ch (@chars){
    if ((ord($ch) > 31) && (ord($ch) < 127)){ $str .= $ch; }
  }
  return $str;
}

sub checkip
# Check socket and its snmp for specific IP
{
  my $self=shift;
  my $ping=shift;

  if($self->_ping)
  {
  # If we find the 9100 open, then...
    if($self->_osocket>0){
      my ($sn,$trace)=$self->_getsn;
      return $sn;
    }
#   else {print "Ping but not socket\n";return 0;}
  }
#  else {print "No ping\n"; return 0;}
}

sub _getsn
# Try to identify the SN using the standard OIDs
{
  my $self=shift;
  my $value='U_O';
  
  if(($value=$self->request('.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.3.0',-type=>'SN')) ne 'UnknownOID'){return $value,'1-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.5.1.1.17.1',-type=>'SN')) ne 'UnknownOID'){return $value,'2-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1248.1.2.2.1.1.1.5.1',-type=>'SN')) ne 'UnknownOID'){return $value,'3-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1347.43.5.1.1.28.1',-type=>'SN')) ne 'UnknownOID'){return $value,'4-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.11.1.10.45.0',-type=>'SN')) ne 'UnknownOID'){return $value,'5-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.23.2.32.4.3.0',-type=>'SN')) ne 'UnknownOID'){return $value,'6-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.3.2.1.3.1',-type=>'SN')) ne 'UnknownOID'){return $value,'7-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.1.4.0',-type=>'SN')) ne 'UnknownOID'){return $value,'8-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.6.1.1.7.1',-type=>'SN')) ne 'UnknownOID'){return $value,'9-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.2.1.2.1.6.1',-type=>'SN')) ne 'UnknownOID'){return $value,'10-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2435.2.3.9.4.2.1.5.5.1.0',-type=>'SN')) ne 'UnknownOID'){return $value,'11-';}

  elsif(($value=$self->request('.1.3.6.1.2.1.2.2.1.6.1',-type=>'MAC')) ne 'UnknownOID'){return $value,'12-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.2.2.1.6.2',-type=>'MAC')) ne 'UnknownOID'){return $value,'13-';}
  return $value,'X-';
}

sub getgeneric
{
  my $self=shift;
  my $host; # structure to store the results (if any)
  my $value='';
  
  ($host->{SN},$host->{TRACE})=$self->_getsn;
  
  $host->{TOTAL}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.10.2.1.4.1.1')) ne 'UnknownOID'){$host->{TOTAL}=$value;$host->{TRACE}.='20-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.2.1.5.1.0')) ne 'UnknownOID'){$host->{TOTAL}=$value;$host->{TRACE}.='21-';}

  $host->{COLOR}='U_O';
  if(($value=$self->request('.1.3.6.1.4.1.11.2.3.9.4.2.1.4.1.2.7.0')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='31-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1248.1.2.2.27.1.1.4.1.1')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='32-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1347.42.2.2.1.1.3.1.2')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='33-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.13.2.1.6.1.20.33')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='34-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.12')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='35-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.13')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='36-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.21')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='37-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.5')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='38-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.3.2.3.2.1.4.128.1')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='39-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.2.1.5.3.0')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='40-';}

  elsif(($value=$self->request('.1.3.6.1.2.1.43.10.2.1.4.1.1')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='41-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.2.1.5.1.0')) ne 'UnknownOID'){$host->{COLOR}=$value;$host->{TRACE}.='42-';}

  $host->{MC1}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.1')) ne 'UnknownOID'){$host->{MC1}=$value;$host->{TRACE}.='50-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.4.1')) ne 'UnknownOID'){$host->{MC1}=$value;$host->{TRACE}.='51-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.20.2.2.1.9.2.3')) ne 'UnknownOID'){$host->{MC1}=$value;$host->{TRACE}.='52-';}
  if($host->{MC1}==0){$host->{MC1}=100;}

  $host->{CC1}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.1')) ne 'UnknownOID'){$host->{CC1}=$value;$host->{TRACE}.='60-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.3.1')) ne 'UnknownOID'){$host->{CC1}=$value;$host->{TRACE}.='61-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.20.2.1.7.2.1.4.20.3')) ne 'UnknownOID'){$host->{CC1}=$value;$host->{TRACE}.='62-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.1')) ne 'UnknownOID'){$host->{CC1}=$value;$host->{TRACE}.='63-';}

  $host->{MC2}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.2')) ne 'UnknownOID'){$host->{MC2}=$value;$host->{TRACE}.='70-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.4.2')) ne 'UnknownOID'){$host->{MC2}=$value;$host->{TRACE}.='71-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.20.2.2.1.9.2.3')) ne 'UnknownOID'){$host->{MC2}=$value;$host->{TRACE}.='72-';}
  if($host->{MC2}==0){$host->{MC2}=100;}

  $host->{CC2}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.2')) ne 'UnknownOID'){$host->{CC2}=$value;$host->{TRACE}.='80-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.3.2')) ne 'UnknownOID'){$host->{CC2}=$value;$host->{TRACE}.='81-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.20.2.1.7.2.1.1.20.3')) ne 'UnknownOID'){$host->{CC2}=$value;$host->{TRACE}.='82-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.2')) ne 'UnknownOID'){$host->{CC2}=$value;$host->{TRACE}.='83-';}

  $host->{MC3}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.3')) ne 'UnknownOID'){$host->{MC3}=$value;$host->{TRACE}.='90-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.4.3')) ne 'UnknownOID'){$host->{MC3}=$value;$host->{TRACE}.='91-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.20.2.2.1.9.2.3')) ne 'UnknownOID'){$host->{MC3}=$value;$host->{TRACE}.='92-';}
  if($host->{MC3}==0){$host->{MC3}=100;}

  $host->{CC3}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.3')) ne 'UnknownOID'){$host->{CC3}=$value;$host->{TRACE}.='100-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.3.3')) ne 'UnknownOID'){$host->{CC3}=$value;$host->{TRACE}.='101-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.20.2.1.7.2.1.2.20.3')) ne 'UnknownOID'){$host->{CC3}=$value;$host->{TRACE}.='102-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.3')) ne 'UnknownOID'){$host->{CC3}=$value;$host->{TRACE}.='103-';}

  $host->{MC4}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.4')) ne 'UnknownOID'){$host->{MC4}=$value;$host->{TRACE}.='110-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.4.4')) ne 'UnknownOID'){$host->{MC4}=$value;$host->{TRACE}.='111-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.20.2.2.1.9.2.3')) ne 'UnknownOID'){$host->{MC4}=$value;$host->{TRACE}.='112-';}
  if($host->{MC4}==0){$host->{MC4}=100;}

  $host->{CC4}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.4')) ne 'UnknownOID'){$host->{CC4}=$value;$host->{TRACE}.='120-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.1.1.1.100.3.1.1.3.4')) ne 'UnknownOID'){$host->{CC4}=$value;$host->{TRACE}.='121-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.20.2.1.7.2.1.3.20.3')) ne 'UnknownOID'){$host->{CC4}=$value;$host->{TRACE}.='122-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.4')) ne 'UnknownOID'){$host->{CC4}=$value;$host->{TRACE}.='123-';}

  $host->{MC5}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.5')) ne 'UnknownOID'){$host->{MC5}=$value;$host->{TRACE}.='130-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.8')) ne 'UnknownOID'){$host->{MC5}=$value;$host->{TRACE}.='131-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.11')) ne 'UnknownOID'){$host->{MC5}=$value;$host->{TRACE}.='132-';}
  if($host->{MC5}==0){$host->{MC5}=100;}

  $host->{CC5}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.5')) ne 'UnknownOID'){$host->{CC5}=$value;$host->{TRACE}.='140-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.8')) ne 'UnknownOID'){$host->{CC5}=$value;$host->{TRACE}.='141-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.11')) ne 'UnknownOID'){$host->{CC5}=$value;$host->{TRACE}.='142-';}

  $host->{MC6}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.6')) ne 'UnknownOID'){$host->{MC6}=$value;$host->{TRACE}.='150-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.9')) ne 'UnknownOID'){$host->{MC6}=$value;$host->{TRACE}.='151-';}
  if($host->{MC6}==0){$host->{MC6}=100;}

  $host->{CC6}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.6')) ne 'UnknownOID'){$host->{CC6}=$value;$host->{TRACE}.='160-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.9')) ne 'UnknownOID'){$host->{CC6}=$value;$host->{TRACE}.='161-';}

  $host->{MC7}='100';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.7')) ne 'UnknownOID'){$host->{MC7}=$value;$host->{TRACE}.='170-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.10')) ne 'UnknownOID'){$host->{MC7}=$value;$host->{TRACE}.='171-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.8.1.11')) ne 'UnknownOID'){$host->{MC7}=$value;$host->{TRACE}.='172-';}
  if($host->{MC7}==0){$host->{MC7}=100;}

  $host->{CC7}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.7')) ne 'UnknownOID'){$host->{CC7}=$value;$host->{TRACE}.='180-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.10')) ne 'UnknownOID'){$host->{CC7}=$value;$host->{TRACE}.='181-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.43.11.1.1.9.1.11')) ne 'UnknownOID'){$host->{CC7}=$value;$host->{TRACE}.='182-';}

  $host->{MODEL}='U_O';
  if(($value=$self->request('.1.3.6.1.2.1.25.3.2.1.3.1')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='190-';}
  elsif(($value=$self->request('.1.3.6.1.2.1.1.1.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='192-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.2.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='192-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1347.43.5.1.1.1.1')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='193-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.2001.1.3.1.1.10.1.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='194-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.23.2.32.4.2.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='195-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.253.8.53.3.2.1.2.1')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='196-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.236.11.5.1.1.1.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='197-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1602.1.1.1.1.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='198-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1347.43.5.1.1.1.1')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='199-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.1.1.1.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='200-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.7.2.2.3.0')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='201-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.2.1.2.1.2.1')) ne 'UnknownOID'){$host->{MODEL}=$value;$host->{TRACE}.='202-';}

  $host->{FIRMWARE}='U_O';
  if(($value=$self->request('.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.6.0')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='210-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1248.1.2.2.2.1.1.2.1.3')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='211-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1248.1.2.2.2.1.1.2.1.4')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='212-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.1347.43.5.4.1.5.1.1')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='213-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.367.3.2.1.6.1.1.4.1')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='214-';}
  elsif(($value=$self->request('.1.3.6.1.4.1.641.1.1.1.0')) ne 'UnknownOID'){$host->{FIRMWARE}=$value;$host->{TRACE}.='215-';}

  $host->{DISPLAY1}=$host->{DISPLAY2}=$host->{DISPLAY3}=$host->{DISPLAY4}='';
  if(($value=$self->request('.1.3.6.1.2.1.43.16.5.1.2.1.1')) ne 'UnknownOID'){$host->{DISPLAY1}=$value;$host->{TRACE}.='220-';}
  if(($value=$self->request('.1.3.6.1.2.1.43.16.5.1.2.1.2')) ne 'UnknownOID'){$host->{DISPLAY2}=$value;$host->{TRACE}.='221-';}
  if(($value=$self->request('.1.3.6.1.2.1.43.16.5.1.2.1.3')) ne 'UnknownOID'){$host->{DISPLAY3}=$value;$host->{TRACE}.='222-';}
  if(($value=$self->request('.1.3.6.1.2.1.43.16.5.1.2.1.4')) ne 'UnknownOID'){$host->{DISPLAY4}=$value;$host->{TRACE}.='223-';}

  $host->{RESPONSE}='&L1='.$host->{SN}.'&L2='.$host->{TOTAL}.'&L3='.$host->{COLOR}.'&L4='.$host->{MC1}.
                    '&L5='.$host->{CC1}.'&L6='.$host->{MC2}.'&L7='.$host->{CC2}.'&L8='.$host->{MC3}.
                    '&L9='.$host->{CC3}.'&L10='.$host->{MC4}.'&L11='.$host->{CC4}.'&L12='.$host->{MC5}.
                    '&L13='.$host->{CC5}.'&L14='.$host->{MC6}.'&L15='.$host->{CC6}.'&L16='.$host->{MC7}.
                    '&L17='.$host->{CC7}.'&L18='.$host->{MODEL}.'&L19='.$self->{target}.'&L20='.$host->{FIRMWARE}.
                    '&L21='.$host->{DISPLAY1}.'&L22='.$host->{DISPLAY2}.'&L23='.$host->{DISPLAY3}.
                    '&L24='.$host->{DISPLAY4}.'&L90='.$host->{TRACE};

  return $host;
}

sub getmodel
{
  my $self=shift;
  my $answer=shift;
  my $host;
  my $i=0;

  $answer=~s/OK:OIDL#//;
  $host->{RESPONSE}='&';
  my @codes=split("#",$answer);
  foreach my $code(@codes)
  {
    $i++;
    $code=~/\!\!/;
    my $counterid=$`;
    my $oid=$';
    $counterid=~s/\AC/L/; # adapt Color to Legal
    $counterid=~s/\AB/L/; # adapt Black to Legal
    $counterid=~s/\AG/L/; # adapt Generic to Legal
    if($oid=~/\AMAC/)
    {
      $oid=~s/\AMAC//;
      $host->{RESPONSE}.=$counterid.'='.$self->request($oid,-type=>'MAC').'&';
    }
    else{
      $host->{RESPONSE}.=$counterid.'='.$self->request($oid).'&';
    }
  } 
  return $host;
}

sub listandcall
{
   my $self=shift;
   my %properties=@_; # rest of params by hash
   my $browser = LWP::UserAgent->new;
   if($self->{xml}->{proxy} ne '')
   {
     $browser->proxy(['http'],$self->{xml}->{proxy});
   }
   elsif($self->{xml}->{proxy} eq 'auto')
   { 
      $browser->env_proxy;
   }
   
   my $printers=0;
   my $verbose=0;
   $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};
   print "Proxy: $self->{xml}->{proxy}\n" if ($verbose && $self->{xml}->{proxy} ne '');

   my $devices=$self->{xml}->{devices}->{device};
   foreach my $device(@$devices)
   {
      $self->{target}=$device->{ip};
      print "Checking $self->{target}\n" if $verbose;
      if(my $sn=$self->checkip)
      {
        $printers++;
        print "Printer found: $sn\n" if $verbose;
        print "Connecting... " if $verbose;
        my $response = $browser->get($self->{url}.'&devid='.$sn);
        if($response->is_success)
        {
          print "OK\n" if $verbose;
          my $answer=$response->decoded_content;
          if($answer eq 'OK:GEN')
          {
            print "No defined model, using Generics.\n" if $verbose;
            if(my $host=$self->getgeneric)
            {
              print "Sending data\n" if $verbose;
              my $a=$browser->get($self->{url}.'&devid='.$sn.'&devread=1'.$host->{RESPONSE});
            }
            else
            {
               print "Error during the data validation.\n" if $verbose;
               return "ERROR: data validation failure";
            }
          }
          elsif($answer=~/OK:OIDL#.*/)
          {
              print "Model identified\n" if $verbose;
              my $host=$self->getmodel($answer);
              $browser->get($self->{url}.'&devid='.$sn.'&devread=1'.$host->{RESPONSE});
          }
          elsif($answer=~/OK:MR#.*/)
          {
               print "Maximun number of readings per day achieved.\n" if $verbose;
	      return "ERROR: Maximun number of readings per day achieved";
          }
          elsif($answer=~/OK:UP#.*/)
          {
            print "Error, please verify yor configuration.\n" if $verbose;
            return "ERROR: configuration fault";
          }
        }
        else
        {
          print "Connection failed!\n" if $verbose;
          return "ERROR: connection failed";
        }
      } 
    }
    print "$printers Printer(s) monitorized\n" if $verbose;
    return "OK $printers";
}

sub discoverandcall
{
   my $self=shift;
   my %properties=@_; # rest of params by hash
   my $browser = LWP::UserAgent->new;

   if($self->{xml}->{proxy} ne '')
   { 
      $browser->proxy(['http'],$self->{xml}->{proxy});
   }
   elsif($self->{xml}->{proxy} eq 'auto')
   { 
      $browser->env_proxy;
   }
   
   my $printers=0;
  
   my $verbose=0;
   $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};

   print "Proxy: $self->{xml}->{proxy}\n" if ($verbose && $self->{xml}->{proxy} ne '');

   my $devices=$self->{xml}->{devices}->{device};
   
   my $ranges=$self->{xml}->{range};
   foreach my $range(@$ranges)
   {
     if ($range->{lan} eq '')
     {
      my $testip=eval{$self->{address}=Net::Address::IP::Local->public};
      if($@){$self->{address}='127.0.0.1';}
     }
     else
     {
      $self->{address}=$range->{lan};
     }
     
     $self->{net}=$self->{address};
     $self->{net}=~s/\.\d*\Z//; # extract net from address

     my $init=1;
     my $end=254;
     $init=$range->{from} if defined $range->{from};
     $end=$range->{to} if defined $range->{to};
     print "Discovering LAN: $self->{net} [$init - $end] \n" if $verbose;
     for (my $i=$init;$i<=$end;$i++)
     {
        $self->{target}=$self->{net}.'.'.$i;
        print "Checking $self->{target}\n" if $verbose;
        if(my $sn=$self->checkip)
        {
          $printers++;
	  print "Printer found: $sn\n" if $verbose;
          my $response = $browser->get($self->{url}.'&devid='.$sn);
          if($response->is_success)
          {
            my $answer=$response->decoded_content;
            if($answer eq 'OK:GEN')
            {
	      print "No model identified, using Generics.\n" if $verbose;
              if(my $host=$self->getgeneric)
              {
                my $a=$browser->get($self->{url}.'&devid='.$sn.'&devread=1'.$host->{RESPONSE});
                print "Sending data.\n" if $verbose;
              }
              else
              {
		 print "Error during the data validation.\n" if $verbose;
                 return "ERROR: data validation failure";
              }
            }
            elsif($answer=~/OK:OIDL#.*/)
            {
	        print "Model identified.\n" if $verbose;
                my $host=$self->getmodel($answer);
                $browser->get($self->{url}.'&devid='.$sn.'&devread=1'.$host->{RESPONSE});
            }
            elsif($answer=~/OK:MR#.*/)
            {
                print "Maximum number of readings per day achieved.\n" if $verbose; 
	        return "ERROR: maximum number of readings per day achieved";
            }
            elsif($answer=~/OK:UP#.*/)
            {
                print "Error, please verify yor configuration.\n" if $verbose;
                return "ERROR: configuration fault";
            }
          }
          else
          {
             print "Connection failed!\n" if $verbose;
             return "ERROR: connection failed";
          }
        } 
      }
    }
    print "$printers Printer(s) monitorized\n";
    return "OK $printers";
}

sub listandmail
{
   my $self=shift;
   my %properties=@_; # rest of params by hash
   my $verbose=0;
   $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};

   my $printers=0;
   my $user=$self->{xml}->{mail}->{user};
   my $pass=$self->{xml}->{mail}->{pass};
   my $server=$self->{xml}->{mail}->{smtp};
   my $to=$self->{xml}->{mail}->{to};
   my $body_mail = "Mail sent by CPM - list\n\n#####\n";

   my $devices=$self->{xml}->{devices}->{device};
   foreach my $device(@$devices)
   {
      $self->{target}=$device->{ip};
      print "Checking $self->{target}\n" if $verbose;
      $printers++;
      print "Printer located\n" if $verbose;
      $body_mail.="\n\nDEVICE ".$device->{number}.": ".$self->{xml}->{id}->{user}."\n";
      my $oids=$device->{oid};print "\n";
      my @keys=keys(%$oids);
      foreach my $oid(@keys)
      {
	my $translate='Y';
	my $walk='N';
	if($oids->{$oid}->{content}=~/\AMAC.*/)
	{
		$translate='N';
	}
	if($oids->{$oid}->{content}=~/\AW.*/)
	{
		$walk='Y';
	}
	# filter any non OID
	$oids->{$oid}->{content}=~/..*/;$oids->{$oid}->{content}=$&;
	my $snmp;
	if($walk eq 'Y')
	{
		$snmp=$self->requesttable($oids->{$oid}->{content});
	}
	else
	{
		$snmp=$self->request($oids->{$oid}->{content});
	}
	if($translate eq 'N')
	{
		 $snmp=~s/0x//; # remove 0x00
                 $snmp=~s/.{2}/$&\:/g; # add the : every two digits
                 $snmp=~s/:\Z//; # remove the last :
                 $snmp=uc($snmp); # convert to capital letters
	}
        $body_mail.=" ".$oid.": ".$snmp."\n";
      } 
    }
    #Send the email
    print "Composing email..." if $verbose;
    my $smtp=Net::SMTP_auth->new($server);
    $smtp->auth('LOGIN',$user,$pass);
    $smtp->mail($user);
    $smtp->to($to);
    $smtp->data();
    $smtp->datasend("Subject: CPM $self->{xml}->{id}->{user}\n");
    $smtp->datasend("To: $to\n");
    $smtp->datasend("From: MyPrinterCloud\n");
    $smtp->datasend($body_mail);
    $smtp->dataend;
    $smtp->quit;
    print "Sent!\n" if $verbose ;
    return "OK $printers";
}

sub discoverandmail
{
   my $self=shift;
   my %properties=@_; # rest of params by hash
   my $verbose=0;
   $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};

   my $printers=0;
   my $user=$self->{xml}->{mail}->{user};
   my $pass=$self->{xml}->{mail}->{pass};
   my $server=$self->{xml}->{mail}->{smtp};
   my $to=$self->{xml}->{mail}->{to};
   my $body_mail = "Mail sent by CPM - list\n\n#####\n";

   my $ranges=$self->{xml}->{range};
   foreach my $range(@$ranges)
   {
     if ($range->{lan} eq '')
     {
      my $testip=eval{$self->{address}=Net::Address::IP::Local->public};
      if($@){$self->{address}='127.0.0.1';}
     }
     else
     {
      $self->{address}=$range->{lan};
     }
    
     $self->{net}=$self->{address};
     $self->{net}=~s/\.\d*\Z//; # extract net from address

     my $init=1;
     my $end=254;
     $init=$range->{from} if defined $range->{from};
     $end=$range->{to} if defined $range->{to};
     for (my $i=$init;$i<=$end;$i++)
     {
        $self->{target}=$self->{net}.'.'.$i;
        print "Checking $self->{target}\n" if $verbose;
        if(my $sn=$self->checkip)
        {
          $printers++;
	  print "Printer found: $sn\n" if $verbose;
          $body_mail.="\n\nDEVICE $printers: ".$self->{xml}->{id}->{user}."\n";
          my $host=$self->getgeneric;
          $body_mail.=$host->{RESPONSE}."\n";
        } 
     }
   }
   #Send the email
   print "Composing email..." if $verbose;
   my $smtp=Net::SMTP_auth->new($server);
   $smtp->auth('LOGIN',$user,$pass);
   $smtp->mail($user);
   $smtp->to($to);
   $smtp->data();
   $smtp->datasend("Subject: CPM $self->{xml}->{id}->{user}\n");
   $smtp->datasend("To: $to\n");
   $smtp->datasend("From: MyPrinterCloud\n");
   $smtp->datasend($body_mail);
   $smtp->dataend;
   $smtp->quit;
   print "Sent!\n" if $verbose ;
   return "OK $printers";
}

sub auto
{
   my $self=shift;
   my %properties=@_; # rest of params by hash
   my $verbose=0;
   $verbose=$properties{'-verbose'} if defined $properties{'-verbose'};
   if($self->{xml}->{id}->{comm} eq 'call')
   {
	print "Using CALL" if $verbose;
	if($self->{xml}->{id}->{mode} eq 'list')      
	{
		print " with a LIST\n" if $verbose;
		return $self->listandcall(-verbose=>$verbose);
	}
	else
	{
		print " and DISCOVERING\n" if $verbose;
		return $self->discoverandcall(-verbose=>$verbose);
	}
    }
    else
    {
	if($self->{xml}->{id}->{mode} ne 'list')
	{
		print "Discover and Email\n" if $verbose;
                return $self->discoverandmail(-verbose=>$verbose);
	}
	else
	{
                print "Using SMTP-auth from a fixed list and OIDs\n" if $verbose;	
	        return $self->listandmail(-verbose=>$verbose);
	}
    }
}


1;

__END__

=head1 NAME

CPM - Complete module to work with MyPrinterCloud System

=head1 SYNOPSIS

 use CPM;
 my $env=CPM->new();
 $env->auto(-verbose=>1);

=head1 DESCRIPTION

The CPM module manages the API of MyPrinterCloud, providing the subroutines to collect the information from the networked printers and to transmit it to CPS (Cloud Printing Server). It offers several options to accomplish key design criteria such as non-invasive, open, flexible, standard and scalable.

=head1 FUNCTIONALITY

The CPM functionality is completely defined by its configuration file (config.xml) that acts also, as firmware of the module.

=head1 Configuration sample

The CPM needs a default configuration file that must be adjusted by the user, at least, including his credentials (valid user in MyPrinterCloud).

<?xml version="1.0" encoding="UTF-8"?>
  <opt call="http://myprintercloud.nubeprint.com/np/selector.pl" proxy="" >
    <id comm="call" 
        date="2010-09-10"
        mode="discover"
        pass="xxx"
        type="soft-public"
        user="demo@nubeprint.com"
    />
    <range from="105" to="115" lan=""/>
  </opt>

=head2 ID section

=over 3
 
=item comm [email,call]: it defines the communication method

=item mode [discover,list]: set if the CPM must discover the network or only collect data from the printers previously identified in a list

=item user: email account valid on the CPS or MyPrinterCloud

=item pass: password of a valid user of the CPS or MyPrinterCloud

=item type: optional

=item date: date when the configuration file was built by the CPS.

=back

=head2 Communication channel 

Communication with the CPS accepts two different forms depending on the needs of the destination network. Also, note that although there are two mechanisms you can activate only one per CPM.

=head3 Call

This method is based on the HTTP standard, which operates in real time and is bidirectional. That allows the CPM apply the latest set of OIDs to be queried for a particular machine. Although an HTTP connection is needed, it is a very efficient solution.

<call="http://myprintercloud.nubeprint.com/np/selector.pl"/>

=head3 Email

This method is based on the SMTP standard with Auth support. When it's activated, the CPM collects all the information from the networked printers, composes a summary email, and sends it to the CPS. Obviously it is not bidirectional, nor in real-time, but in some cases this solution provides the Administrator an easier way to check or audit the information being transmitted.

<mail pass="yyy" smtp="myprintercloud.com" user="aaa@myprintercloud.com"/>

=head2 Modes

=head3 Discover

If this method is enabled, the CPM discovers all the networked printers and for each one, it will request information to the CPS (if it's already registered, its model, the set of OIDs, ...). The CPM auto-detects the local net in order to make a scanning of the LAN.

=head4 Range

The default discover behaviour can be modified specifying the local range and the subnet in where the CPM should scan. By default the CPM assumes the local net and from 1 to 254.

<range from="105" to="110" lan="192.168.2.0"/>

=head3 List

In this case the CPM gets a list of printers (section devices, embedded into the config file) to read, and for each one, it has already all the information needed to make a successful request.

	<devices>
	    <device ip="192.168.2.108" number="0">
	      <oid name="C1">.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.3.0</oid>
	      <oid name="C18">.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.2.0</oid>
	      <oid name="C2">.1.3.6.1.2.1.43.10.2.1.4.1.1</oid>
	      <oid name="C4">.1.3.6.1.2.1.43.11.1.1.8.1.1</oid>
	      <oid name="C5">.1.3.6.1.2.1.43.11.1.1.9.1.1</oid>
	      <oid name="C59">.1.3.6.1.2.1.43.11.1.1.8.1.2</oid>
	      <oid name="C60">.1.3.6.1.2.1.43.11.1.1.9.1.2</oid>
	    </device>
	     <device ip="192.168.2.109" number="1">
	      <oid name="C1">.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.3.0</oid>
	      <oid name="C18">.1.3.6.1.4.1.11.2.3.9.4.2.1.1.3.2.0</oid>
	      <oid name="C2">.1.3.6.1.2.1.43.10.2.1.4.1.1</oid>	
	      <oid name="C4">.1.3.6.1.2.1.43.11.1.1.8.1.1</oid>
	      <oid name="C5">.1.3.6.1.2.1.43.11.1.1.9.1.1</oid>
	      <oid name="C59">.1.3.6.1.2.1.43.11.1.1.8.1.2</oid>
	      <oid name="C60">.1.3.6.1.2.1.43.11.1.1.9.1.2</oid>
	    </device>
	</devices>

=head1 CLASS

 use CPM;
 my $env=CPM->new();

=head1 HIGH-LEVEL SUBROUTINES

The CPM exports several subroutines to allow the developer to choose the way to handle the different transactions.

=over 4
 
=item new([-config=>'config.xml'])

Create the object to handle the readings and the data transaction

=item auto([-verbose=1]

Complete the transaction using the directives from the configuration file

=item listandcall([-verbose=1])

Read printers of a List provided by the configuration file and use the Call method to send the data

=item listandmail([-verbose=1])

Read printers of a List provided by the configuration file and send the data by email

=item discoverandcall([-verbose=1])

Discover the networked printers and use the Call method to send the data

=item discoverandmail([-verbose=1])

Discover the networked printers and send the data by email

=back

=head1 MEDIUM-LEVEL SUBROUTINES

=over 4

=item saveconfig

Save the configuration data into the xml file

=item request($oid,[-type=>MAC|SN])

Make an SNMP request to read any OID.
If MAC, it converts the hex values into an string like AA:BB:CC:DD
If SN, it checks that it's a valid string. Enough lenght, and not resetted.
Always converts the hex to ASCII strings

=item requesttable

Make an SNMP walk request to read a complete branch

=item checkip

Determinate if exists an actived printer using the IP. If yes, it returns its SN

=item getgeneric

Read the Generics. It uses the common OIDs to try to identify the printer model and collect the basic information.

=item getmodel

Read the specific model of printer. This function receives information from the CPS (OIDs of the model) and performs a specific SNMP request.

=back

=head1 AUTHOR

Juan Jose 'Peco' San Martin, C<< <peco at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 NubePrint

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
