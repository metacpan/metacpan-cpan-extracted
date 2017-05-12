package Apache::Session::MemcachedClient;
use Apache::Session::Memorycached;
use Fcntl qw(:DEFAULT :flock);
$| = 1;
our $VERSION = '2.1.1';

sub new {
    my $class = shift;
    my %args  = @_;
    my $self;
    $self = \%args;
    bless $self, $class;

}

sub run {

    my $self        = shift;
    my $file_input  = $self->{in_file};
    my $file_output = $self->{out_file};
    my $naptime     = $self->{naptime} || '1';
    my $safetime    = $self->{safetime} || '900';    # 15 minutes

    for ( ; ; ) {
        sysopen( FH, $file_input, O_RDWR | O_CREAT ) || die "$file_input $!\n";
        flock( FH, LOCK_EX );
        my @ligne = <FH>;
        seek( FH, 0, 0 );
        truncate( FH, 0 );
        close(FH);
        my @log;
        for (@ligne) {
            ( my $session, my $time ) = /^(\w+)\s(\d+)/;
### retrieve session
            my $param = $self->{localmemcached};
            my $sign  = $self->{signature} || 'master';

            my %localsession;
            my %remotesession;
            tie %localsession, 'Apache::Session::Memorycached', $session,
              $param;
            if ( !%localsession ) {

### error in retrieve session
                untie %localsession;
                push @log, "FATAL :$session FAILED \n";
                next;

            }
            my %_localsession = %localsession;
            untie %localsession;

#######################################
##  avoid loop in master2master case ##
#######################################
            if ( $_localsession{$sign} ) {
### pehap already replicated
                #   exept in this case
                my $time_origine = $_localsession{$sign};
                $time_origine =~ s/#.+$//;
                if ( ( time - $time_origine ) < $safetime ) {
                    push @log, "INFO :$session SYN OK\n";
                    next;
                }

            }

            $_localsession{$sign} = time . "#" . $time;

#### and send this to the other server
            my $paramdist = $self->{remotememcached};

#####  ne marche pas $session exist ########
            my %remotesession;
            tie %remotesession, 'Apache::Session::Memorycached', $session,
              $paramdist;

            if (%remotesession) {
### error in retrieve remote session
                my $time_origine = $remotesession{$sign};
                $time_origine =~ s/#.+$//;
                next if ( ( time - $time_origine ) < $safetime );
            }

            %remotesession = %_localsession;
            untie %remotesession;

            push @log, "INFO :$session REPLICATED\n";

            if ( $self->{safety_mode} ) {
                my %remotesession;
### we retrieve session from the other memcached server
                my $paramdist = $self->{remotememcached};
                tie %remotesession, 'Apache::Session::Memorycached', $session,
                  $paramdist;

                my %_remotesession = %remotesession;
                untie %remotesession;

                if ( $_remotesession{$sign} ) {
                    push @log, "INFO :$session VERIFIED\n";
                }
                else {
                    push @log, "FATAL :$session REPLICATION ERROR\n";
                }
            }

        }

        sysopen( FS, $file_output, O_WRONLY | O_APPEND | O_CREAT )
          || die "$file_output $!\n";
        flock( FS, LOCK_EX );
        for (@log) {
            print FS $_;
        }
        close(FS);
        sleep $naptime;

    }
}
1;



=pod

=head1 NAME

Apache::Session::MemcachedClient - A component of memcached's replication 

=head1 SYNOPSIS

 use Apache::Session::MemcachedClient ;
 my $rep = MemcachedClient->new(in_file =>"/tmp/logmem1",
                            out_file =>"/tmp/log1",
                            naptime => 2 ,
                     localmemcached => {'servers' => ['localhost:11211'],  },  
                     remotememcached =>{'servers' => ['localhost:11311'],  },
                     signature  => 'master11211',
		     safety_mode   =>'actived' , 
 );
 $rep->run ;
 exit;


=head1 DESCRIPTION

This module is an implementation of replication for memcached backend session storage .  It replicates session created by Apache::Session::Memorycached between master to slave OR  master to master.

In input , it reads a file issued from Apache::Session::MemcachedReplicator then it sends session on the other memcached server .


The lemonldap project (SSO under GPL)  uses this module 

=head1 Options

 - in_file : input file .
 - out_file : log in output file 
 - naptime :  time between 2 cycles (in second)
 - localmemcached : you local server 
 - remotememcached : you remote server (pehap the slave) 
 - signature : string used in order to avoid loops replication
 - safety_mode : thrue : read on remote server after write in order to be sure of success of replication

  see client_memcached.pl in script  directory.

 
=head1 AUTHOR

This module was written by eric german <germanlinux@yahoo.fr>.
 

=head1 SEE ALSO


L<Apache::Session::MemcachedReplicator>, 
L<Apache::Session::Memorycached>,

