package Apache::AuthDigestDBI;

use Apache ();
use Apache::Constants qw( OK AUTH_REQUIRED FORBIDDEN DECLINED SERVER_ERROR );
use DBI ();
use IPC::SysV qw( IPC_CREAT IPC_RMID S_IRUSR S_IWUSR );
use Apache::AuthDigest::API;
use Digest::MD5;
use strict;

# $Id: AuthDigestDBI.pm,v 1.1 2002/11/11 13:58:37 geoff Exp $

require_version DBI 1.00;

$Apache::AuthDigestDBI::VERSION = '0.89';

# 1: report about cache miss
# 2: full debug output
$Apache::AuthDigestDBI::DEBUG = 0;


# configuration attributes, defaults will be overwritten with values from .htaccess.

my %Config = (
    'Auth_DBI_data_source'      => '',
    'Auth_DBI_username'         => '',
    'Auth_DBI_password'         => '',
    'Auth_DBI_pwd_table'        => '',
    'Auth_DBI_uid_field'        => '',
    'Auth_DBI_pwd_field'        => '',
    'Auth_DBI_pwd_whereclause'  => '',
    'Auth_DBI_grp_table'        => '',
    'Auth_DBI_grp_field'        => '',
    'Auth_DBI_grp_whereclause'  => '',
    'Auth_DBI_log_field'        => '',
    'Auth_DBI_log_string'       => '',
    'Auth_DBI_authoritative'    => 'on',
    'Auth_DBI_nopasswd'         => 'off',
    'Auth_DBI_encrypted'        => 'on',
    'Auth_DBI_encryption_salt'  => 'password',
    'Auth_DBI_uidcasesensitive' => 'on',
    'Auth_DBI_pwdcasesensitive' => 'on',
    'Auth_DBI_placeholder'      => 'off',
);

# stores the configuration of current URL.
# initialized  during authentication, eventually re-used for authorization.
my $Attr = { };


# global cache: all records are put into one string.
# record separator is a newline. Field separator is $;.
# every record is a list of id, time of last access, password, groups (authorization only).
# the id is a comma separated list of user_id, data_source, pwd_table, uid_field.
# the first record is a timestamp, which indicates the last run of the CleanupHandler followed by the child counter.

my $Cache = time . "$;0\n";

# unique id which serves as key in $Cache.
# the id is generated during authentication and re-used for authorization.
my $ID;


# minimum lifetimes of cache entries in seconds.
# setting the CacheTime to 0 will not use the cache at all.

my $CacheTime = 0;

# supposed to be called in a startup script.
# sets CacheTime to a user defined value.

sub setCacheTime {
    my $class      = shift;
    my $cache_time = shift;
    # sanity check
    $CacheTime = $cache_time if ($cache_time =~ /\d+/);
}


# minimum time interval in seconds between two runs of the PerlCleanupHandler.
# setting CleanupTime to 0 will run the PerlCleanupHandler after every request.
# setting CleanupTime to a negative value will disable the PerlCleanupHandler.

my $CleanupTime = -1;

# supposed to be called in a startup script.
# sets CleanupTime to a user defined value.

sub setCleanupTime {
    my $class        = shift;
    my $cleanup_time = shift;
    # sanity check
    $CleanupTime = $cleanup_time if ($cleanup_time =~ /\-*\d+/);
}


# optionally the string with the global cache can be stored in a shared memory segment.
# the segment will be created from the first child and it will be destroyed if the last child exits.
# the reason for not handling everything in the main server is simply, that there is no way to setup 
# an ExitHandler which runs in the main server and which would remove the shared memory and the semaphore.
# hence we have to keep track about the number of children, so that the last one can do all the cleanup.
# creating the shared memory in the first child also has the advantage, that we don't have to cope
# with changing the ownership.
# if a shm-function fails, the global cache will automatically fall back to one string per process.

my $SHMKEY  =     0; # unique key for shared memory segment and semaphore set
my $SEMID   =     0; # id of semaphore set
my $SHMID   =     0; # id of shared memory segment
my $SHMSIZE = 50000; # default size of shared memory segment

# shortcuts for semaphores
my $obtain_lock  = pack("sss", 0,  0, 0) . pack("sss", 0, 1, 0);
my $release_lock = pack("sss", 0, -1, 0);

# supposed to be called in a startup script.
# sets SHMSIZE to a user defined value and initializes the unique key, used for the shared memory segment and for the semaphore set.
# creates a PerlChildInitHandler which creates the shared memory segment and the semaphore set.
# creates a PerlChildExitHandler which removes the shared memory segment and the semaphore set upon server shutdown.
# keep in mind, that this routine runs only once, when the main server starts up.

sub initIPC {
    my $class   = shift;
    my $shmsize = shift;

    # make sure, this method is called only once
    return if $SHMKEY;

    # ensure minimum size of shared memory segment
    $SHMSIZE = $shmsize if $shmsize >= 500;

    # generate unique key based on path of AuthDBI.pm
    foreach my $file (keys %INC) {
        if ($file eq 'Apache/AuthDBI.pm') {
            $SHMKEY = IPC::SysV::ftok($INC{$file}, 1);
            last;
        }
    }

    # provide a handler which initializes the shared memory segment (first child)
    # or which increments the child counter. 
    if(Apache->can('push_handlers')) {
        Apache->push_handlers("PerlChildInitHandler" => \&childinit);
    }

    # provide a handler which decrements the child count or which destroys the shared memory 
    # segment upon server shutdown, which is defined by the exit of the last child.
    if(Apache->can('push_handlers')) {
        Apache->push_handlers("PerlChildExitHandler" => \&childexit);
    }
}


# authentication handler

sub authen {

    my ($r) = @_;
    my ($key, $val, $dbh);

    my $prefix = "$$ Apache::AuthDigestDBI::authen";

    if ($Apache::AuthDigestDBI::DEBUG > 1) {
        my ($type) = '';
        $type .= 'initial ' if $r->is_initial_req;
        $type .= 'main'     if $r->is_main;
        print STDERR "==========\n$prefix request type = >$type< \n";
    }

    return OK unless $r->is_initial_req; # only the first internal request

    print STDERR "REQUEST:\n", $r->as_string if $Apache::AuthDigestDBI::DEBUG > 1;
	
	my $auth = 'digest';

	# here the dialog pops up and asks you for username and password
	my ($status, $response, $res, $passwd_sent);
	if ($r->header_in("Authorization") =~ /^Basic (.*)/i) {
		$auth = 'Basic';
		my $username;
		($username, $passwd_sent) = split ':', old_decode_base64($1);
		$r->connection->user($username);
	}

	if ($auth eq 'digest') {

		$r = Apache::AuthDigest::API->new($r);
		($status, $response) = $r->get_digest_auth_response;		
		return $status unless $status == OK;
		$passwd_sent = 'digest';
		
	} else {
	
		#($res, $passwd_sent) = $r->get_basic_auth_pw;
		#print STDERR "$prefix get_basic_auth_pw: res = >$res<, password sent = >$passwd_sent<\n" if $Apache::AuthDigestDBI::DEBUG > 1;
		#return $res if $res; # e.g. HTTP_UNAUTHORIZED
		
		return AUTH_REQUIRED unless $passwd_sent;
		
	}

    # get username
    my ($user_sent) = $r->connection->user;
    print STDERR "$prefix user sent = >$user_sent<\n" if $Apache::AuthDigestDBI::DEBUG > 1;

    # do we use shared memory for the global cache ?
    print STDERR "$prefix cache in shared memory, shmid $SHMID, shmsize $SHMSIZE, semid $SEMID \n" if ($SHMID and $Apache::AuthDigestDBI::DEBUG > 1);

    # get configuration
    while(($key, $val) = each %Config) {
        $val = $r->dir_config($key) || $val;
        $key =~ s/^Auth_DBI_//;
        $Attr->{$key} = $val;
        printf STDERR "$prefix Config{ %-16s } = %s\n", $key, $val if $Apache::AuthDigestDBI::DEBUG > 1;
    }

    # parse connect attributes, which may be tilde separated lists
    my @data_sources = split(/~/, $Attr->{data_source});
    my @usernames    = split(/~/, $Attr->{username});
    my @passwords    = split(/~/, $Attr->{password});
    $data_sources[0] = '' unless $data_sources[0]; # use ENV{DBI_DSN} if not defined

    # obtain the id for the cache
    my $data_src = $Attr->{data_source};
    $data_src =~ s/\(.+\)//go; # remove any embedded attributes, because of trouble with regexps
    $ID = join ',', $user_sent, $data_src, $Attr->{pwd_table}, $Attr->{uid_field};

    # if not configured decline
    unless ($Attr->{pwd_table} && $Attr->{uid_field} && $Attr->{pwd_field}) {
        printf STDERR "$prefix not configured, return DECLINED\n" if $Apache::AuthDigestDBI::DEBUG > 1;
        return DECLINED;
    }

    # do we want Windows-like case-insensitivity?
    $user_sent   = lc($user_sent)   if $Attr->{uidcasesensitive} eq "off";
    $passwd_sent = lc($passwd_sent) if $Attr->{pwdcasesensitive} eq "off";

    # check whether the user is cached but consider that the password possibly has changed
    my $passwd = '';
    my $salt   = '';
    if ($CacheTime) { # do we use the cache ?
        if ($SHMID) { # do we keep the cache in shared memory ?
            semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
            shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
            substr($Cache, index($Cache, "\0")) = '';
            semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
        }
        # find id in cache
        my ($last_access, $passwd_cached, $groups_cached);
        if ($Cache =~ /$ID$;(\d+)$;(.+)$;(.*)\n/) {
            $last_access   = $1;
            $passwd_cached = $2;
            $groups_cached = $3;
            printf STDERR "$prefix cache: found >$ID< >$last_access< >$passwd_cached< \n" if $Apache::AuthDigestDBI::DEBUG > 1;
			if ($auth eq 'digest') {
				$salt = $response->{'realm'};
				my $passwd_to_check = Digest::MD5::md5_hex(join ':', $user_sent, $salt, $passwd_cached);
				$passwd = $passwd_cached if $r->compare_digest_response($response, $passwd_to_check);
			} else {
				$salt = $Attr->{encryption_salt} eq 'userid' ? $user_sent : $passwd_cached;
				my $passwd_to_check = $Attr->{encrypted} eq 'on' ? crypt($passwd_sent, $salt) : $passwd_sent; 
				# match cached password with password sent 
				$passwd = $passwd_cached if $passwd_to_check eq $passwd_cached;
			}
        }
    }

    if ($passwd) { # found in cache
        printf STDERR "$prefix passwd found in cache \n" if $Apache::AuthDigestDBI::DEBUG > 1;
    } else { # password not cached or changed
        printf STDERR "$prefix passwd not found in cache \n" if $Apache::AuthDigestDBI::DEBUG;

        # connect to database, use all data_sources until the connect succeeds
        my $j;
        for ($j = 0; $j <= $#data_sources; $j++) {
            last if ($dbh = DBI->connect($data_sources[$j], $usernames[$j], $passwords[$j]));
        }
        unless ($dbh) {
            $r->log_reason("$prefix db connect error with data_source >$Attr->{data_source}<", $r->uri);
            return SERVER_ERROR;
        }

        # generate statement
        my $user_sent_quoted = $dbh->quote($user_sent);
        my $select    = "SELECT $Attr->{pwd_field}";
        my $from      = "FROM $Attr->{pwd_table}";
        my $where     = ($Attr->{uidcasesensitive} eq "off") ? "WHERE lower($Attr->{uid_field}) =" : "WHERE $Attr->{uid_field} =";
        my $compare   = ($Attr->{placeholder}      eq "on")  ? "?" : "$user_sent_quoted";
        my $statement = "$select $from $where $compare";
        $statement   .= " AND $Attr->{pwd_whereclause}" if $Attr->{pwd_whereclause};
        print STDERR "$prefix statement: $statement\n" if $Apache::AuthDigestDBI::DEBUG > 1;

        # prepare statement
        my $sth;
        unless ($sth = $dbh->prepare($statement)) {
            $r->log_reason("$prefix can not prepare statement: $DBI::errstr", $r->uri);
            $dbh->disconnect;
            return SERVER_ERROR;
        }

        # execute statement
        my $rv;
        unless ($rv = ($Attr->{placeholder} eq "on") ? $sth->execute($user_sent) : $sth->execute) {
            $r->log_reason("$prefix can not execute statement: $DBI::errstr", $r->uri);
            $dbh->disconnect;
            return SERVER_ERROR;
        }

        # fetch result
        while ($_ = $sth->fetchrow_array) {
            # strip trailing blanks for fixed-length data-type
            $_ =~ s/ +$// if $_;
            # consider the case with many users sharing the same userid
	    $passwd .= "$_$;";
        }

        chop  $passwd if $passwd;
        undef $passwd if 0 == $sth->rows; # so we can distinguish later on between no password and empty password

        if ($sth->err) {
            $dbh->disconnect;
            return SERVER_ERROR;
        }
        $sth->finish;

        # re-use dbh for logging option below
        $dbh->disconnect unless ($Attr->{log_field} && $Attr->{log_string});
    }

    $r->subprocess_env(REMOTE_PASSWORDS => $passwd);
    print STDERR "$prefix passwd = >$passwd<\n" if $Apache::AuthDigestDBI::DEBUG > 1;

    # check if password is needed
    if (!defined($passwd)) { # not found in database
        # if authoritative insist that user is in database
        if ($Attr->{authoritative} eq 'on') {
            $r->log_reason("$prefix password for user $user_sent not found", $r->uri);
            $r->note_basic_auth_failure;
            return AUTH_REQUIRED;
        } else {
            # else pass control to the next authentication module
            return DECLINED;
        }
    }

    # allow any password if nopasswd = on and the retrieved password is empty
    if ($Attr->{nopasswd} eq 'on' && !$passwd) {
        return OK;
    }

    # if nopasswd is off, reject user
    unless ($passwd_sent && $passwd) {
        $r->log_reason("$prefix user $user_sent: empty password(s) rejected", $r->uri);
        $r->note_basic_auth_failure;
        return AUTH_REQUIRED;
    }

    # compare passwords
    my $found = 0;
    my $password;
    foreach $password (split(/$;/, $passwd)) {
        # compare the two passwords possibly crypting the password if needed
        my $did_match = 0;
		if ($auth eq 'digest') {
			$salt = $response->{'realm'};
			# password to check is in a reverse role from below
			# it's the correct password
			my $passwd_to_check = Digest::MD5::md5_hex(join ':', $user_sent, $salt, $password);
			$did_match = 1 if $r->compare_digest_response($response, $passwd_to_check);
		} else {
			$salt = $Attr->{encryption_salt} eq 'userid' ? $user_sent : $password;
			my $passwd_to_check = $Attr->{encrypted} eq 'on' ? crypt($passwd_sent, $password) : $passwd_sent;
            print STDERR "$prefix user $user_sent: > '$passwd_to_check' eq '$password' < \n" if $Apache::AuthDigestDBI::DEBUG > 1;
			$did_match = 1 if $passwd_to_check eq $password;
		}
		
        if ($did_match) {
            $found = 1;
            $r->subprocess_env(REMOTE_PASSWORD => $password);
            print STDERR "$prefix user $user_sent: password match for >$password< \n" if $Apache::AuthDigestDBI::DEBUG > 1;
            # update timestamp and cache userid/password if CacheTime is configured
            if ($CacheTime) { # do we use the cache ?
                if ($SHMID) { # do we keep the cache in shared memory ?
                    semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
                    shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
                    substr($Cache, index($Cache, "\0")) = '';
                }
                # update timestamp and password or append new record
                my $now = time;
                if (!($Cache =~ s/$ID$;\d+$;.*$;(.*)\n/$ID$;$now$;$password$;$1\n/)) {
		    $Cache .= "$ID$;$now$;$password$;\n";
                } else {
                }
                if ($SHMID) { # write cache to shared memory
                    shmwrite($SHMID, $Cache, 0, $SHMSIZE)  or printf STDERR "$prefix shmwrite failed \n";
                    semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
                }
            }
            last;
        }
    }
    unless ($found) {
        $r->log_reason("$prefix user $user_sent: password mismatch", $r->uri);
		if ($auth eq 'digest') {
			$r->note_digest_auth_failure;
		} else {
			$r->note_basic_auth_failure;		
		}
        return AUTH_REQUIRED;
    }

    # logging option
    if ($Attr->{log_field} && $Attr->{log_string}) {
        if (!$dbh) { # connect to database if not already done
            my ($j, $connect);
            for ($j = 0; $j <= $#data_sources; $j++) {
                if ($dbh = DBI->connect($data_sources[$j], $usernames[$j], $passwords[$j])) {
                    $connect = 1;
                    last;
                }
            }
            unless ($connect) {
                $r->log_reason("$prefix db connect error with $Attr->{data_source}", $r->uri);
                return SERVER_ERROR;
            }
        }
        my $user_sent_quoted = $dbh->quote($user_sent);
        my $statement = "UPDATE $Attr->{pwd_table} SET $Attr->{log_field} = $Attr->{log_string} WHERE $Attr->{uid_field}=$user_sent_quoted";
        print STDERR "$prefix statement: $statement\n" if $Apache::AuthDigestDBI::DEBUG > 1;
        unless ($dbh->do($statement)) {
            $r->log_reason("$prefix can not do statement: $DBI::errstr", $r->uri);
            $dbh->disconnect;
            return SERVER_ERROR;
        }
        $dbh->disconnect;
    }

    # Unless the cache or the CleanupHandler is disabled, the CleanupHandler is initiated 
    # if the last run was more than $CleanupTime seconds before. 
    # Note, that it runs after the request, hence it cleans also the authorization entries 
    if ($CacheTime and $CleanupTime >= 0) {
        my $diff = time - substr($Cache, 0, index($Cache, "$;"));
        print STDERR "$prefix secs since last CleanupHandler: $diff, CleanupTime: $CleanupTime \n" if $Apache::AuthDigestDBI::DEBUG > 1;
        if ($diff > $CleanupTime and Apache->can('push_handlers')) {
            print STDERR "$prefix push PerlCleanupHandler \n" if $Apache::AuthDigestDBI::DEBUG > 1;
            Apache->push_handlers("PerlCleanupHandler", \&cleanup);
        }
    }

    printf STDERR "$prefix return OK\n" if $Apache::AuthDigestDBI::DEBUG > 1;
    return OK;
}


# authorization handler, it is called immediately after the authentication

sub authz {

    my ($r) = @_;
    my ($key, $val, $dbh);

    my ($prefix) = "$$ Apache::AuthDigestDBI::authz ";

    if ($Apache::AuthDigestDBI::DEBUG > 1) {
        my ($type) = '';
        $type .= 'initial ' if $r->is_initial_req;
        $type .= 'main'     if $r->is_main;
        print STDERR "==========\n$prefix request type = >$type< \n";
    }

    return OK unless $r->is_initial_req; # only the first internal request

    my ($user_result)  = DECLINED;
    my ($group_result) = DECLINED;

    # get username
    my ($user_sent) = $r->connection->user;
    print STDERR "$prefix user sent = >$user_sent<\n" if $Apache::AuthDigestDBI::DEBUG > 1 ;

    # here we could read the configuration, but we re-use the configuration from the authentication

    # parse connect attributes, which may be tilde separated lists
    my @data_sources = split(/~/, $Attr->{data_source});
    my @usernames    = split(/~/, $Attr->{username});
    my @passwords    = split(/~/, $Attr->{password});
    $data_sources[0] = '' unless $data_sources[0]; # use ENV{DBI_DSN} if not defined

    # if not configured decline
    unless ($Attr->{pwd_table} && $Attr->{uid_field} && $Attr->{grp_field}) {
        printf STDERR "$prefix not configured, return DECLINED\n" if $Apache::AuthDigestDBI::DEBUG > 1;
        return DECLINED;
    }

    # do we want Windows-like case-insensitivity?
    $user_sent = lc($user_sent) if $Attr->{uidcasesensitive} eq "off";

    # select code to return if authorization is denied:
    my $authz_denied= $Attr->{expeditive} eq 'on' ? FORBIDDEN : AUTH_REQUIRED;

    # check if requirements exists
    my ($ary_ref) = $r->requires;
    unless ($ary_ref) {
        if ($Attr->{authoritative} eq 'on') {
            $r->log_reason("user $user_sent denied, no access rules specified (DBI-Authoritative)", $r->uri);
            $r->note_basic_auth_failure if $authz_denied == AUTH_REQUIRED;
            return $authz_denied;
        }
        printf STDERR "$prefix no requirements and not authoritative, return DECLINED\n" if $Apache::AuthDigestDBI::DEBUG > 1;
        return DECLINED;
    }

    # iterate over all requirement directives and store them according to their type (valid-user, user, group)
    my($hash_ref, $valid_user, $user_requirements, $group_requirements);
    foreach $hash_ref (@$ary_ref) {
        while (($key,$val) = each %$hash_ref) {
            last if $key eq 'requirement';
        }
        $val =~ s/^\s*require\s+//;
        # handle different requirement-types
        if ($val =~ /valid-user/) {
            $valid_user = 1;
        } elsif ($val =~ s/^user\s+//go) {
            $user_requirements .= " $val";
        } elsif ($val =~ s/^group\s+//go) {
            $group_requirements .= " $val";
        }
    }
    $user_requirements  =~ s/^ //go;
    $group_requirements =~ s/^ //go;
    print STDERR "$prefix requirements: valid-user=>$valid_user< user=>$user_requirements< group=>$group_requirements< \n"  if $Apache::AuthDigestDBI::DEBUG > 1;

    # check for valid-user
    if ($valid_user) {
        $user_result = OK;
        print STDERR "$prefix user_result = OK: valid-user\n" if $Apache::AuthDigestDBI::DEBUG > 1;
    }

    # check for users
    if ($user_result != OK && $user_requirements) {
        $user_result = AUTH_REQUIRED;
        my $user_required;
        foreach $user_required (split /\s+/, $user_requirements) {
            if ($user_required eq $user_sent) {
                print STDERR "$prefix user_result = OK for $user_required \n" if $Apache::AuthDigestDBI::DEBUG > 1;
                $user_result = OK;
                last;
           }
        }
    }

    # check for groups
    if ($user_result != OK && $group_requirements) {
        $group_result = AUTH_REQUIRED;
        my ($group, $group_required);

        # check whether the user is cached but consider that the group possibly has changed
        my $groups = '';
        if ($CacheTime) { # do we use the cache ?
            # we need to get the cached groups for the current id, which has been read already 
            # during authentication, so we do not read the Cache from shared memory again
            my ($last_access, $passwd_cached, $groups_cached);
            if ($Cache =~ /$ID$;(\d+)$;(.*)$;(.+)\n/) {
                $last_access   = $1;
                $passwd_cached = $2;
                $groups_cached = $3;
                printf STDERR "$prefix cache: found >$ID< >$last_access< >$groups_cached< \n" if $Apache::AuthDigestDBI::DEBUG > 1;
                REQUIRE_1: foreach $group_required (split /\s+/, $group_requirements) {
                    foreach $group (split(/,/, $groups_cached)) {
                        if ($group_required eq $group) {
                            $groups = $groups_cached;
                            last REQUIRE_1;
		        }
                    }
                }
            }
        }

        if ($groups) { # found in cache
            printf STDERR "$prefix groups found in cache \n" if $Apache::AuthDigestDBI::DEBUG > 1;
        } else { # groups not cached or changed
            printf STDERR "$prefix groups not found in cache \n" if $Apache::AuthDigestDBI::DEBUG;

            # connect to database, use all data_sources until the connect succeeds
            my ($j, $connect);
            for ($j = 0; $j <= $#data_sources; $j++) {
                if ($dbh = DBI->connect($data_sources[$j], $usernames[$j], $passwords[$j])) {
                    $connect = 1;
                    last;
                }
            }
            unless ($connect) {
                $r->log_reason("$prefix db connect error with $Attr->{data_source}", $r->uri);
                return SERVER_ERROR;
            }

            # generate statement
            my $user_sent_quoted = $dbh->quote($user_sent);
            my $select    = "SELECT $Attr->{grp_field}";
            my $from      = ($Attr->{grp_table}) ? "FROM $Attr->{grp_table}" : "FROM $Attr->{pwd_table}";
            my $where     = ($Attr->{uidcasesensitive} eq "off") ? "WHERE lower($Attr->{uid_field}) =" : "WHERE $Attr->{uid_field} =";
            my $compare   = ($Attr->{placeholder}      eq "on")  ? "?" : "$user_sent_quoted";
            my $statement = "$select $from $where $compare";
            $statement   .= " AND $Attr->{grp_whereclause}" if ($Attr->{grp_whereclause});
            print STDERR "$prefix statement: $statement\n" if $Apache::AuthDigestDBI::DEBUG > 1;

            # prepare statement
            my $sth;
            unless ($sth = $dbh->prepare($statement)) {
                $r->log_reason("can not prepare statement: $DBI::errstr", $r->uri);
                $dbh->disconnect;
                return SERVER_ERROR;
            }

            # execute statement
            my $rv;
            unless ($rv = ($Attr->{placeholder} eq "on") ? $sth->execute($user_sent) : $sth->execute) {
                $r->log_reason("can not execute statement: $DBI::errstr", $r->uri);
                $dbh->disconnect;
                return SERVER_ERROR;
            }

            # fetch result and build a group-list
            my $group;
            while ( $group = $sth->fetchrow_array ) {
                # strip trailing blanks for fixed-length data-type
                $group =~ s/ +$//;
                $groups .= "$group,";
            }
            chop $groups if $groups;

            $sth->finish;
            $dbh->disconnect;
        }

        $r->subprocess_env(REMOTE_GROUPS => $groups);
        print STDERR "$prefix groups = >$groups<\n" if $Apache::AuthDigestDBI::DEBUG > 1;

        # skip through the required groups until the first matches
        REQUIRE_2: foreach $group_required (split /\s+/, $group_requirements) {
            foreach $group (split(/,/, $groups)) {
                # check group
                if ($group_required eq $group) {
                    $group_result = OK;
                    $r->subprocess_env(REMOTE_GROUP => $group);
                    print STDERR "$prefix user $user_sent: group_result = OK for >$group< \n" if $Apache::AuthDigestDBI::DEBUG > 1;
                    # update timestamp and cache userid/groups if CacheTime is configured
                    if ($CacheTime) { # do we use the cache ?
                        if ($SHMID) { # do we keep the cache in shared memory ?
                            semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
                            shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
                            substr($Cache, index($Cache, "\0")) = '';
                        }
                        # update timestamp and groups
                        my $now = time;
                        # entry must exists from authentication
	        	$Cache =~ s/$ID$;\d+$;(.*)$;.*\n/$ID$;$now$;$1$;$groups\n/;
                        if ($SHMID) { # write cache to shared memory
                            shmwrite($SHMID, $Cache, 0, $SHMSIZE)  or printf STDERR "$prefix shmwrite failed \n";
                            semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
                        }
                    }
                    last REQUIRE_2;
		}
            }
        }
    }

    # check the results of the requirement checks
    if ($Attr->{authoritative} eq 'on' && $user_result != OK && $group_result != OK) {
        my $reason;
        $reason .= " USER"  if $user_result  == AUTH_REQUIRED;
        $reason .= " GROUP" if $group_result == AUTH_REQUIRED;
        $r->log_reason("DBI-Authoritative: Access denied on $reason rule(s)", $r->uri);
        $r->note_basic_auth_failure if $authz_denied == AUTH_REQUIRED;
        return $authz_denied;
    }

    # return OK if authorization was successful
    if ($user_result == OK || $group_result == OK) {
        printf STDERR "$prefix return OK\n" if $Apache::AuthDigestDBI::DEBUG > 1;
        return OK;
    }

    # otherwise fall through
    printf STDERR "$prefix fall through, return DECLINED\n" if $Apache::AuthDigestDBI::DEBUG > 1;
    return DECLINED;
}


# The PerlChildInitHandler initializes the shared memory segment (first child)
# or increments the child counter. 
# Note: this handler runs in every child server, but not in the main server.

sub childinit {
    my $prefix = "$$ Apache::AuthDigestDBI         PerlChildInitHandler";
    # create (or re-use existing) semaphore set
    $SEMID = semget($SHMKEY, 1, IPC_CREAT|S_IRUSR|S_IWUSR);
    if (!defined($SEMID)) {
      print STDERR "$prefix semget failed \n";
      return;
    }
    # create (or re-use existing) shared memory segment
    $SHMID = shmget($SHMKEY, $SHMSIZE, IPC_CREAT|S_IRUSR|S_IWUSR);
    if (!defined($SHMID)) {
      print STDERR "$prefix shmget failed \n";
      return;
    }
    # make ids accessible to other handlers
    $ENV{AUTH_SEMID} = $SEMID;
    $ENV{AUTH_SHMID} = $SHMID;
    # read shared memory, increment child count and write shared memory segment
    semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
    shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
    substr($Cache, index($Cache, "\0")) = '';
    my $child_count_new = 1;
    if ($Cache =~ /^(\d+)$;(\d+)\n/) { # segment already exists (eg start of additional server)
        my $time_stamp   = $1;
        my $child_count  = $2;
        $child_count_new = $child_count + 1;
        $Cache =~ s/^$time_stamp$;$child_count\n/$time_stamp$;$child_count_new\n/;
    } else { # first child => initialize segment
        $Cache = time . "$;$child_count_new\n";
    }
    print STDERR "$prefix child count = $child_count_new \n" if $Apache::AuthDigestDBI::DEBUG > 1;
    shmwrite($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmwrite failed \n";
    semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
    1;
}


# The PerlChildExitHandler decrements the child count or destroys the shared memory 
# segment upon server shutdown, which is defined by the exit of the last child.
# Note: this handler runs in every child server, but not in the main server.

sub childexit {
    my $prefix = "$$ Apache::AuthDigestDBI         PerlChildExitHandler";
    # read Cache from shared memory, decrement child count and exit or write Cache to shared memory
    semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
    shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
    substr($Cache, index($Cache, "\0")) = '';
    $Cache =~ /^(\d+)$;(\d+)\n/;
    my $time_stamp  = $1;
    my $child_count = $2;
    my $child_count_new = $child_count - 1;
    if ($child_count_new) {
        print STDERR "$prefix child count = $child_count \n" if $Apache::AuthDigestDBI::DEBUG > 1;
        # write Cache into shared memory
        $Cache =~ s/^$time_stamp$;$child_count\n/$time_stamp$;$child_count_new\n/;
        shmwrite($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmwrite failed \n";
        semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
    } else { # last child
        # remove shared memory segment and semaphore set
        print STDERR "$prefix child count = $child_count, remove shared memory $SHMID and semaphore $SEMID \n" if $Apache::AuthDigestDBI::DEBUG > 1;
        shmctl($SHMID,    IPC_RMID, 0) or print STDERR "$prefix shmctl failed \n";
        semctl($SEMID, 0, IPC_RMID, 0) or print STDERR "$prefix semctl failed \n";
    }
    1;
}


# The PerlCleanupHandler skips through the cache and deletes any outdated entry.
# Note: this handler runs after the response has been sent to the client.

sub cleanup {
    my $prefix = "$$ Apache::AuthDigestDBI         PerlCleanupHandler";
    print STDERR "$prefix \n" if $Apache::AuthDigestDBI::DEBUG > 1;
    my $now = time;
    if ($SHMID) { # do we keep the cache in shared memory ?
        semop($SEMID, $obtain_lock) or print STDERR "$prefix semop failed \n";
        shmread($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmread failed \n";
        substr($Cache, index($Cache, "\0")) = ''; 
    }
    my $newCache = "$now$;"; # initialize timestamp for CleanupHandler
    my ($time_stamp, $child_count);
    foreach my $record (split(/\n/, $Cache)) {
        if (!$time_stamp) { # first record: timestamp of CleanupHandler and child count
            ($time_stamp, $child_count) = split(/$;/, $record);
            $newCache .= "$child_count\n";
            next;
        }
        my ($id, $last_access, $passwd, $groups) = split(/$;/, $record);
        my $diff = $now - $last_access;
        if ($diff >= $CacheTime) {
            print STDERR "$prefix delete >$id<, last access $diff s before \n" if $Apache::AuthDigestDBI::DEBUG > 1;
        } else {
            print STDERR "$prefix keep   >$id<, last access $diff s before \n" if $Apache::AuthDigestDBI::DEBUG > 1;
            $newCache .= "$id$;$now$;$passwd$;$groups\n";
        }
    }
    $Cache = $newCache;
    if ($SHMID) { # write Cache to shared memory
        shmwrite($SHMID, $Cache, 0, $SHMSIZE) or printf STDERR "$prefix shmwrite failed \n";
        semop($SEMID, $release_lock) or print STDERR "$prefix semop failed \n";
    }
    1;
}

sub old_decode_base64 ($)
{
	local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
	
	my $str = shift;
	$str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
	if (length($str) % 4) {
		require Carp;
		Carp::carp("Length of base64 data not a multiple of 4")
	}
	$str =~ s/=+$//;                        # remove padding
	$str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
	
	return join '', map( unpack("u", chr(32 + length($_)*3/4) . $_),
					$str =~ /(.{1,60})/gs);
}

1;

__END__


=head1 NAME

Apache::AuthDigestDBI - Authentication and Authorization via Perl's DBI,
supporting both Basic and Digest Authentication

=head1 SYNOPSIS

 # Configuration in httpd.conf or startup.pl:

 PerlModule Apache::AuthDigestDBI

 # Authentication and Authorization in .htaccess:

 AuthName DBI
 AuthType Digest

 PerlAuthenHandler Apache::AuthDigestDBI::authen
 PerlAuthzHandler  Apache::AuthDigestDBI::authz

 PerlSetVar Auth_DBI_data_source   dbi:driver:dsn
 PerlSetVar Auth_DBI_username      db_username
 PerlSetVar Auth_DBI_password      db_password
 #DBI->connect($data_source, $username, $password)

 PerlSetVar Auth_DBI_pwd_table     users
 PerlSetVar Auth_DBI_uid_field     username
 PerlSetVar Auth_DBI_pwd_field     password
 # authentication: SELECT pwd_field FROM pwd_table WHERE uid_field=$user
 PerlSetVar Auth_DBI_grp_field     groupname
 # authorization: SELECT grp_field FROM pwd_table WHERE uid_field=$user

 require valid-user
 require user   user_1  user_2 ...
 require group group_1 group_2 ...

The AuthType may be Digest or Basic. It will 'fallback' to Basic if the client
ignores the request for Digest authentication. The password B<must not> be encrypted
for Digest authentication and the fallback to Basic. For Basic authentication,
passwords may be encrypted.

You may use one or more valid require lines. For a single require line with the
requirement 'valid-user' or with the requirements 'user user_1 user_2 ...' it is
sufficient to use only the authentication handler.


=head1 DESCRIPTION

This is a hacked up version Apache::AuthDBI that uses Apache::AuthDigest to do
Digest authentication. Please see the docs for Apache::AuthDBI for full usage.


=head1 PREREQUISITES

Note that this module requires Apache::AuthDBI and Apache::AuthDigest.


=head1 SEE ALSO

L<Apache::AuthDBI>, L<Apache::AuthDigest::API>, L<Apache>, L<mod_perl>, L<DBI>


=head1 BUGS

The password must not be encrypted for use with Digest authentication.

When Digest authentication is requested, it accepts Basic authentication. (This
isn't a bug, except that you cannot shut this behavior off.)


=head1 AUTHORS

=item *
Apache::AuthDigestDBI variation by Robert Giseburt <rob@heavyhosting.net>

=item *
Apache::AuthDBI by Edmund Mergl

=item *
mod_perl by Doug MacEachern <modperl-subscribe@apache.org>

=item *
DBI by Tim Bunce <dbi-users-subscribe@perl.org>



=head1 COPYRIGHT

The Apache::AuthDigestDBI module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
