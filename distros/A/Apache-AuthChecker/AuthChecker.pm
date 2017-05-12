# This package is distributed under GNU public license.
# See file COPYING for details.

package Apache::AuthChecker;

$VERSION = 1.01;


use DynaLoader();
use IPC::Shareable;
use IPC::SysV qw(IPC_RMID);



# mod_perl2 development team has completely lost the idea of backwards
# compatibility of different versions of mod_perl2. Not to mention
# mod_perl1.
# This is why I use some ugly eval's.

eval {
    require Apache;
    require mod_perl;
};
if ($@) {
    eval {
        require Apache2;
        require mod_perl;
    };
    if ($@) {
    	eval {
            require mod_perl2;
        };
        if ($@) {
            die "Can't find mod_perl installed: $@\n";
        }
    }
}
my $MP2 = ($mod_perl::VERSION >= 1.99) ? 1 : 0;
if ($mod_perl::VERSION >= 2.000002) {
    $MP2 = 2;
}

if ($MP2 == 1) { 
    require Symbol;
    require Apache::RequestRec;
    require Apache::Connection;
    require Apache::Log;
    require Apache::SubRequest;

    require Apache::Access;
    require Apache::RequestUtil;
    require Apache::Const;
    require Apache::Access;
    require Apache::CmdParms ;
    require Apache::Module ;

    @APACHE_MODULE_COMMANDS = (
            {
            name         => 'PerlAuthCheckerMaxUsers',
            func         => __PACKAGE__ . '::PerlAuthCheckerMaxUsers',
            req_override => Apache::OR_ALL,
            args_how     => Apache::ITERATE,
            errmsg       => 'PerlAuthCheckerMaxUsers number',
            },
            {
            name         => 'PerlSecondsToExpire',
            func         => __PACKAGE__ . '::PerlSecondsToExpire',
            req_override => Apache::OR_ALL,
            args_how     => Apache::ITERATE,
            errmsg       => 'PerlSecondsToExpire secs',
            },
    
    );
    eval {
        Apache::Module::add(__PACKAGE__, \@APACHE_MODULE_COMMANDS);
    };
    if ($@) {
            die "Can't add module directives1: $@\n";
    }

} elsif ($MP2 == 2) { 
    require Symbol;
    require Apache2::RequestRec;
    require Apache2::Connection;
    require Apache2::Log;
    require Apache2::SubRequest;

    require Apache2::Access;
    require Apache2::RequestUtil;
    require Apache2::Const;
    require Apache2::Access;
    require Apache2::CmdParms ;
    require Apache2::Module ;

    @APACHE_MODULE_COMMANDS = (
            {
            name         => 'PerlAuthCheckerMaxUsers',
            func         => __PACKAGE__ . '::PerlAuthCheckerMaxUsers',
            req_override => Apache2::Const::OR_ALL,
            args_how     => Apache2::Const::ITERATE,
            errmsg       => 'PerlAuthCheckerMaxUsers number',
            },
            {
            name         => 'PerlSecondsToExpire',
            func         => __PACKAGE__ . '::PerlSecondsToExpire',
            req_override => Apache2::Const::OR_ALL,
            args_how     => Apache2::Const::ITERATE,
            errmsg       => 'PerlSecondsToExpire secs',
            },
    
    );
    eval {
        Apache2::Module::add(__PACKAGE__, \@APACHE_MODULE_COMMANDS);
    };
    if ($@) {
            die "Can't add module directives2: $@\n";
    }


} else {
    require Apache::ModuleConfig;
    require Apache::Constants;
}


use vars qw(%DB);

# Yes, I know about existence of Apache::Const(ants) with friends.
# But I can't spend all my time chasing various perl/mod_perl 
# configurations/versions in free project.
# That's why I put in code some not-at-all-correctnesses like this one,
# to be compatible even with Perl 5.005:
my $OK = 0;
my $AUTH_REQUIRED = 401;
my $REDIRECT = 302;



if ($ENV{MOD_PERL}) {
    no strict;
    @ISA = qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION);
}


sub get_config {

    eval {
        Apache::Module->get_config(@_);
    };
    if ($@) {
        eval {
            Apache::Module->get_config(__PACKAGE__, @_);
        }
    };
}

my $debug = 1;
my $ipc_key = 0x27071975;
my $bytes_per_record = 45;

sub handler {
    my $r = shift;
    my $res;
    my $sent_pw;
    my $rc;

    return undef unless defined($r);

    my ($res, $sent_pw) = $r->get_basic_auth_pw;
    return $res if $res != $OK;
    my $user = ($MP2) ? $r->user : $r->connection->user;
    my $remote_ip = $r->connection->remote_ip;
    my $ignore_this_request = 0;
    my $cur_time = time();

    my $passwd_file = $r->dir_config('AuthUserFile');
    my $max_failed_attempts = $r->dir_config('MaxFailedAttempts') || 10;

    my $time_to_expire;
    my $mem_size;
    my $default_time_to_expire = 3600;
    my $default_mem_size = 65535;


    # Fetch custom directives values
    if ($MP2) {
        $s = $r->server;
        $dir_cfg = get_config($s, $r->per_dir_config);
        $time_to_expire = $dir_cfg->{'AuthCheckerSecondsToExpire'} || 
            $default_time_to_expire;
        $mem_size = $dir_cfg->{'AuthCheckerMemSize'} || 
            $default_mem_size;
    } else {
        my $cfg = Apache::ModuleConfig->get($r);
        $time_to_expire = $cfg->{AuthCheckerSecondsToExpire} ||
            $default_time_to_expire;
        $mem_size = $cfg->{AuthCheckerMemSize} || 
            $default_mem_size
    }
    

    my ($failed_attempts, $last_access);


    unless (defined %DB) {
        #Init stuff here
        $r->log_error("AuthChecker started pid: $$ tie memory $mem_size...")
            if ($debug);
        tie %DB, 'IPC::Shareable', $ipc_key, 
            { create => 1, mode => 0644, size => $mem_size};
        unless (defined %DB) {
            $r->log_error("AuthChecker is unable to tie shared memory.");
            exit(1);
        }
        $r->log_error("AuthChecker started successfully.")
            if ($debug);
    };
        
    tied(%DB)->shlock;


    #Expire old hash records
    if (!defined($DB{0})) {
        $DB{0} = $cur_time;
    } elsif (($cur_time-$time_to_expire) > $DB{0}) {
        
    
        foreach $rc (keys %DB) {
            my ($x, $last_access) = split(':', $DB{$rc});
            if (($cur_time-$time_to_expire) > $last_access) {
                delete $DB{$rc};
                $r->log_error("IP: $remote_ip expired.");
            }
        }
        $DB{0} = $cur_time;
    }
    
    if (defined($DB{$remote_ip})) {
        ($failed_attempts, $last_access) = 
            split(':', $DB{$remote_ip});
            
        $r->log_error("Stats IP: $remote_ip Attempts: $failed_attempts")
            if ($debug);
        
        if ($failed_attempts >= $max_failed_attempts) {
            $r->log_error("IP: $remote_ip is blocked. ".
                          "Auth attempts: $failed_attempts");
            $ignore_this_request = 1;
        }
    } else {
        $r->log_error("IP: $remote_ip not found in DB.")
            if ($debug);
    }
    

    if (!$ignore_this_request) {

        $rc = open(P, $passwd_file);
        if (!$rc) {
            $r->note_basic_auth_failure;
            $r->log_error("Can't open file", $passwd_file);
            tied(%DB)->shunlock;
            return $AUTH_REQUIRED;
        };

        my $i;
        while ($i = <P>) {
            chomp $i;
            next if ($i =~ /^#/);
            my ($user_name, $saved_pw) = split(':',$i);
            next if ($user ne $user_name);
        
            my $gpw = crypt($sent_pw,$saved_pw);
            $r->log_error("User: $user Saved pw: $saved_pw Get pw: $gpw")
                if ($debug);
        
            if ($saved_pw ne crypt($sent_pw,$saved_pw)) {
                last;
            } else {
                tied(%DB)->shunlock;
                return $OK;
            }
        }
        close(P);
    }
    
    if ($failed_attempts) {
        $failed_attempts++;
    } else {
        $failed_attempts=1;
    }    
    $last_access = time();
    
    
    my $val = "$failed_attempts:$last_access";
    $DB{$remote_ip} = $val;
    tied(%DB)->shunlock;

    $r->log_error("Authorization for $user IP: $remote_ip failed. Attempts: $failed_attempts");  

    if ($ignore_this_request) {    
        my $uri = $r->dir_config('RedirectURI') || "/";
        $r->internal_redirect_handler($uri);
        return $REDIRECT;
    } else {
        my $i = $REDIRECT;
        $r->log_error("AUTH1: $i");
        $i = $AUTH_REQUIRED;
        $r->log_error("AUTH2: $i");
        $i = $OK;
        $r->log_error("AUTH3: $i");

        $r->note_basic_auth_failure;
        return $AUTH_REQUIRED;
    }
}

sub PerlAuthCheckerMaxUsers ($$$) {
    my ($cfg, $parms, $arg) = @_;
    $cfg->{AuthCheckerMemSize} = $arg * $bytes_per_record;

    clean_up();    
}

sub PerlSecondsToExpire ($$$) {
    my ($cfg, $parms, $arg) = @_;
    $cfg->{AuthCheckerSecondsToExpire} = $arg;
    
    clean_up();
}

sub clean_up {
    #Remove old locks and memory - if our ancestor died ungracefully.
    my $sid = semget ($ipc_key,0,0);
    my $shmid = shmget ($ipc_key,0,0);
    semctl($sid,0,IPC_RMID,0) if (defined $sid);
    shmctl($shmid,IPC_RMID,0) if (defined $shmid);
}


1;
__END__


=head1 NAME

Apache::AuthChecker - mod_perl based authentication module used to prevent brute force attacks via HTTP authorization.

=head1 SYNOPSIS

See README section.

=head1 README

Apache::AuthChecker - mod_perl based authentication module used to prevent
brute force attacks via HTTP authorization. It remembers IP addresses of any
user trying to authenticate for certain period of time. If user
runs out limit of failed attempts to authenticate - all his authentication
requests will be redirected to some URI (like this: /you_are_blocked.html).

Requirements: 

 1. Apache 1.3.x (2.x) with mod_perl 1.2x (2.x) enabled 
 2. IPC::Shareable perl module version 0.60 by BSUGARS. Probably it
    should work with other versions, but I did not test.

Installation:

 -from the directory where this file is located, type:
     perl Makefile.PL
     make && make test && make install
                                  
!!! For RedHat users !!! 
1. You need httpd-devel rpm package installed.
2. If 'make' fails, try to type: 
export LANG=en_US
and restart installation process FROM BEGINNING.
There is a known bug in RedHat distributions.


Apache configuration process:

 1. Add directives to httpd.conf below directives LoadModule and AddModule:
    <IfDefine MODPERL2>
	PerlModule Apache2
        PerlLoadModule Apache::AuthChecker
    </IfDefine>
    <IfDefine !MODPERL2>
        PerlModule Apache::AuthChecker
    </IfDefine>
    PerlAuthCheckerMaxUsers 1450           
    PerlSecondsToExpire     3600           

 Note: parameter PerlAuthCheckerMaxUsers affects amount of shared memory 
  allocated. Rule to estimate: every IP record eats 45 bytes. It means if you 
  set 1000 users - 45Kbytes of shared memory will be allocated. Default
  setting is 64KByte which gives us about 1450 records.
  Exact value depends on PerlSecondsToExpire parameter.
  !!! It does not store ALL logins info, ONLY FAILED ONES BY IP.
      I see no need to make it big.
  Max limit depends on your OS settings.
  
 PerlSecondsToExpire - how long will we store data about authentication 
  failures.
   

 2. Use .htaccess or <Directory> or <Location> mechanisms with the 
  following directives (default values):

    AuthName "My secret area"
    PerlAuthenHandler Apache::AuthChecker
    PerlSetVar      AuthUserFile /path/to/my/.htpasswd
    PerlSetVar      MaxFailedAttempts 10
    PerlSetVar      RedirectURI /
    require valid-user
    
 Example. 
    Your old .htaccess file looks like:
    
    AuthName "My secret area"
    AuthType Basic
    AuthUserFile /path/to/my/.htpasswd
    require valid-user
        
    The new one:
    
    AuthName "My secret area"
    #AuthType Basic
    PerlAuthenHandler Apache::AuthChecker
    PerlSetVar    AuthUserFile /path/to/my/.htpasswd
    require valid-user
                

 Parameters:

 AuthUserFile       - path to your passwords htpasswd-made file (REQUIRED).
 MaxFailedAttempts  - Maximum attempts we give user to mistype password 
                      (OPTIONAL, default - 8).
 RedirectURI        - URI (not URL!) to redirect attacker then he runs out 
                      attempts limit ((OPTIONAL, default - /). 
                      For example: /you_are_blocked.html


=head1 DESCRIPTION

Apache::AuthChecker - mod_perl based authentication module used to prevent
brute force attacks via HTTP authorization. It remembers IP addresses of any
user trying to authenticate for certain period of time. If user from this IP
runs out limit of failed attempts to authenticate - all his authentication
requests will be redirected to some URI (like this: /you_are_blocked.html).

=head1 PREREQUISITES

 1. Apache 1.3.x with mod_perl 1.2x enabled 
 2. IPC::Shareable perl module version 0.60 by BSUGARS. Probably it
    should work with other versions, but I did not test.

=head1 AUTHOR

Andre Yelistratov 
 E-mail: andre@sundale.net
 ICQ: 9138065

=cut
