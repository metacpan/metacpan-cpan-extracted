package App::Validation::Automation;

use Carp;
use Switch;
use Moose;
use Net::SSH::Perl;
use namespace::autoclean;
use English qw(-no_match_vars);

=head1 NAME

App::Validation::Automation 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use App::Validation::Automation;

    my $obj = App::Validation::Automation->new(
        config          => \%config,
        log_file_handle => $log_handle,
        user_name       => $config{'COMMON.USER'},     #Optional Parameter
        password        => $config{'COMMON.PASSWORD'}, #Optional Parameter
        site            => $config{'COMMON.SITE'},     #Optional Parameter
        zone            => $config{'COMMON.ZONE'},     #Optional Parameter
        secret_pphrase  => $secret_pphrase,            #Optional Parameter
    );

    $success = $obj->validate_urls();
    $success = $obj->test_dnsrr_lb();
    $success = $obj->validate_processes_mountpoints();

    #Or, If config is small

    my $obj = App::Validation::Automation->new(
        config          => {
            'COMMON.SSH_PROTO'    => '2,1',
            'COMMON.ID_RSA'       => [
                                        /home/user/.ssh/id_rsa1, 
                                        /home/user/.ssh/id_rsa2
                                     ],
            'COMMON.DEFAULT_HOME' => /home/user/App/Validation,
            'COMMON.LOG_DIR'      => /home/user/App/Validation/log,
            'COMMON.LINK'         => http://ap.xyz.com/loginproxy_servlet,
            'COMMON.PROCESS_TMPL' => ps -eaf |grep -i %s|grep -v grep|wc -l
            'COMMON.FILESYS_TMPL' => cd %s
            'HOSTNAME1.PROCESSES' => [BBL:1, DMADM:],
            'HOSTNAME1.FILE_SYS'  => [/home, /],
            'HOSTNAME2.PROCESSES' => [BL:1, DADM:],
            'HOSTNAME2.FILE_SYS'  => [/home, /],
            'HOSTNAME2.LINKS'     => [
                                        http://hostname2.xyz.com:6666,
                                        http://hostname2.xyz.com:6667, 
                                     ]
        },
        log_file_handle => $log_handle,
        user_name       => $config{'COMMON.USER'},     #Optional Parameter
        password        => $config{'COMMON.PASSWORD'}, #Optional Parameter
        site            => $config{'COMMON.SITE'},     #Optional Parameter
        zone            => $config{'COMMON.ZONE'},     #Optional Parameter
        secret_pphrase  => $secret_pphrase,            #Optional Parameter
    );
   
   #Verify All links - calls validate_url for all links under each host
   $ret = $obj->validate_urls();
   #Verify filesystems and processes on remote hosts- calls connect,validate_process
   #and validate_mount for all processes and filesystems on all remote hosts 
   $ret = $obj->validate_processes_mountpoints();
   #DNS Round Robin and Load Balancing functionality Check - Calls dnsrr and lb 
   #for common link
   $ret = $obj->test_dnsrr_lb();

   #Or,do most of the stuff yourself and based on success/failure log/mail
   $ret = $obj->validate_url("http://cpan.org");
   $ret = $obj->dnsrr("http://abc.com",10,2);
   $ret = $obj->lb("http://abc.com",10,2);

   $ret = $obj->connect("abc.xyz.com","user");
   $ret = $obj->validate_process("BBL:4","ps -eaf|grep %s|wc -l");
   $ret = $obj->validate_mountpoint("/home","cd %s");
   

=head1 DESCRIPTION
    
A Validation Framework to check if your Application is running fine or not.This module can be used for Applications that are built on Unix and have a Web interface.
The suite has the capabilty to check Application web urls for accessiblity,and also login into each of those urls to ascertain database connectivity along with sub 
url accessbility.One can also verfiy processes and mountpoints on the remote hosts which house the application. The password for logging into the web urls is stored 
in an encrypted file.The Module also has capability to test if Load Balancing and DNS Round Robin is funtioning.High Availabilty Web applications use Load Balancing 
and DNS Round Robin to add redundancy,high availability, and effective load distribution among the various servers(Web,Application, and Database servers).Further to
frontend validations the module provides methods to validate the backend.To carryout backend verification it connects to remote hosts using SSH.Backend verfication 
involves checking if correct not of processe are running and file systems are accessible.App::Validation::Automation is driven by a tunable configuration file(sample 
config bundled with this distribution)which is formated in Windows .ini format.Please take a look at the configuration file under config/.

=head1 INHERITANCE,ATTRIBUTES AND ROLES

App::Validation::Automation Class leverages App::Validation::Automation::Web and App::Validation::Automation::Unix to perform Web and Unix level validations.It also acts as an application logger,alarmer and log purger.

=cut

extends 'App::Validation::Automation::Web','App::Validation::Automation::Unix';

has 'config' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

has 'log_file_handle' => (
    is       => 'rw',
    isa      => 'FileHandle',
    required => 1,
);

has 'inaccessible_urls' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
);

has 'faulty_processes' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
);

has 'faulty_mountpoints' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
);

has 'hostname' => (
    is      => 'rw',
    isa     => 'Str',
);

has 'secret_pphrase' => (
    is      => 'ro',
    isa     => 'Str',
);

with 'App::Validation::Automation::Logging',
     'App::Validation::Automation::Alarming',
     'App::Validation::Automation::Purging';

=head1 METHODS

=head2 validate_urls

Check various web links stored in config file for accessibility.The real work is done by validate_url method of App::Validation::Automation::Web class.Returns true on success and false on failure.Handles password expiration along with authentication failure.On password expiry calls change_web_pwd and change_unix_pwd to change password at both Web and Unix level.Notifies via text page and email and also logs the error message.

=cut

sub validate_urls {
    my $self   = shift;
    my ($msg, @inaccessible_urls, $subject, $body, $url);

    foreach my $key ( keys %{$self->config} ) {
        if($key =~ /LINKS/i) {
            local $WARNING = 0;
            foreach my $url(@{$self->config->{$key}}) {
                $self->validate_url($url);
                switch ($self->web_msg) {
                    case /Password.+?Expired/i {
                        &{$self->_error_handler($url)->{PASSWORD_EXPIRED}};
                    }
                    case /Authentication.+?Failure/i {
                        &{$self->_error_handler($url)->{AUTHENTICATION_FAILURE}};
                    }
                    case /Missdirected/i {
                        &{$self->_error_handler($url)->{MISSDIRECTED}};
                        push @inaccessible_urls,$url;
                    }
                    else {
                        &{$self->_error_handler($url)->{SUCCESS}};
                    }
                }
            }
        }
    }

    if ( @inaccessible_urls ) {
        $subject = "App Valildation -> Failed";
        $body    = "Following Links were not accessible ->\n";
        $body    .= join "\n", @inaccessible_urls;
        $body    .= "\nRefer logs under".$self->config->{'COMMON.LOG_DIR'}." for details";

        #$self->inaccessible_urls( \@inaccessible_urls );
        $self->mail( $subject, $body );
        $self->log( $self->mail_msg );

        $self->page( $subject, $body );
        $self->log( $self->page_msg );

        return 0;
    }
    return 1;
}

=head2 test_dnsrr_lb

Validates if DNS Round Robin and Load Balancing feature is working fine or not.

=cut

sub test_dnsrr_lb {
    my $self       = shift;
    my ($msg, @inaccessible_urls, $return, $subject, $body,
        $fail_flag, $ret, $url, $max_requests, $min_unique);
    $url           = $self->config->{'COMMON.LINK'};
    $max_requests  = $self->config->{'COMMON.MAX_REQ'};
    $min_unique    = $self->config->{'COMMON.MIN_UNQ'};
    $subject       = "App Valildation -> Failed";

    if($self->dnsrr($url, $max_requests, $min_unique)) {
        $self->log( "DNS Round Robin Validated " );
    }
    else {
        $msg = $self->config->{'COMMON.LINK'}.$self->web_msg;
        $self->log( $msg );

        $body = "DNS Round Robin Validation Failed\n";
        $body .= "\nRefer logs under".$self->config->{'COMMON.LOG_DIR'}." for details";
        $self->mail( $subject, $body );
        $self->log( $self->mail_msg );

        $fail_flag = 1;
        $self->clear_web_msg;
    }

    if($self->lb($url, $max_requests, $min_unique)) {
        $self->log( "Load Balancing Validated " );
    }
    else {
        $msg = $self->config->{'COMMON.LINK'}.$self->web_msg;
        $self->log( $msg );

        $body = "Load Balancing Validation Failed\n";
        $body .= "\nRefer logs under".$self->config->{'COMMON.LOG_DIR'}." for details";
        $self->mail( $subject, $body );
        $self->log( $self->mail_msg );

        $fail_flag = 1;
        $self->clear_web_msg;
    }
    return 0 if( $fail_flag );
    return 1;
}

=head2 validate_processes_mountpoints

Checks various processes and filesystems on remote servers.The method establishes connection to the remote server.this pre-cooked connection is used by validate_process
and validate_mountpoint to do the real work.The connection is establised using Net::SSH::Perl. Please note to generate and store the Private and Public key pairs for password less SSH login.Refer HOWTO section down below to generate Public/Private key pairs.

=cut

sub validate_processes_mountpoints {
    my $self   = shift;
    my $user = $self->config->{'COMMON.REMOTE_USER'} || $ENV{USER};
    my (@faulty_processes, @faulty_mountpoints, $msg, $subject, $body, $ret);

    foreach my $key ( keys %{$self->config} ) {
        if( $key =~/PROCESSES/ ) {
            my ($host) = ($key =~ /(.*)\..*/);
            $self->log("Connecting to $host...");
            $self->log("Connection Successful!")
                    if($self->connect($host, $user));

            $self->log("Validating Processes...");
            foreach my $proc_tmpl (@{$self->config->{$key}}) {
                if($self->validate_process($proc_tmpl)) {
                    $self->log("$host: $proc_tmpl : OK");
                }
                else {
                    $self->log("$host: $proc_tmpl : NOT OK\n".$self->unix_msg);
                    push @faulty_processes,$proc_tmpl;
                    $self->clear_unix_msg;
                }
            }

           $key = $host.'.FILE_SYS';
           $self->log("Validating FileSystems...");
           foreach my $mountpoint (@{$self->config->{$key}}) {
               if($self->validate_mountpoint($mountpoint)) {
                   $self->log("$host: $mountpoint : OK");
               }
               else {
                   $self->log("$host: $mountpoint : NOT OK ".$self->unix_msg);
                   push @faulty_mountpoints,$mountpoint;
                   $self->clear_unix_msg;
               }
           }
        }
    }

    if( @faulty_processes || @faulty_mountpoints ) {
        $subject = "App Valildation -> Failed";
        $body    = "Unix Validation Failed\n";
        $body    .= "\nRefer logs under".$self->config->{'COMMON.LOG_DIR'}." for details";

        $self->mail( $subject, $body );
        $self->log( $self->mail_msg );
        #$self->faulty_processes( \@faulty_processes );
        return 0;
    }
    return 1;
}

sub _error_handler {
    my $self = shift;
    my $url  = shift;
    my ($msg, $actions);

    $actions = {
        PASSWORD_EXPIRED      =>  sub {
            $msg = $self->web_msg." : About to Change at Web Level :";
            $self->clear_web_msg;
            if($self->change_web_pwd($url)) {
                $self->log("$msg : OK");
            }
            else {
                $self->log($msg.$self->web_msg);
                confess $msg.$self->web_msg;
            }
            $msg = "About to Change at Unix Level :";
            if($self->change_unix_pwd) {
                $self->log("$msg : OK");
            }
            else {
                $self->log($msg.$self->unix_msg);
                confess $msg.$self->unix_msg;
            }
        },
        AUTHENTICATION_FAILURE => sub {
            $self->log(
                $self->web_msg."Incorrect Credentials... Exiting!"
            );
            confess $self->web_msg."Incorrect Credentials... Exiting!";
        },
        MISSDIRECTED           => sub {
            $msg = $url." : Inaccessible\nError : ".$self->web_msg;
            $self->log( $msg );
            $self->clear_web_msg;
        },
        SUCCESS                => sub { $self->log("$url : OK"); },
    };

    return $actions;

}


sub _trim_spaces {

    my $self = shift;
    my $line = shift;

    $line    =~ s/^\s+//;
    $line    =~ s/\s+$//;

    return $line;

}

=head1 HOWTO

=head2 Generate Public/Private key pairs for SSH

ssh-keygen is used to generate that Public/Private key pair:

user@localhost>ssh-keygen -t rsa

Generating public/private rsa key pair.

Enter file in which to save the key (/home/user/.ssh/id_rsa):

Enter passphrase (empty for no passphrase):

Enter same passphrase again:

Your identification has been saved in /home/user/.ssh/id_rsa.

Your public key has been saved in /home/user/.ssh/id_rsa.pub.

The key fingerprint is:
f6:61:a8:27:35:cf:4c:6d:13:22:70:cf:4c:c8:a0:23 user@localhost

The command ssh-keygen -t rsa initiated the creation of the key pair.Adding a passphrase is not required so just press enter.The private key gets saved in .ssh/id_rsa. This file is read-only and only for you. No one else must see the content of that file, as it is used to decrypt all correspondence encrypted with the public key. The public key gets stored in .ssh/id_rsa.pub.The content of the id_rsa.pub needs to be copied in the file .ssh/authorized_keys of the system you wish to SSH to without being prompted for a password. Here are the steps:

Create .ssh dir on remote host(The dir may already exist,No issues):

user@localhost>ssh user@remotehost mkdir -p .ssh
user@remotehost's password: 

Append user's new public key to user@remotehost : .ssh/authorized_keys and enter user's password:

user@localhost>cat .ssh/id_rsa.pub | ssh user@remotehost 'cat >> .ssh/authorized_keys'
user@remotehost's password:

Test login without password:

user@localhost>ssh user@remotehost
user@remotehost>hostname

remotehost

=head2 Use configuration file

App::Validation::Automation is driven by a tunable configuration file.The configuration file is in Windows .ini format.The wrapper script using App::Validation::Automation needs to either read the configuration file or build the configuration itself.The configuration file is broadly divided into two parts COMMON and Remote host specific.The COMMON part contains generic info used by App::Validation::Automation not specific to any host.

Example:

[COMMON]

#User to login into Web links

USER = web_user           

#Common User to login into remote host

REMOTE_USER = user        

#Post link MAX_REQ no of times, used while testing Load
#Balancing and DNS round robin functionality

MAX_REQ = 10              
                         
#Minimum distinct redirected uris to ascertain Load Balancing
#and DNS round robin is working fine

MIN_UNQ = 2

#Log file extension

LOG_EXTN = log            

#Print SSH debugging info to STDOUT

DEBUG_SSH  = 1        

#Try SSH2 protocol first and then SSH1

SSH_PROTO  = '2,1'

#Private keys for each server(AA,KA...) used for SSH

ID_RSA = /home/user/.ssh/id_rsa_AA,/home/user/.ssh/id_rsa_KA

MAIL_TO = 'xyz@yahoo.com,123@gmail.com'

PAGE_TO = '8168168164@vodafone.in'

FROM = xy@localhost.com

SMTP = localhost.com

#Text file containing Encrypted password for USER

ENC_PASS_FILE = pass.txt 

DEFAULT_HOME = /home/App/Validation

LOG_DIR = /home/App/Validation/log

#Log file retention period, delete log file older than 5 days

RET_PERIOD = 5     

#Main Weblink used for Load Balancing and DNS round robin test

LINK = http://cpan.org 

#Remote command fired to get process count.%s is replaced process name

PROCESS_TMPL = ps -eaf | grep -i %s | grep -v grep | wc -l 

#Remote command fired to check filesystem.%s is replaced by filesystem name

FILESYS_TMPL = cd %s      

#FQDN of remote server

[AA.xyz.com]

#Processes to verify on remote hosts along with their minimum quantity

PROCESSES = BBL:1, EPsrv:1, WEBLEPsrv:1 

#Filesystems to verify on remote hosts

FILE_SYS  =  /test, /export/home     

#FQDN of remote server

[KA.xyz.com]              

#Processes to verify on remote hosts along with their minimum quantity

PROCESSES = BBL:1, EPsrv:1, WEBLEPsrv:1 

#Filesystems to verify on remote hosts

FILE_SYS  =  /test, /export/home        

#Links specific to KA server these links are checked for accessibility

LINKS     = http://KA.xyz.com:7000,http://KA.xyz.com:7100 



=head1 AUTHOR

Varun Juyal, C<< <varunjuyal123@yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-validation-automation at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Validation-Automation>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Validation::Automation

Also check out the script under script/ for a full blown example on how to use this 
suite.


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Validation-Automation>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Validation-Automation>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Validation-Automation>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Validation-Automation/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Varun Juyal.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
