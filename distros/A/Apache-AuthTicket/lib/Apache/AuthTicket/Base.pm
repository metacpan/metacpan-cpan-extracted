package Apache::AuthTicket::Base;
BEGIN {
  $Apache::AuthTicket::Base::VERSION = '0.93';
}

# ABSTRACT: Common methods for all Apache::AuthTicket versions.

use strict;
use base qw(Class::Accessor::Fast);
use DBI;
use SQL::Abstract;
use MRO::Compat;
use Digest::MD5;
use MIME::Base64 ();
use Storable ();
use ModPerl::VersionUtil;

use constant DEBUGGING => 0;

__PACKAGE__->mk_accessors(qw(request _secret_version _dbh _sql));

# configuration items
# PerlSetVar FooTicketDB  dbi:Pg:dbname=template1
# PerlSetVar FooDBUser     test
# PerlSetVar FooDBPassword  test
# PerlSetVar FooTicketTable tickets:ticket_hash
# PerlSetVar FooUserTable   users:usrname:passwd
# PerlSetVar FooPasswordStyle cleartext
# PerlSetVar FooSecretTable   ticketsecrets:sec_data:sec_version

our %DEFAULTS = (
    TicketExpires         => 15,
    TicketIdleTimeout     => 0,
    TicketLogoutURI       => '/',
    TicketDB              => 'dbi:Pg:dbname=template1',
    TicketDBUser          => 'test',
    TicketDBPassword      => 'test',
    TicketTable           => 'tickets:ticket_hash',
    TicketUserTable       => 'users:usrname:passwd',
    TicketPasswordStyle   => 'cleartext',
    TicketSecretTable     => 'ticketsecrets:sec_data:sec_version',
    TicketLoginHandler    => '/login',
    TicketCheckIP         => 1,
    TicketCheckBrowser    => 0
);

# configured items get dumped in here
our %CONFIG = ();

sub configure {
    my ($class, $auth_name, $conf) = @_;

    $class->push_handler(PerlChildInitHandler => sub {
        for (keys %$conf) {
            die "bad configuration parameter $_" unless defined $DEFAULTS{$_};
            $CONFIG{$auth_name}{$_} = $conf->{$_};
        }
    });
}

# check credentials and return a session key if valid
# return undef if invalid
sub authen_cred {
    my ($class, $r, $user, $pass) = @_;

    my $self = $class->new($r);

    if ($self->check_credentials($user, $pass)) {
        return $self->make_ticket($user);
    }
    else {
        return undef;
    }
}

# check a session key, return user id
# return undef if its not valid.
sub authen_ses_key {
    my ($class, $r, $session_key) = @_;

    my $self = $class->new($r);

    if (my $ticket = $self->parse_ticket($session_key)) {
        return $$ticket{user};
    }
    else {
        return undef;
    }
}

sub _error_reason {
    my ($self, $reason) = @_;

    $self->request->subprocess_env(AuthTicketReason => $reason);

    return;
}


sub parse_ticket {
    my ($self, $key) = @_;

    my $r = $self->request;

    my ($hash, $data) = split '--', $key
        or return $self->_error_reason('malformed_ticket');

    my ($secret, $version);
    unless ($self->is_hash_valid($hash)) {
        return $self->_error_reason('invalid_hash');
    }

    my $ticket = $self->unserialize_ticket($data)
        or return $self->_error_reason('malformed_ticket');

    unless ($r->request_time < $$ticket{expires}) {
        return $self->_error_reason('expired_ticket');
    }

    unless (($secret, $version) = $self->fetch_secret($$ticket{version})) {
        # can't get server secret
        return $self->_error_reason('missing_secret');
    }

    if ($self->_ticket_idle_timeout($hash, $ticket)) {
        # user has exceeded idle-timeout
        $self->delete_hash($hash);
        return $self->_error_reason('idle_timeout');
    }

    unless ($self->_is_ticket_signature_valid($data, $hash, $secret)) {
        return $self->_error_reason('tampered_hash');
    }

    # otherwise, everything is ok
    $self->_update_ticket_timestamp($hash);

    return $ticket;
}

sub _is_ticket_signature_valid {
    my ($self, $data, $hash, $secret) = @_;

    my @fields = ($secret, $data);

    if ($self->get_config('TicketCheckIP')) {
        my $ip = $self->request->connection->remote_ip;
        push @fields, $ip;
    }

    if ($self->get_config('TicketCheckBrowser')) {
        push @fields, $self->user_agent;
    }

    warn "FIELDS: [@fields]\n" if DEBUGGING;

    my $newhash = $self->hash_for(@fields);

    if ($newhash eq $hash) {
        return 1;
    }
    else {
        return 0;
    }
}

sub sql {
    my $self = shift;

    unless (defined $self->_sql) {
        $self->_sql( SQL::Abstract->new );
    }

    $self->_sql;
}

sub get_config {
    my ($self, $name) = @_;

    unless (defined $self->{config}{$name}) {
        my $r = $self->request;
        my $auth_name = $r->auth_name;

        $self->{config}{$name} =
            $self->str_config_value(
                $r->dir_config("${auth_name}$name"),
                $CONFIG{$auth_name}{$name},
                $DEFAULTS{$name});
    }

    return $self->{config}{$name}
}

sub login_screen ($$) {
    my ($class, $r) = @_;

    my $self = $class->new($r);

    my $action = $self->get_config('TicketLoginHandler');

    my $destination = $r->prev->uri;
    my $args = $r->prev->args;
    if ($args) {
        $destination .= "?$args";
    }

    $class->make_login_screen($r, $action, $destination);

    return $class->apache_const('OK');
}

sub make_login_screen {
    my ($self, $r, $action, $destination) = @_;

    if (DEBUGGING) {
        # log what we think is wrong.
        my $reason = $r->prev->subprocess_env("AuthCookieReason");
        $r->log_error("REASON FOR AUTH NEEDED: $reason");
        $reason = $r->prev->subprocess_env("AuthTicketReason");
        $r->log_error("AUTHTICKET REASON: $reason");
    }

    $r->content_type('text/html');

    $r->send_http_header if ModPerl::VersionUtil->is_mp1;

    $r->print(
        q{<!DOCTYPE HTML PUBLIC  "-//W3C//DTD HTML 3.2//EN">},
        q{<HTML>},
        q{<HEAD>},
        q{<TITLE>Log in</TITLE>},
        q{</HEAD>},
        q{<BODY bgcolor="#ffffff">},
        q{<H1>Please Log In</H1>}
    );

    $r->print(
        qq{<form method="post" action="$action">},
        qq{<input type="hidden" name="destination" value="$destination">},
        q{<table>},
        q{<tr>},
        q{<td>Name</td>},
        q{<td><input type="text" name="credential_0"></td>},
        q{</tr>},
        q{<tr>},
        q{<td>Password</td>},
        q{<td><input type="password" name="credential_1"></td>},
        q{</tr>},
        q{</table>},
        q{<input type="submit" value="Log In">},
        q{<p>},
        q{</form>},
        q{<EM>Note: </EM>},
        q{Set your browser to accept cookies in order for login to succeed.},
        q{You will be asked to log in again after some period of time.},
        q{</body></html>}
    );

    return $self->apache_const('OK');
}

sub logout ($$) {
    my ($class, $r) = @_;

    my $self = $class->new($r);

    $self->delete_ticket($r);
    $self->next::method($r); # AuthCookie logout

    $r->headers_out->add(Location => $self->get_config('TicketLogoutURI'));

    return $class->apache_const('REDIRECT');
}

##################### END STATIC METHODS ###########################3
sub new {
    my ($class, $r) = @_;

    return $class->SUPER::new({request => $r});
}

sub dbh {
    my $self = shift;

    unless (defined $self->_dbh) {
        $self->_dbh($self->dbi_connect);
    }

    $self->_dbh;
}

sub dbi_connect {
    my $self = shift;

    my $r         = $self->request;
    my $auth_name = $r->auth_name;

    my ($db, $user, $pass) = map {
        $self->get_config($_)
    } qw/TicketDB TicketDBUser TicketDBPassword/;

    my $dbh = DBI->connect_cached($db, $user, $pass)
        or die "DBI Connect failure: ", DBI->errstr, "\n";

    return $dbh;
}

sub check_credentials {
    my ($self, $user, $password) = @_;

    my ($table, $user_field, $pass_field) = $self->user_table;

    my ($stmt, @bind) =
        $self->sql->select($table, $pass_field, {$user_field => $user});

    my ($db_pass) = eval {
        $self->dbh->selectrow_array($stmt, undef, @bind);
    };
    if ($@) {
        $self->dbh->rollback;
        return 0;
    }

    unless (defined $db_pass) {
        # user not in database
        return 0;
    }

    my $style = $self->get_config('TicketPasswordStyle');

    if ($self->compare_password($style, $password, $db_pass)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub fetch_secret {
    my ($self, $version) = @_;

    my $dbh = $self->dbh;

    my ($secret_table, $secret_field, $secret_version_field) = $self->secret_table;

    # generate SQL
    my @fields = ($secret_field, $secret_version_field);
    my %where = ( $secret_version_field => $version ) if defined $version;
    my $order = " $secret_version_field DESC LIMIT 1 ";
    my ($stmt, @bind) = $self->sql->select($secret_table, \@fields, \%where, $order);

    return eval {
        $dbh->selectrow_array($stmt, undef, @bind);
    };
    if ($@) {
        $dbh->rollback;
        die $@;
    }
}

sub secret_version {
    my $self = shift;

    unless (defined $self->_secret_version) {
        $self->_secret_version( ($self->fetch_secret)[1] );
    }

    return $self->_secret_version;
}

sub make_ticket {
    my ($self, $user_name) = @_;

    my $ticket = $self->new_ticket_for($user_name);

    my ($secret) = $self->fetch_secret($$ticket{version});

    my $data = $self->serialize_ticket($ticket);

    my @fields = ($secret, $data);

    # only add ip if TicketCheckIP is on.
    if ($self->get_config('TicketCheckIP')) {
        push @fields, $self->request->connection->remote_ip;
    }

    if ($self->get_config('TicketCheckBrowser')) {
        push @fields, $self->user_agent;
    }

    my $hash = $self->hash_for(@fields);

    eval {
        $self->save_hash($hash);
    };
    if ($@) {
        warn "save_hash() failed, treating this request as invalid login.\n";
        warn "reason: $@";
        return;
    }

    return join '--', $hash, $data;
}

sub serialize_ticket {
    my ($self, $hashref) = @_;

    return MIME::Base64::encode( Storable::nfreeze($hashref), '' );
}

sub unserialize_ticket {
    my ($self, $data) = @_;

    return Storable::thaw( MIME::Base64::decode($data) );
}

sub new_ticket_for {
    my ($self, $user_name) = @_;

    my $now     = time;
    my $expires = $now + $self->get_config('TicketExpires') * 60;

    return {
        version => $self->secret_version,
        time    => $now,
        user    => $user_name,
        expires => $expires
    };
}

sub delete_ticket {
    my ($self, $r) = @_;

    my $key = $self->key($r);
    warn "delete_ticket: key $key" if DEBUGGING;

    my ($hash) = split '--', $key or return;

    $self->delete_hash($hash);
}

########## SERVER SIDE HASH MANAGEMENT METHODS

sub _update_ticket_timestamp {
    my ($self, $hash) = @_;

    my $time = $self->request->request_time;
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

# boolean _ticket_idle_timeout(String hash, Hashref ticket)
#
# return true if the ticket table timestamp is older than the IdleTimeout
# value.
sub _ticket_idle_timeout {
    my ($self, $hash, $ticket) = @_;

    my $idle = $self->get_config('TicketIdleTimeout') * 60;
    return 0 unless $idle;       # if not timeout set, its still valid.

    my $db_time = $self->{DBTicketTimeStamp};
    my $time = $self->request->request_time;
    if (DEBUGGING) {
        warn "Last activity: ", ($time - $db_time), " secs ago\n";
        warn "Fail if thats > ", ($idle), "\n";
    }

    if ( ($time - $db_time)  > $idle ) {
        # its timed out
        return 1;
    }
    else {
        return 0;
    }
}

sub save_hash {
    my ($self, $hash) = @_;

    my ($table, $tick_field, $ts_field) = $self->ticket_table;

    my ($query, @bind) = $self->sql->insert($table, {
        $tick_field => $hash,
        $ts_field   => $self->request->request_time });

    my $dbh = $self->dbh;

    eval {
        my $sth = $dbh->do($query, undef, @bind);
        $dbh->commit unless $dbh->{AutoCommit};
    };
    if ($@) {
        $dbh->rollback;
        die $@;
    }
}

sub delete_hash {
    my ($self, $hash) = @_;

    my ($table, $tick_field) = $self->ticket_table;

    my ($query, @bind) = $self->sql->delete($table, { $tick_field => $hash });

    my $dbh = $self->dbh;

    eval {
        my $sth = $dbh->do($query, undef, @bind);
        $dbh->commit unless $dbh->{AutoCommit} || 0;
    };
    if ($@) {
        $dbh->rollback;
        die $@;
    }
}

sub is_hash_valid {
    my ($self, $hash) = @_;

    my ($table, $tick_field, $ts_field) = $self->ticket_table;

    my ($query, @bind) = $self->sql->select($table, [$tick_field, $ts_field], 
        { $tick_field => $hash });

    my $dbh = $self->dbh;

    my ($db_hash, $ts) = (undef, undef);
    eval {
        ($db_hash, $ts) = $dbh->selectrow_array($query, undef, @bind);
        $self->{DBTicketTimeStamp} = $ts;   # cache for later use.
    };
    if ($@) {
        $dbh->rollback;
        die $@;
    }

    return (defined $db_hash and $db_hash eq $hash) ? 1 : 0;
}

sub hash_for {
    my $self = shift;

    return Digest::MD5::md5_hex(@_);
}

sub user_agent {
    my $self = shift;

    return $ENV{HTTP_USER_AGENT}
        || $self->request->headers_in->get('User-Agent')
        || '';
}

sub compare_password {
    my ($self, $style, $check, $expected) = @_;

    if ($style eq 'crypt') {
        return crypt($check, $expected) eq $expected;
    }
    elsif ($style eq 'cleartext') {
        return $check eq $expected;
    }
    elsif ($style eq 'md5') {
        return Digest::MD5::md5_hex($check) eq $expected;
    }
    else {
        die "unrecognized password style '$style'";
    }

    return 0;
}

sub str_config_value {
    my $self = shift;

    for my $value (@_) {
        next unless defined $value;

        my $test = lc $value;

        # convert booleans to 1/0
        if ($test =~ /^(?:1|on|yes|true)$/) {
            return 1;
        }
        elsif ($test =~ /^(?:0|off|no|false)$/) {
            return 0;
        }
        else {
            # return value unchanged.
            return $value;
        }
    }

    return;
}

sub ticket_table {
    my $self = shift;

    return split ':', $self->get_config('TicketTable');
}

sub user_table {
    my $self = shift;

    return split ':', $self->get_config('TicketUserTable');
}

sub secret_table {
    my $self = shift;

    return split ':', $self->get_config('TicketSecretTable');
}

sub push_handler { die "unimplemented" }

sub set_user { die "unimplemented" }

sub apache_const { die "unimplemented" }

1;



=pod

=head1 NAME

Apache::AuthTicket::Base - Common methods for all Apache::AuthTicket versions.

=head1 VERSION

version 0.93

=head1 SYNOPSIS

 # This module is internal to Apache::AuthTicket.  you should never use this
 # module directly.

=head1 DESCRIPTION

This module is a base class providing common methods for C<Apache::AuthTicket>
and C<Apache2::AuthTicket>.

=head1 METHODS

=head2 configure

 Apache2::AuthTicket->configure(AuthName =>
    TicketUserTable => 'users:user_name:pass',
    TicketLoginHandler => '/login',
    ...
 );

This sets configuration values for a given AuthName.  This is an alternative to
using PerlSetVar's to specify all of the configuration settings.

=head2 parse_ticket

 my $ok = $self->parse_ticket($ticket_string)

Verify the ticket string.  If the ticket is invalid or tampered, the C<AuthTicketReason> subprocess_env setting will be set to one of the following:

=over 4

=item *

malformed_ticket

Ticket does not contain the required fields

=item *

invalid_hash

Ticket hash is not found in the database

=item *

expired_ticket

Ticket has expired

=item *

missing_secret

Secret that signed this ticket was not found

=item *

idle_timeout

Ticket idle timeout exceeded

=item *

tampered_hash

Ticket has been tampered with.  The checksum does not match the checksum in the
ticket

=back

=head2 sql

Get the C<SQL::Abstract> object.

=head2 get_config

 my $value = $self->get_config($name)

Get a configuration value, or its default value if the setting is not
configured.

=head2 make_login_screen

 my $result = $self->make_login_screen($r, $action, $destination)

Print out the login screen html, and return an Apache status code.

=head2 dbh

Get the database handle

=head2 dbi_connect

 my $dbh = $self->dbi_connect

Returns a new connection to the database

=head2 check_credentials

 my $ok = $self->check_credentials($username, $password)

Return C<true> if the credentials are valid

=head2 fetch_secret

 my ($value, $version) = $self->fetch_secret;
 my ($value) = $self->fetch_secret($version)

Return the secret and version of the secret.  if the C<version> argument is
present, return that specific version of the secret instead of the most recent
one.

=head2 secret_version

Returns the version of the current (most-recent) secret

=head2 make_ticket

 my $string = $self->make_ticket($username)

Creates a ticket string for the given username

=head2 serialize_ticket

 my $data = $self->serialize_ticket($hashref)

Encode the hashref in a format suitable for sending in a HTTP cookie

=head2 unserialize_ticket

 my $hashref = $self->unserialize_ticket($data)

Decode cookie data into hashref.  This is the opposite of serialize_ticket()

=head2 new_ticket_for

 my $hashref = $self->new_ticket_for($username)

Creates new ticket hashref for the given username.  You could overload this to
append extra fields to the ticket.

=head2 delete_ticket

 $self->delete_ticket($r)

Invalidates the ticket by expiring the cookie and deletes the hash from the database

=head2 save_hash

 $self->save_hash($hash)

save the hash value/checksum in the database

=head2 delete_hash

 $self->delete_hash($hash)

Remove the given hash from the database.

=head2 is_hash_valid

 my $ok = $self->is_hash_valid($hash)

Return C<true> if the given hash is in the local database

=head2 hash_for

 my $hash = $self->hash_for(@values)

Compute a hash for the given values

=head2 user_agent

 my $agent = $self->user_agent

Get the request client's user agent string

=head2 compare_password

 my $ok = $self->compare_password($style, $entered, $actual)

Check a password and return C<true> if C<entered> matches C<actual>.  C<style> specifys what type of password is in C<actual>, and is one of the following:

=over 4

=item *

crypt

standard UNIX C<crypt()> value

=item *

cleartext

plain text password

=item *

md5

MD5 hash of password

=back

=head2 str_config_value

 my $val = $self->str_config_value($name)

Get a configuration value.  This converts things like yes,on,true to C<1>, and
no,off,false to C<0>.  Multiple C<name> values may be given and the first
defined value will be returned.  If no config value is defined matching any of
the given C<name>'s, then C<undef> is returned.

=head2 ticket_table

 my ($name, $hash_col, $timestamp_col) = $self->ticket_table

Unpacks the config value C<TicketTable> into its components.

=head2 user_table

 my ($name, $hash_col, $timestamp_col) = $self->ticket_table

Unpacks the config value C<TicketUserTable> into its components.

=head2 secret_table

 my ($name, $hash_col, $timestamp_col) = $self->ticket_table

Unpacks the config value C<TicketSecretTable> into its components.

=head2 push_handler

 $class->push_handler($name => sub { ... });

B<Subclass Must Implement This>.  Push the given subroutine as a mod_perl
handler

=head2 set_user

 $self->set_user($username)

B<Subclass Must Implement This>.  Set the username for this request.

=head2 apache_const

 my $const = $self->apache_const($name)

B<Subclass Must Implement This>.  Return the given apache constant.

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/apache-authticket>
and may be cloned from L<git://github.com/mschout/apache-authticket.git>

=head1 BUGS

Please report any bugs or feature requests to bug-apache-authticket@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-AuthTicket

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

