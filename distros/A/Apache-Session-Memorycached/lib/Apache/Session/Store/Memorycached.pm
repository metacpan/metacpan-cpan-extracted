############################################################################
#
# Apache::Session::Store::Memorycached
# Implements session object storage via memcached 
# Copyright(c) eric german <germanlinux@yahoo.fr>     
# Distribute under the Artistic License
#
############################################################################

package Apache::Session::Store::Memorycached;

use strict;
use Symbol;
use Data::Dumper;
use Cache::Memcached;
use Digest::MD5 qw(md5_hex);
use vars qw($VERSION);
$VERSION = '2.2';


sub new {
#This constructor allocate memory space for for the package!!
    my $class = shift;
    my $self;
	$self->{opened} = 0;
    
    return bless $self, $class;
}


sub insert {
#This function is called, when a tie instruction is launch with an undef id 
#Otherwise at the first identification ( cf Login.pm )
my $self    = shift;
my $session = shift;

	if (! exists $session->{args}->{updateOnly} 
		 || $session->{args}->{updateOnly} != 1 ) {

		 my $retour;
		 my $ryserver = $session->{args}->{servers};
		 my $ryserverlocal = $session->{args}->{local};
		 my $rytimeout = $session->{args}->{timeout}||'0';
		 my $memd= new Cache::Memcached  { 'servers' => $ryserver };
		 my $ident = $session->{data}->{_session_id}; 
		 my $rhash = $session->{data};
		 $retour = $memd->set($ident,$rhash,$rytimeout);
		if($retour!=1){
			$memd->set($ident,$rhash,$rytimeout);		
		}
		 if ($ryserverlocal)
		     {
		 my $memdlocal= new Cache::Memcached  { 'servers' => $ryserverlocal};
		 my $identlocal = $session->{data}->{_session_id};
		 my $rhashlocal = $session->{data};
		 $retour = $memdlocal->set($identlocal,$rhashlocal,$rytimeout);
		if($retour!=1){
			$memdlocal->set($identlocal,$rhashlocal,$rytimeout);
		}
		      
		
		}
	}
	
	$self->{opened} = 1;
 
 }

sub update {
    my $self    = shift;
    my $session = shift;
 my $retour;
 my $ryserver = $session->{args}->{servers};
 my $ryserverlocal = $session->{args}->{local};
 my $rytimeout = $session->{args}->{timeout}||'0';
 my $principalkey;
 my $keyvalue;
my $memd= new Cache::Memcached  { 'servers' => $ryserver };
 
my $ident = $session->{data}->{_session_id} ;
 my $rhash = $session->{data};
if ( $session->{args}->{principal} ) {
$principalkey =  $session->{args}->{principal} ;
$keyvalue= $session->{data}->{$principalkey} ;
$keyvalue =  md5_hex($keyvalue) ; 
$memd->set($keyvalue,$ident,$rytimeout) if $keyvalue;
my $identp = $principalkey.'_MD5';
$session->{data}->{$identp} = $keyvalue ;
}
$retour =  $memd->set($ident,$rhash,$rytimeout);



if($retour!=1){


}

if ($ryserverlocal)
    {
 my $memdlocal= new Cache::Memcached  { 'servers' => $ryserverlocal};
 my $identlocal = $session->{data}->{_session_id}; 
 my $rhashlocal = $session->{data};
####  in order to prepare identify federation ####
if ( $session->{args}->{principal} ) {
$memdlocal->set($keyvalue,$identlocal,$rytimeout) if $keyvalue;
}

 $retour = $memdlocal->set($identlocal,$rhashlocal,$rytimeout);



if($retour!=1){


}


     }
##################################################
 $self->{opened} = 1;
}

sub materialize {
    my $self    = shift;
    my $session = shift;

my $ryserver = $session->{args}->{servers};
my $rhash; 
my $ryserverlocal = $session->{args}->{local};
my $rytimeout = $session->{args}->{timeout}||'0';
  if ($ryserverlocal)
     {
 my $memdlocal= new Cache::Memcached  { 'servers' => $ryserverlocal};
 my $identlocal = $session->{data}->{_session_id}; 
 $rhash = $memdlocal->get($identlocal);
     }
 #####
 ####
 ####
 my @tabkey = keys (%{$rhash}) ;
 if ($#tabkey <1)     
          {
	  ### not found in local cache , I retrieve session on primary server
	   #print STDERR "MATERIALIZE : RIEN SUR SERVEUR LOCAL $$ !!!\n";
   	   my $memd= new Cache::Memcached  { 'servers' => $ryserver };
           my $ident = $session->{data}->{_session_id};
           $rhash = $memd->get($ident);
		if(!defined($rhash)){
			

		}
 ## the data is in the  principal cache notin the local cache 
 ##  we must put data in it.
            if ($ryserverlocal && $rhash)
                  {
			#print STDERR "MATERIALIZE : REPERCUSSION SUR SERVEUR LOCAL $$ !!!\n";
                     my $memdlocal= new Cache::Memcached  { 'servers' => $ryserverlocal};
		     my $identlocal = $session->{data}->{_session_id};
                     #### oups !  ....bug corrected 
                     # my $rhashlocal = $session->{data};mistake
                      my $rhashlocal = $rhash;
                      $memdlocal->set($identlocal,$rhash,$rytimeout);
                     if($!){

			
                     }
		}

            }

 $self->{opened} = 1;
 
$session->{data} =$rhash;
#if(!defined($rhash)){
#$session->{error} = 1;
#                }
  
}    

sub remove {
    my $self    = shift;
    my $session = shift;

    my $ryserver = $session->{args}->{servers};


my $memd= new Cache::Memcached  { 'servers' => $ryserver};
    my $principalkey;
    my $identp;
    my $keyvalue;
    my $ryserverlocal = $session->{args}->{local};
    my $ident = $session->{data}->{_session_id} ;
if ( $session->{args}->{principal} ) {

      $principalkey =  $session->{args}->{principal} ;
      $identp = $principalkey.'_MD5';
      $keyvalue= $session->{data}->{$identp} ;
      $memd->delete($keyvalue) if $keyvalue ;
  }
            $memd->delete($ident);  
     if ($ryserverlocal)
          {
            my $memdlocal= new Cache::Memcached  { 'servers' => $ryserverlocal };
            my $identlocal = $session->{data}->{_session_id}; 
         $memdlocal->delete($keyvalue) if $keyvalue ;
         $memdlocal->delete($identlocal);
           }
 
   $self->{opened} = 0;
    
    }

sub close {
    my $self = shift;

    if ($self->{opened}) {
        $self->{opened} = 0;
    }
}

sub DESTROY {
    my $self = shift;

    if ($self->{opened}) {    
    }
}

1;

=pod

=head1 NAME

Apache::Session::Store::Memorycached - Store persistent data on the network with  memcached

=head1 SYNOPSIS


 use Apache::Session::Store::Memorycached;
 
 my $store = new Apache::Session::Store::Memorycached;
 
 $store->insert($ref);
 $store->update($ref);
 $store->materialize($ref);
 $store->remove($ref);

=head1 DESCRIPTION

This module fulfills the storage interface of Apache::Session.  The serialized
objects are stored in files on your network in unused memory 

=head1 OPTIONS

This module requires one argument in the usual Apache::Session style.  The
name of the option is servers, and the value is the  same of memcached .
 Example

 tie %s, 'Apache::Session::Memorycached', undef,
    {servers  => ['mymemcachedserver:port'],
     'timeout' => '300',
     'updateOnly' => 1 ,
     'principal' => uid,  
        };

In order to optimize the network ,you can use a local memcached server.
All read-only opération are sending fisrt at local server .If you need write ou rewrite data , the data is sending at the principal memcached sever and local cache too  for synchronisation.

note :  'updateOnly' => 1  just realize up-date operation not init operation. 
 Init operation is use in order to book and lock the number session but it's not available in this module 
 
  'principal' => uid :  this  parameter is use to create reverse reference 
  like this : MD5_hex(uid) => id_session in memcached server . By this it usefull to retrieve id_session from principal name . And add uid_MD5 => MD5_hex(uid) in main session .
 

=head1 NOTES


=head1 AUTHOR

This module was written by eric german <germanlinux@yahoo.fr> 

=head1 SEE ALSO

L<Apache::Session>
