package Apache2::AuthTicketLDAP;
BEGIN {
  $Apache2::AuthTicketLDAP::VERSION = '0.02';
}

# ABSTRACT: Cookie Based Access with LDAP Authentication

use strict;
use base qw(Apache2::AuthTicket);
use Apache2::Const qw(OK HTTP_FORBIDDEN);
use Apache2::ServerUtil;
use CHI;
use DBI;
use Digest::SHA qw/sha512_hex/;
use Net::LDAP;
use Net::LDAP::Entry; # Necessary to find methods for cached entries
use SQL::Abstract;

our (%DEFAULTS);
$DEFAULTS{'LDAPURL'} = 'ldap://ldap.example.com:389';
$DEFAULTS{'LDAPDN'} = 'dc=example,dc=com';
$DEFAULTS{'LDAPScope'} = 'sub';
$DEFAULTS{'LDAPFilter'} = 'uid=MYUSER';
$DEFAULTS{'TicketDBAutoCommit'} = 1;
$DEFAULTS{'TicketThreshold'} = 0;

our $_ldap_handle;
our $CACHE_ENTRY_DELIMITER = q{!/|*};

our $_ldap_entry_cache = CHI->new(
    driver     => 'FastMmap',
    root_dir   => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPCacheDir'),
    cache_size => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPCacheSize'),
    page_size => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPCachePageSize'),
    expire_time => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPCacheTTL'),
    namespace => 'LDAPCache',
);

our $_stmt_cache = CHI->new(
    driver     => 'FastMmap',
    root_dir   => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPCacheDir'),
    cache_size => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPStmtCacheSize'),
    page_size => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPStmtCachePageSize'),
    expire_time => Apache2::ServerUtil->server->dir_config('AuthTicketLDAPStmtCacheTTL'),
    namespace => 'StmtCache',
);

sub hash_for {
    my $self = shift;
    return Digest::SHA::sha512_hex(@_);
}

sub ldap {
    my ($self) = @_;
    if ($_ldap_handle && $_ldap_handle->socket->connected) {
        return $_ldap_handle;
    }
    # Get LDAP config from Apache
    my $ldapurl = $self->get_config('LDAPURL');
    # Query LDAP for user
    $_ldap_handle = Net::LDAP->new($ldapurl)
        or die "$@"; 
    return $_ldap_handle;
}

sub ldap_search {
    my ($self, $user) = @_;
    my ($ldapdn,$ldapscope,$ldapfilter,$ldf,$ldap,$search,$entry,
    $mesg);

    $ldapdn = $self->get_config('LDAPDN');
    $ldapscope = $self->get_config('LDAPScope');
    $ldapfilter = $self->get_config('LDAPFilter');

    $ldf = $ldapfilter;
    $ldf =~ s/MYUSER/$user/g;

    $search = $self->ldap->search(
      base => $ldapdn,
      scope => $ldapscope,
      filter => $ldf
    ) or die "$@"; 

    if ($search->count() <= 0) {
        return undef;
    }

    $entry = $search->pop_entry();
    return $entry;
}

#FIXME CHI documentation suggests we may need to 
# forcibly remove aged cache entries
sub ldap_cache {
    my ($self, $user, $entry) = @_;
    my $auth_name = $self->request->auth_name;

    if (!$user || !$auth_name) {
        return undef;
    }

    my $cache_user = $auth_name . $CACHE_ENTRY_DELIMITER . $user;

    # Store and return LDAP entry
    if ($user && $entry) {
        return $_ldap_entry_cache->set($cache_user, $entry);
    } 
    
    # Retrieve
    my $cached_entry = $_ldap_entry_cache->get($cache_user);
    if ($cached_entry) {
	return $cached_entry;
    }

    $entry = $self->ldap_search($user);
    if ($entry) {
        return $self->ldap_cache($user, $entry);
    }

    return undef;
}

sub check_credentials {
    my ($self, $user, $password) = @_;
    my ($entry, $mesg);
    # 1) check_ldap_cache for UID entry. Avoids anonymous search.
    # 2) if not in cache, run a search and cache the result
    # 3) lastly, bind with supplied password.

    $entry = $self->ldap_cache($user) or return 0;

    $mesg = $self->ldap->bind($entry->dn(), password => $password)
        or die "$@";

    if (!$mesg->is_error()) {
        return 1;
    }

    return 0;
}

sub ldap_attribute {
    my ($class, $r, $args) = @_;
    my ($attr, $val) = split(/=/, $args, 2);
    my ($self, $user, $entry);

    $self = $class->new($r);
    $user = $r->user;
    $entry = $self->ldap_cache($user) or return HTTP_FORBIDDEN;

    for my $a ($entry->get_value($attr)) {
        if ($a eq $val) {
            return OK;
        }
    }

    return HTTP_FORBIDDEN;
}

sub stmt_cache_set {
    my ($self, $cache_stmt, $row) = @_;

    if (!$row && !$cache_stmt) {
        return undef;
    }

    # Store and return stmt result
    return $_stmt_cache->set($cache_stmt, $row);
}

sub stmt_cache {
    my ($self, $stmt, @bind) = @_;

    if (!$stmt) {
        return undef;
    }

    my $cache_stmt = join($CACHE_ENTRY_DELIMITER, $stmt, @bind);

    # Retrieve
    my $cached_entry = $_stmt_cache->get($cache_stmt);
    if ($cached_entry) {
	return $cached_entry;
    }

    my $dbh = $self->dbh;

    my $row = eval {
        $dbh->selectrow_arrayref($stmt, undef, @bind);
    };
    if ($@) {
        $dbh->rollback;
	die $@;
    }

    if ($row) {
        return $self->stmt_cache_set($cache_stmt, $row);
    }

    return undef;

}

sub fetch_secret {
    my ($self, $version) = @_;
    my ($secret_table, $secret_field, $secret_version_field) = $self->secret_table;

    # generate SQL
    my @fields = ($secret_field, $secret_version_field);
    my %where = ( $secret_version_field => $version ) if defined $version;
    my $order = " $secret_version_field DESC ";
    my ($stmt, @bind) = $self->sql->select($secret_table, \@fields, \%where, $order);
    # SQL::Abstract is quoting the version number. DBD::Informix doesn't like that.
    @bind = ($version) if $version;
    # Originally, had DESC LIMIT 1, which Informix doesn't support.
    $stmt =~ s/SELECT/SELECT FIRST 1/;

    # Using our statement cache
    return @{$self->stmt_cache($stmt, @bind)};
}

sub is_hash_valid {
    my ($self, $hash) = @_;

    my ($table, $tick_field, $ts_field) = $self->ticket_table;

    my ($query, @bind) = $self->sql->select($table, [$tick_field, $ts_field], 
        { $tick_field => $hash });

    my ($db_hash, $ts) = (undef, undef);

    # Using our statement cache
    ($db_hash, $ts) = @{$self->stmt_cache($query, @bind) || []};

    if ($ts) {
        $self->{DBTicketTimeStamp} = $ts;   # cache for later use.
    }

    return (defined $db_hash and $db_hash eq $hash) ? 1 : 0;
}

sub _update_ticket_timestamp {
    my ($self, $hash) = @_;

    my $threshold = $self->get_config('TicketThreshold');

    my $db_time = $self->{DBTicketTimeStamp};
    my $time = $self->request->request_time;

    # If the difference between the old timestamp and the new one is not 
    # above the threshold, return. Reduces database updates.
    if ($threshold && $time - $db_time < $threshold) {
        return;
    }

    my $dbh = $self->dbh;

    my ($table, $tick_field, $ts_field) = $self->ticket_table;

    my ($query, @bind) = $self->sql->update($table,
        {$ts_field   => $time},
        {$tick_field => $hash});

    eval {
        my $sth = $dbh->do($query, undef, @bind);
        $dbh->commit unless $dbh->{AutoCommit};
    };
    if ($@) {
        $dbh->rollback;
        die $@;
    }
}

# We do a local connection. Username/Password not required.
# Have to override to make this happen.
# Added configuration for setting AutoCommit Y/N
# Set isolation and lock mode options
sub dbi_connect {
    my $self = shift;

    my $r         = $self->request;
    my $auth_name = $r->auth_name;

    my ($db, $user, $pass, $autocomm) = map {
        $self->get_config($_)
    } qw/TicketDB TicketDBUser TicketDBPassword TicketDBAutoCommit/;

    my $dboptions = {};

    if (defined $autocomm && ($autocomm || $autocomm == 0)) {
        $dboptions->{AutoCommit} = $autocomm;
    }

    $user = $user eq 'test' ? undef $user : $user;
    $pass = $pass eq 'test' ? undef $pass : $pass;

    my $dbh = DBI->connect_cached($db, $user, $pass, $dboptions)
        or die "DBI Connect failure: ", DBI->errstr, "\n";

    my ($scheme, $driver) = DBI->parse_dsn($db)
        or die "DBI DSN parsing failure: ", DBI->errstr, "\n";

    if ($driver eq 'Informix') {
        $dbh->do('SET ISOLATION TO DIRTY READ')
            or die "SET ISOLATION failed: ", DBI->errstr, "\n";
        $dbh->do('SET LOCK MODE TO WAIT 2')
            or die "SET LOCK MODE failed: ", DBI->errstr, "\n";
    }

    return $dbh;
}

1;

=pod

=head1 NAME

Apache2::AuthTicketLDAP - Cookie Ticketing with LDAP Authentication

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 The documentation is largely the same as I<Apache2::AuthTicket>, however, with 
 a few addenda. A typical installation will look like:

 # in httpd.conf
 PerlModule Apache2::AuthTicketLDAP
 PerlSetVar AuthCookieDebug 3 #Useful for debugging
 PerlSetVar AuthTicketLDAPCacheDir "/var/cache/apache"
 PerlSetVar AuthTicketLDAPCacheSize "4m"
 PerlSetVar AuthTicketLDAPCachePageSize "4096"
 PerlSetVar AuthTicketLDAPCacheTTL "10m"
 PerlSetVar AuthTicketLDAPStmtCacheSize "4m"
 PerlSetVar AuthTicketLDAPStmtCachePageSize "4096"
 PerlSetVar AuthTicketLDAPStmtCacheTTL "1m"
 PerlSetVar FooCookieName "MyCookie"
 PerlSetVar FooSatisfy any
 PerlSetVar FooTicketDB dbi:mysql:database=mschout;host=testbed
 PerlSetVar FooTicketDBAutoCommit 0
 PerlSetVar FooTicketDBUser test
 PerlSetVar FooTicketDBPassword secret
 PerlSetVar FooTicketTable tickets:ticket_hash:ts
 PerlSetVar FooTicketSecretTable ticket_secrets:sec_data:sec_version
 PerlSetVar FooTicketExpires 45
 PerlSetVar FooTicketIdleTimeout 30
 PerlSetVar FooTicketThreshold 60
 PerlSetVar FooTicketLogoutURI /foo/index.html
 PerlSetVar FooTicketLoginHandler /foologin
 PerlSetVar FooLoginScript /foologinform
 PerlSetVar FooPath /
 PerlSetVar FooDomain .foo.com
 PerlSetVar FooSecure 1
 PerlSetVar FooLDAPURL "ldap://ldap.foo.com:389"
 PerlSetVar FooLDAPDN "dc=foo,dc=com"
 PerlSetVar FooLDAPScope "one"
 PerlSetVar FooLDAPFilter "uid=MYUSER"

 <Location /foo>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     PerlAuthenHandler Apache2::AuthTicketLDAP->authenticate
     PerlAuthzHandler Apache2::AuthTicketLDAP->authorize
     require ldap_attribute allowedFoo=Yes
     require valid-user
 </Location>
 
 <Location /foologinform>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     SetHandler perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->login_screen
 </Location>

 # Or for a mod_perl script to handle logins, store /foologinform in here and 
 # change:  PerlSetVar FooLoginScript /my/path/cgi-bin/foologinform
 <Directory /my/path/cgi-bin>
     Options ExecCGI
     SetHandler perl-script
     PerlResponseHandler ModPerl::Registry
     PerlOptions +ParseHeaders
     AllowOverride none
     Order allow,deny
     Allow from all
 </Directory>
 
 <Location /foologin>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     SetHandler perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->login
 </Location>
 
 <Location /foo/logout>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     SetHandler perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->logout
 </Location>

=head1 DESCRIPTION

This module builds upon the I<Apache2::AuthTicket> database-backed, cookie 
ticketing system for websites. It provides for authentication and authorization
against an LDAP database. It also implements I<CHI>-based, mmap'd file caching
of LDAP entries and SELECT queries.

Further differences between the two modules include:
 1) Custom dbi_connect, supporting:
    a) passwordless local connections
    b) AutoCommit via TicketDBAutoCommit option
    c) a couple of Informix-specific options (ISOLATION and LOCK MODE)
 2) Use SHA512 instead of MD5 for digests
 3) Support "require ldap_attribute myAttrib=Foo"
 4) TicketThreshold: Only update database when a ticket timestamp is at least
    X seconds old. Reduces database updates.

Keep in mind that the mmap caching will make apache processes look huge. It is 
an illusion -- cached files are only mapped into memory once.

LDAP authentication processing works similarly to mod_ldap/mod_authnz_ldap. 
 1) An anonymous search looks up a user on the LDAP server. 
 Returns 403 if unsuccessful. Otherwise, the entry is cached.
 2) That user's LDAP entry DN and password is used to bind to
 the server. Returns 403 if unsuccessful, OK if successful.

On the database side, everything works the same as I<Apache2::AuthTicket> except
that users are authenticated and authorized with LDAP instead.

Authorization works similarly to mod_ldap/mod_authnz_ldap.
 1) B<require valid-user> works as usual.
 2) B<require ldap-attribute> was changed to B<require ldap_attribute> (note 
 the underscore).
    a) The cache is checked for an LDAP entry for the user. 
    b) If it exists and is not expired, that entry is used. 
    c) Otherwise, a new anonymous search is performed and cached.
    d) If the attribute value does not match, return 403. Otherwise, 
    OK.

=head1 CONFIGURATION

These are the things you must do in order to configure this module: 

 1) Configure your mod_perl apache server.
 2) Create the necessary database tables.
 3) Add a secret to the secrets table.
 4) Ensure the cache directory exists and is read/write for the forked apache 
    user or group.

=head2 Apache Configuration - httpd.conf

There are a number of additional configuration variables required by this
module. Otherwise, configuration is largely the same as with
I<Apache2::AuthTicket>.

Additional per-AuthName variables supported by the I<Apache2::AuthTicket>
configuration mechanism:
  * PerlSetVar SEULDAPURL "ldap://ldap.foo.com:389"
  * PerlSetVar SEULDAPDN "dc=foo,dc=com"
  * PerlSetVar SEULDAPScope "one"
  * PerlSetVar SEULDAPFilter "uid=MYUSER"
  * PerlSetVar SEUTicketDBAutoCommit 0

Additional variables that are defined once in httpd.conf and are global for all
AuthNames and are not configurable through configure():
  * PerlSetVar AuthTicketLDAPCacheDir "/var/cache/apache"
  * PerlSetVar AuthTicketLDAPCacheSize "4m"
  * PerlSetVar AuthTicketLDAPCachePageSize "4096"
  * PerlSetVar AuthTicketLDAPCacheTTL "10m"
  * PerlSetVar AuthTicketLDAPStmtCacheSize "4m"
  * PerlSetVar AuthTicketLDAPStmtCachePageSize "4096"
  * PerlSetVar AuthTicketLDAPStmtCacheTTL "1m"

There are four blocks that need to be entered into httpd.conf.  The first of
these is the block specifying your access restrictions.  This block should look
somrthing like this:

 <Location /foo>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     PerlAuthenHandler Apache2::AuthTicketLDAP->authenticate
     PerlAuthzHandler Apache2::AuthTicketLDAP->authorize
     require valid-user
     require ldap_attribute myAttrib=Foo
 </Location>

The remaining blocks control how to display the login form, and the login and
logout URLs.  These blocks should look similar to this:

 <Location /foologinform>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     SetHandler perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->login_screen
 </Location>
 
 # Or for a mod_perl script to handle logins, store /foologinform in here and 
 # change:  PerlSetVar FooLoginScript /my/path/cgi-bin/foologinform
 <Directory /my/path/cgi-bin>
     Options ExecCGI
     SetHandler perl-script
     PerlResponseHandler ModPerl::Registry
     PerlOptions +ParseHeaders
     AllowOverride none
     Order allow,deny
     Allow from all
 </Directory>

 <Location /foologin>
     AuthType    Apache2::AuthTicketLDAP
     AuthName    Foo
     SetHandler  perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->login
 </Location>
 
 <Location /foo/logout>
     AuthType Apache2::AuthTicketLDAP
     AuthName Foo
     SetHandler perl-script
     PerlResponseHandler Apache2::AuthTicketLDAP->logout
 </Location>

=head2 Apache Configuration - startup.pl

Any non-global I<Apache2::AuthTicketLDAP> configuration items can be set in
startup.pl. You can configure an AuthName like this:

 Apache2::AuthTicketLDAP->configure(String auth_name, *Hash config)

When configuring this way, you don't prefix the configuration items with the 
AuthName value like you do when using PerlSetVar directives.

You must still include I<Apache2::AuthCookie> configuration directives and
I<Apache2::AuthTicketLDAP> global variables in httpd.conf when configuring the
server this way.  These items include:

  * PerlSetVar FooPath /
  * PerlSetVar FooDomain .foo.com
  * PerlSetVar FooSecure 1
  * PerlSetVar FooLoginScript /foologinform
  * PerlSetVar AuthTicketLDAPCacheDir "/var/cache/apache"
  * PerlSetVar AuthTicketLDAPCacheSize "4m"
  * PerlSetVar AuthTicketLDAPCachePageSize "4096"
  * PerlSetVar AuthTicketLDAPCacheTTL "10m"
  * PerlSetVar AuthTicketLDAPStmtCacheSize "4m"
  * PerlSetVar AuthTicketLDAPStmtCachePageSize "4096"
  * PerlSetVar AuthTicketLDAPStmtCacheTTL "1m"

Example of configure():
 Apache2::AuthTicketLDAP->configure('Foo', {
     TicketDB            => 'DBI:mysql:database=test;host=foo',
     TicketDBUser        => 'mschout',
     TicketDBPassword    => 'secret',
     TicketTable         => 'tickets:ticket_hash:ts',
     TicketSecretTable   => 'ticket_secrets:sec_data:sec_version',
     TicketExpires       => '15',
     TicketLogoutURI     => '/foo/index.html',
     TicketLoginHandler  => '/foologin',
     TicketIdleTimeout   => 5,
     TicketThreshold     => 60,
     LDAPURL             => 'ldap://ldap.foo.com:389',
     LDAPDN              => 'dc=foo,dc=com',
     LDAPScope           => 'one',
     LDAPFilter          => 'uid=MYUSER',
     TicketDBAutoCommit  => 0,
 });

Configuration is the same as with I<Apache2::AuthTicket> and 
I<Apache2::AuthCookie>, though B<TicketUserTable> and B<TicketPasswordStyle>
are ignored.

The following directives are added by this module:

=over 3

=item B<TicketThreshold>

This directive tells the module to only update the database when a ticket 
timestamp is at least X seconds old. Reduces database updates.

 Example: 60
 Default: 0 (always update)
 Required: No

=item B<TicketDBAutoCommit>

This directive tells whether to start the database connection in AutoCommit 
mode or not.

 Example: 0
 Default: 1
 Required: No

=item B<AuthTicketLDAPCacheDir>

Set the file path of the cache directory to be used by I<CHI>. It is the same
for both the statement and LDAP entry caches.

 Example: /var/cache/apache
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPCacheSize>

Set the size of the LDAP entry cache. You can use 1k or 1m for kilobytes or 
megabytes, respectively.

 Example: 4m
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPCachePageSize>

Set the page size of the LDAP entry cache. In bytes.

 Example: 4096
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPCacheTTL>

Set the maximum time a cached LDAP entry is considered "good". You can use 1m,
1h, or 1d for minutes, hours, days, respectively. N.b., expired entries remain
in the cache. They are ignored until their space is needed.

 Example: 10m
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPStmtCacheSize>

Set the size of the SELECT statement cache. You can use 1k or 1m for kilobytes
or megabytes, respectively.

 Example: 4m
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPStmtCachePageSize>

Set the page size of the SELECT statement cache. In bytes.

 Example: 4096
 Default: <none>
 Required: Yes

=item B<AuthTicketLDAPStmtCacheTTL>

Set the maximum time a cached SELECT result is considered "good". You can use 
1m, 1h, or 1d for minutes, hours, days, respectively. N.b., expired entries 
remain in the cache. They are ignored until their space is needed.

 Example: 1m
 Default: <none>
 Required: Yes

=item B<LDAPURL>

Set the URL for the LDAP server. The default is there to comply with 
I<Apache2::AuthTicket>'s admittedly weird standard of providing unlikely 
defaults for things which should be overridden.

 Example: ldap://ldap.example.com:389
 Default: ldap://ldap.example.com:389
 Required: No, but really Yes

=item B<LDAPDN>

Set the LDAP Distinguished Name for searching.

 Example: dc=example,dc=com
 Default: dc=example,dc=com
 Required: No, but really Yes

=item B<LDAPScope>

Set the LDAP scope for searching. Valid: one, sub, base.

 Example: one
 Default: sub
 Required: No

=item B<LDAPFilter>

Set the LDAP filter for searching. The text MYUSER will be replaced with the
supplied login name.

 Example: uid=MYUSER
 Default: uid=MYUSER
 Required: No

=back

=head2 Database Configuration

Only the tickets and secrets tables from I<Apache2::AuthTicket> are needed for
this module. Please refer to that module's documentation for detailed 
implementation details.

One important difference is that due to this module's usage of SHA512, the 
ticket size is 128.

The following is just a summary:

=over 3

=item B<tickets table>

 Example:

 CREATE TABLE tickets (
    ticket_hash CHAR(128) NOT NULL,
    ts          INT NOT NULL,
    PRIMARY KEY (ticket_hash)
 );

=item B<secrets table>

 Example:

 CREATE TABLE ticketsecrets (
     sec_version  SERIAL,
     sec_data     TEXT NOT NULL
 );

=back

=head1 METHODS

=over

=back

=head1 CREDITS

Many thanks to Michael Schout for writing I<Apache2::AuthTicket>. Additional 
thanks to St. Edward's University for providing the resources to write this 
module.

=head1 SEE ALSO

L<Apache2::AuthTicket>, L<Apache2::AuthCookie>, L<Net::LDAP>, L<CHI>, L<CHI::Driver::FastMmap>

=head1 AUTHOR

Stephen Olander-Waters <stephenw@stedwards.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by St. Edward's University.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

