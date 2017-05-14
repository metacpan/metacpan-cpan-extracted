##
## Schedule::Chronic::Logger
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Logger.pm,v 1.2 2004/07/26 23:12:49 hackworth Exp $
##

package Schedule::Chronic::Logger;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Errno qw(:POSIX);
use Data::Dumper;
use Sys::Syslog qw(:DEFAULT setlogsock);

# Preloaded methods go here.

sub new {

    my ($class, %args) = @_;

    my %self = (%args);

    $self{facility} ||= 'daemon';
    $self{name}     ||= 'Chronic';

    # Open a connection to syslog over a UNIX socket. 
    if ($args{type} eq 'syslog') { 

        openlog('Chronic', 'cons,pid', 'user'); 
        setlogsock('unix');

    }

    # Syslog priorities and facilities. These are also used with
    # logging to STDERR.
    $self{syslog_priorities} = {

        emerg   => 0,
        alert   => 1,
        crit    => 2,
        err     => 3,
        warning => 4,
        notice  => 5,
        info    => 6,
        debug   => 7

    };

    $self{syslog_facilities} = {

        kern	=> 0,
        user	=> 1,
        mail	=> 2,
        daemon	=> 3,	
        auth	=> 4,
        syslog	=> 5,
        lpr	    => 6,
        news 	=> 7,
        uucp 	=> 8,
        cron	=> 9,
        authpriv=> 10,
        ftp	    => 11,
        local0	=> 16,
        local1	=> 17,
        local2	=> 18,
        local3	=> 19,
        local4	=> 20,
        local5	=> 21,
        local6	=> 22,

    };

    return bless \%self, $class;

}


sub logthis {

    my ($self, $msg, $prio) = @_;

    # Default priority is 'debug'
    $prio ||= 'debug';

    if ($$self{type} eq 'syslog') { 

        syslog("$$self{facility}|$prio", $msg);

    } elsif ($$self{type} eq 'stderr') { 
        $msg =~ s/^.+?:://;
        print STDERR "debug: $msg\n";
    }

}


1;
