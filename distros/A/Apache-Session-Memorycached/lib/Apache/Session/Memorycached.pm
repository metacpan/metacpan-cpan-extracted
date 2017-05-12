#############################################################################
#
# Apache::Session::Memorycached
# Apache persistent user sessions on the network with memcached
# Copyright(c) eric german <germanlinux@yahoo.fr>
# Distribute under the Artistic License
#
############################################################################

package Apache::Session::Memorycached;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.2.1';
@ISA = qw(Apache::Session);

use Apache::Session;
use Apache::Session::Generate::MD5;
use Apache::Session::Lock::Memorycached;
use Apache::Session::Store::Memorycached;

sub populate {
    my $self = shift;

    $self->{object_store} = new Apache::Session::Store::Memorycached $self;
    $self->{lock_manager} = new Apache::Session::Lock::Memorycached $self;
    $self->{generate}     = \&Apache::Session::Generate::MD5::generate;
    $self->{validate}     = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize}    = \&Apache::Session::Memorycached::none;
    $self->{unserialize}  = \&Apache::Session::Memorycached::none;

    return $self;
}

sub none {
    my $self    = shift;
    my $session = shift;
return;
 }
 sub DESTROY {
    my $self = shift;
    
    $self->save;
    $self->{object_store}->close;
    $self->release_all_locks;
}

1;


=pod

=head1 NAME

Apache::Session::Memorycached - An implementation of Apache::Session

=head1 SYNOPSIS

 use Apache::Session::Memorycached;
 
    tie %session, 'Apache::Session::Memorycached', $cookie, {
          'servers' => ["10.75.1.19:11211"], #all write operations
          'local'  =>  ["localhost:11211"],  #read-only operations
          'timeout' => '300'
     };

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
 




=head1 DESCRIPTION

This module is an implementation of Apache::Session.  It uses the memcached system backing
store .  You may specify servers (principal)  and locals caches for locking in arguments to the constructor. See the example, and the documentation for Apache::Session::Store::Memorycached  and Cache::Memcached .


=head1 REPLICATION
  
 Now Apache::Session::Memorycahed inclues replication between memecached servers 
 Two new components provide a replication service . 
 First package is Apache::Session::MemcachedReplicator
 Second is Apache::Session::MemcachedClient 

 It's now possible to do replication master to slave or master to master
 see man pages and scripts .


=head1 SOAP service

 Now Apache::Session::Memorycached inclues a SOAP service in order to set or 
 get %session in any language . The SOAP service translates data in Perl hashes
 
=head2 Installation of SOAP service 
 
 All scripts are in scripts directory

 Put MemcachedSOAPClass.pm and MemcachedSOAP.cgi in the cgi-bin directory of your apache server with the appropriate right (x) . 
 Change in MemcachedSOAP.cgi the memcached server address .
  (line 11 : $machine = 'ip.ip.ip.ip:11211';  )
  
 Try the three scripts  statTest.pl (first !)  then getTest.pl finish with setTest.pl. 
 

The lemonldap project (SSO under GPL)  uses this module 

=head1 AUTHOR

This module was written by eric german <germanlinux@yahoo.fr>.
 
 Completed by  Habib ZITOUNI <zitouni.habib@gmail.com> and 
Hamza AISSAT<asthamza@hotmail.fr>
 
 SOAP service is a contribution of  Casimir ANTUNES .

=head1 SEE ALSO

L<Apache::Session::DB_File>, L<Apache::Session::Flex>,
L<Apache::Session::MemcachedClient>,L<Apache::Session::MemcachedReplicator>,
L<Apache::Session::MySQL>, L<Apache::Session::Postgres>, L<Apache::Session>
