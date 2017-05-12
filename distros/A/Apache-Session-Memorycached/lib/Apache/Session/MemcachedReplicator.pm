package Apache::Session::MemcachedReplicator;
use Fcntl qw(:DEFAULT :flock) ;
our $VERSION = '2.1.1';
$| =1;

sub new {
my $class =shift;
my %args = @_;
my $self;
$self=\%args;;
bless $self,$class;

}

sub run {
    my $self =shift;
my $file_input = $self->{in_file} ; 
my $file_output = $self->{out_file} ; 
my $naptime= $self->{naptime}||'1';


for(;;) {
sysopen (FH,$file_input, O_RDWR|O_CREAT) ||die "$file_input $!\n";
flock (FH,LOCK_EX);
my @ligne = <FH> ;
seek (FH,0,0);
truncate (FH,0);
close(FH) ;
my  %un_id;
for (@ligne) {
      if (/\sset\s/ ) {
(	my $session) = /set\s(\w+)\s/ ;
$un_id{$session} = time ;
} 
}
sysopen (FS,$file_output, O_WRONLY|O_APPEND|O_CREAT)||die "$file_output $!\n";
flock (FS,LOCK_EX);
for (keys %un_id) {
  print FS "$_ $un_id{$_}\n"; 
}
close (FS) ;  
   sleep $naptime;

}
}
1;




=pod

=head1 NAME

Apache::Session::MemcachedReplicator - A component of memcached's replication 

=head1 SYNOPSIS

 use Apache::Session::MemcachedReplicator ;
 my $rep = MemcachedReplicator->new(in_file =>"/tmp/memcachedlog",
                                    out_file =>"/tmp/logmem",
                                    naptime => 2 ,
                                   );
 $rep->run ;
 exit;


=head1 DESCRIPTION

This module reads log's memcached server and write one line by 'set' command .   
In order to force memcached to be verbose you must laugth it like this: 
  memcached -u root -p 11211 -vv 2> /tmp/logmem1 &

The memcached log file must to be in input of MemcachedClient .
 

The lemonldap project (SSO under GPL)  uses this module. 

=head1 Options

 - in_file : input file .
 - out_file : write in output file 
 - naptime :  time between 2 cycles (in second)


  see slurp_memcached.pl in script directory.

 
=head1 AUTHOR

This module was written by eric german <germanlinux@yahoo.fr>.
 

=head1 SEE ALSO


L<Apache::Session::MemcachedClient>, 
L<Apache::Session::Memorycached>,






