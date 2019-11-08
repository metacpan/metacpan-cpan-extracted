# Connector::Builtin::Authentication::LDAP
#
# Authenticate users against LDAP directory.
#
# NOTE: This module shoud (in theory) use the Connetor::Proxy::Net::LDAP,
# but it didn't fit well. Reusing the proxy connector would require too much of
# hacking.
package Connector::Builtin::Authentication::LDAP;

use strict;
use warnings;
use English;
use Template;
use Data::Dumper;
use Net::LDAP;

use Moose;
extends 'Connector::Builtin';

#
# Options used by Net::LDAP::new()
#
has keepalive => (
    is => 'rw',
    isa => 'Int',
);

has timeout => (
    is => 'rw',
    isa => 'Int',
);

has multihomed => (
    is => 'rw',
    isa => 'Int',
);

has localaddr => (
    is  => 'rw',
    isa => 'Str',
);

has debug => (
    is  => 'rw',
    isa => 'Int',
);

# SSL options for Net::LDAP::new()
has verify => (
    is  => 'rw',
    isa => 'Int',
);

has sslversion => (
    is => 'rw',
    isa => 'Str',
);

has ciphers => (
    is  => 'rw',
    isa => 'Str',
);

has cafile => (
    is  => 'rw',
    isa => 'Str',
);

has capath => (
    is  => 'rw',
    isa => 'Str',
);

has clientcert => (
    is  => 'rw',
    isa => 'Str',
);

has clientkey => (
    is  => 'rw',
    isa => 'Str',
);

has checkcrl => (
    is  => 'rw',
    isa => 'Int',
);

#
# Options used by _bind()
#
has binddn => (
    is  => 'rw',
    isa => 'Str',
);

has password => (
    is  => 'rw',
    isa => 'Str',
);


#
# Options used by Net::LDAP::search()
#
has timelimit => (
    is  => 'rw',
    isa => 'Int',
);

has sizelimit => (
    is  => 'rw',
    isa => 'Int',
);

has base => (
    is  => 'rw',
    isa => 'Str',
);

has filter => (
    is  => 'rw',
    # TODO: this does not work (currently); NB: do we need that?
    #    isa => 'Str|Net::LDAP::Filter',
    isa => 'Str',
);

has scope => (
    is  => 'rw',
    isa => 'Str',
);

#
# Authentication-specific options
#
has userattr => (
    is => 'rw',
    isa => 'Str',
    default => 'uid',
);

has groupattr => (
    is => 'rw',
    isa => 'Str',
    default => 'member',
);

has groupdn => (
    is => 'rw',
    isa => 'Str',
);

has indirect => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has ambiguous => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

#
# Lazy method to initiate LDAP connection once
#
has ldap => (
    is => 'ro',
    isa => 'Net::LDAP',
    builder => '_new_ldap',
    reader => '_ldap',
    lazy => 1,
);

sub _build_options {
    my $self = shift;

    my %options;
    foreach my $key (@_) {
        if (defined $self->$key()) {
            $options{$key} = $self->$key();
        }
    }
    return %options;
}

sub _build_new_options {
    my $self = shift;
    my %options = $self->_build_options(qw( keepalive timeout multihomed localaddr
                                     debug verify sslversion ciphers cafile
                                     capath clientcert clientkey checkcrl ));
    $self->log()->debug('LDAP connection ' . Data::Dumper->Dump([\%options],[qw(*options)]));
    return %options;
}

sub _build_bind_options {
    my $self = shift;
    return $self->_build_options(qw( password ));
}

# NOTE: it requires $arg->{LOGIN} to be defined and well formed!!
sub _build_search_options {
    my $self = shift;
    my $arg = shift;

    my %options = $self->_build_options(qw( base scope sizelimit timelimit ));

    my $filter = $self->filter();
    if(!defined $filter) {
        $filter = '('.$self->userattr().'=[% LOGIN %])';
    }

    # template expansion is performed on filter strings only, not
    # on Net::LDAP::Filter objects
    my $value;
    if (ref $filter eq '') {
        my $template = Template->new({ });
        $template->process(\$filter, $arg, \$value) || die "Error processing argument template.";
        $options{filter} = $value;
    } else {
        $options{filter} = $filter;
    }

    # We don't retrieve any attributes!!! Just search for user's DN.
    #$options{attrs} = ['dn'];

    $self->log()->debug('LDAP search ' . Data::Dumper->Dump([\%options],[qw(*options)]));

    return %options;
}

# NOTE: it returns undef in case of error
sub _new_ldap {
    my $self = shift;
    my $ldapuri = $self->LOCATION();
    $self->log()->debug('Connecting to "' . $ldapuri .'"');
    my $ldap = Net::LDAP->new(
        $ldapuri,
        onerror => 'undef',
        $self->_build_new_options(),
    );
    if(defined $ldap) {
        $self->log()->debug('Connection established');
    } else {
        $self->log()->error('Connection failed (error: '.$@.')');
    }
    return $ldap;
}

# NOTE: it returns undef in case of error
sub _bind {
    my $self = shift;
    my $mesg;
    my $ldap = $self->_ldap;
    if(!defined $ldap) {
        return undef;
    }
    if(defined $self->binddn()) {
        $self->log()->debug('Binding to "'.$self->binddn().'"');
        my %options = $self->_build_bind_options();
        $self->log()->warn('Binding with DN but without password') if (!defined $options{password});
        $mesg = $ldap->bind(
            $self->binddn(),
            %options,
        );
    } else {
        # anonymous bind
        $self->log()->debug('Binding anonymously');
        $mesg = $ldap->bind(
            $self->_build_bind_options(),
        );
    }
    if($mesg->is_error()) {
        $self->log()->error('LDAP bind returned error code '.$mesg->code.' (error: '.$mesg->error_desc.')');
        return undef;
    } else {
        $self->log()->debug('LDAP bind successfull');
        return $ldap;
    }
}

# NOTE: it returns undef in case of error, or ref to an array of user DNs
#       it MAY return an empty array if user is not found
sub _search_user {
    my $self = shift;
    my $user = shift;

    my $ldap = $self->_ldap();
    if(!defined $ldap) {
        $self->log()->error('Can not perform LDAP search');
        return undef;
    }
    $self->log()->debug('Searching LDAP databse for user "'.$user. '"');
    my $result = $ldap->search(
        $self->_build_search_options({ LOGIN => $user })
    );
    if($result->is_error()) {
        $self->log()->error('LDAP search returned error code '.$result->code.' (error: '.$result->error_desc().')');
        return undef;
    } else {
        $self->log()->debug('LDAP search returned '.$result->count . (($result->count ==1) ? ' entry' : ' entries'));
    }
    if($self->groupdn()) {
        $self->log()->debug('Group check requested, groupdn: "'.$self->groupdn().'", groupattr: "'.$self->groupattr().'"');
    }
    my $dns;
    for my $entry ($result->entries()) {
        my $dn = $entry->dn();
        if(defined $self->groupdn()) {
            if(!$self->_check_user_group($dn)) {
                next;
            }
        }
        push(@$dns, $dn);
    }
    return $dns;
}

sub _check_user_group {
    my $self = shift;
    my $dn = shift;
    my $ldap = $self->_ldap();
    $self->log()->debug('Checking if "'.$dn.'" belongs to group "'.$self->groupdn().'"');
    my $result = $ldap->compare($self->groupdn(), attr => $self->groupattr(), value => $dn);
    if($result->is_error()) {
      $self->log()->error('LDAP compare returned error code '.$result->code.' (error: '.$result->error_desc().')');
      return 0;
    }
    if($result->code != 6) { # !compareTrue
      $self->log()->debug('User "'.$dn.'" does not belong to group "'.$self->groupdn().'"');
      return 0;
    }
    $self->log()->debug('User "'.$dn.'" belongs to group "'.$self->groupdn().'"');
    return 1
}

sub _check_user_password {
    my $self = shift;
    my $userdns = shift;
    my $password = shift;
    my $ldap = $self->_ldap;

    my $userdn;
    foreach my $dn (@$userdns) {
      # Try to bind to $dn
      $self->log()->debug('Trying to bind to dn: '.$dn);
      my $mesg = $ldap->bind($dn, password => $password);
      if($mesg->is_error()) {
        $self->log()->debug('LDAP bind to '.$dn.' returned error code '.$mesg->code.' (error: '.$mesg->error_desc().')');
      } else {
        $self->log()->debug('LDAP bind to '.$dn.' succeeded');
        $userdn = $dn;
        last;
      }
    }

    if(!defined $userdn) {
      $self->log()->error('Authentication failed');
      return 0;
    } else {
      $self->log()->info('User successfuly authenticated: (dn: '.$userdn.')');
      return 1;
    }
}

sub get {
    my $self = shift;
    my $arg = shift;
    my $params = shift;

    my @args = $self->_build_path( $arg );
    my $user = shift @args;

    my $password = $params->{password};

    if(!$user) {
        $self->log()->error('Missing user name');
        return undef;
    }
    # enforce valueencoding, see RFC4515, note that we allow non-ascii (utf-8) characters
    # I assume that Net::LDAP->search() escapes them internally as needed
    if (!($user =~ /^([\x01-\x27\x2B-\x5B\x5D-\x7F]|[^[:ascii:]]|\\[0-9a-fA-F][0-9a-fA-F])*$/)) {
        $self->log()->error('Invalid chars in username ("'.$user.'")');
        return undef;
    }

    #
    # let's check if we were instructed to search for the auth user
    #
    my @userdns;
    if($self->indirect()) {
        $self->_bind();
        my $result = $self->_search_user($user);
        if(!defined $result) {
            return $self->_node_not_exists($user);
        }
        @userdns = @$result;
        my $count = @userdns;
        if($count == 0) {
            $self->log()->error('User not found in LDAP database');
            return $self->_node_not_exists($user);
        } elsif($count > 1) {
            $self->log()->debug('Found '.$count.' LDAP entries matching the user "'.$user.'"');
            if(!$self->ambiguous()) {
                $self->log()->error('Ambiguous search result');
                return $self->_node_not_exists($user);
            }
        }
    } else {
        if($self->groupdn()) {
            $self->_bind();
            if(!$self->_check_user_group($user)) {
                return $self->_node_not_exists($user);
            }
        }
        @userdns = ($user);
    }

    return $self->_check_user_password(\@userdns, $password);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

Connector::Builtin::Authentication::LDAP

=head1 DESCRIPTION

Connector (see perldoc I<Connector>) to authenticate users against LDAP.
Supports simple authentication (via LDAP bind), SASL authentication is not
supported.

The module allows for direct bind or indirect bind (with preliminary user
search). Direct bind is the most straightforward method, but it requires
users to know their Distinguished Names (DNs) in LDAP. Indirect bind is more
convenient for users, but it involves LDAP database search, which requires read
access to larger parts of LDAP directory (so LDAP ACLs must be set properly to
allow indirect bind).

The module implements group participation checking. With this option enabled,
only users that belong to a predefined group may pass the authentication.
The group is stored in LDAP directory (it may be for example an entry of
type I<groupOfUniqueNames> with the group participants listed in attribute
I<uniqueMember>).

When requesting indirect bind, the internal user search may return multiple
DNs. By default this is treated as an error (because of ambiguity) and results
with authentication failuer. This may be changed by setting a parameter named
I<ambiguous>, in which case the module will try to consecutively bind to each
DN from the search result.

The indirect bind may be configured to use custom search filter, instead of
the default one. This allows to incorporate additional restrictions on users
based on their attributes stored in LDAP.

=head2 Usage

The username is the first component of the path, the password needs to be
passed in the extended parameters using the key password.

Example:

   $connector->get('username', {  password => 'mySecret' } );

To configure module for direct bind, the connector object should be created
with parameter I<indirect> => 0. This is the simplest authentication method
and requires least parameters to be configured.

Example:

    my $connector = Connector::Builtin::Authentication::LDAP->new({
        LOCATION => 'ldap://ldap.example.org',
        indirect => 0
    })
    my $result = $connector->get(
        'uid=jsmith,ou=people,dc=example,dc=org',
        { password => 'secret' }
    );


Indirect bind, which is default, searches through the LDAP directory. This
usually requires read access to database, and is performed by a separate user.
We'll call that user I<binddn>. For indirect-bind authentication, one usually
has to provide DN and password of the existing I<binddn> user.

Example:

    my $connector = Connector::Builtin::Authentication::LDAP->new({
        LOCATION => 'ldap://ldap.example.org',
        binddn => 'cn=admin,dc=example,dc=org',
        password => 'binddnPassword'
    })
    my $result = $connector->get('jsmith', { password => 'secret' });

Two parameters are used to check group participation: I<groupdn> and
I<groupattr>. The I<groupdn> parameter specifies DN of a group entry and the
I<groupattr> specifies an attribute of the I<groupdn> object where group
participants are listed. If you specify I<groupdn>, the group participation
check is enabled.


Example:

    # Assume, we have in LDAP:
    #
    # dn: cn=vip,dc=example,dc=org
    # objectClass: groupOfNames
    # member: uid=jsmith,ou=people,dc=example,dc=org
    #
    my $connector = Connector::Builtin::Authentication::LDAP->new({
        LOCATION => 'ldap://ldap.example.org',
        indirect => 0,
        binddn => 'cn=admin,dc=example,dc=org',
        password => 'binddnPassword',
        groupdn => 'cn=vip,dc=example,dc=org',
    })
    my $result = $connector->get(
        'uid=jsmith,ou=people,dc=example,dc=org',
        { password => 'secret' }
    );

Note, that in this case we have provided I<binddn> despite the direct-bind
authentication was used. This is, because we needed read access to the
C<cn=vip,dc=example,dc=org> entry (the group object).

The indirect-bind method accepts custom filters for user search.

Example:

    my $connector = Connector::Builtin::Authentication::LDAP->new({
        LOCATION => 'ldap://ldap.example.org',
        binddn => 'cn=admin,dc=example,dc=org',
        password => 'binddnPassword',
        filter => '(&(uid=[% LOGIN %])(accountStatus=active))'
    })
    my $result = $connector->get('jsmith', { password => 'secret' });

You may substitute user name by using I<[% LOGIN %]> template parameter,
as shown in the above example.

=head2 Configuration

Below is the full list of configuration options.

=head3 Connection options

=over 8

=item B<keepalive> => 1

If given, set the socket's SO_KEEPALIVE option depending on the Boolean value
of the option. (Default: use system default).

=item B<timeout> => N

Timeout passed to IO::Socket when connecting the remote server. (Default: 120)

=item B<multihomed> => N

Will be passed to IO::Socket as the MultiHomed parameter when connecting to the
remote server

=item B<localaddr> => HOST

Will be passed to IO::Socket as the LocalAddr parameter, which sets the
client's IP address (as opposed to the server's IP address.)

=item B<debug> => N

Set the LDAP debug level.

=back

=head3 SSL Connection options

=over 8

=item B<verify> => 'none' | 'optional' | 'require'

How to verify the server's certificate:

    none
        The server may provide a certificate but it will not be checked - this
        may mean you are be connected to the wrong server
    optional
        Verify only when the server offers a certificate
    require
        The server must provide a certificate, and it must be valid.

If you set B<verify> to optional or I<require>, you must also set either
B<cafile> or B<capath>. The most secure option is require.

=item B<sslversion>  => 'sslv2' | 'sslv3' | 'sslv23' | 'tlsv1'

This defines the version of the SSL/TLS protocol to use. Defaults to 'tlsv1'.

=item B<ciphers> => CIPHERS

Specify which subset of cipher suites are permissible for this connection,
using the standard OpenSSL string format. The default behavior is to keep the
decision on the underlying cryptographic library.

=item B<capath> => '/path/to/servercerts/'

See B<cafile>.

=item B<cafile> => '/path/to/servercert.pem'

When verifying the server's certificate, either set B<capath> to the pathname
of the directory containing CA certificates, or set B<cafile> to the filename
containing the certificate of the CA who signed the server's certificate. These
certificates must all be in PEM format.


=item B<clientcert> => '/path/to/cert.pem'

See B<clientkey>.

=item B<clientkey> => '/path/to/key.pem'

If you want to use the client to offer a certificate to the server for SSL
authentication (which is not the same as for the LDAP Bind operation) then set
B<clientcert> to the user's certificate file, and B<clientkey> to the user's
private key file. These files must be in PEM format.

=item B<checkcrl> => 1

=back

=head3 BindDN

=over 8

=item B<binddn> => DN

Distinguished Name of the LDAP entry used to search LDAP database for users
being authenticated (indirect bind) and check their group participation.

=item B<password> => PASSWORD

Password for the B<binddn> user.

=back

=head3 Search options (indirect bind)

=over 8

=item B<timelimit> => N

A timelimit that restricts the maximum time (in seconds) allowed for a search.
A value of 0 (the default), means that no timelimit will be requested.

=item B<sizelimit> => N

A sizelimit that restricts the maximum number of entries to be returned as a
result of the search. A value of 0, and the default, means that no restriction
is requested. Servers may enforce a maximum number of entries to return.

=item B<base> => DN

The DN that is the base object entry relative to which the search is to be
performed.

=item B<filter> => TEMPLATESTRING

A filter that defines the conditions an entry in the directory must meet in
order for it to be returned by the search. This may be a (template) string or a
Net::LDAP::Filter object.

=item B<scope>  => 'base' | 'one' | 'sub' | 'subtree' | 'children'

By default the search is performed on the whole tree below the specified base
object. This maybe changed by specifying a scope parameter with one of the
following values:

    base
        Search only the base object.
    one
        Search the entries immediately below the base object.
    sub
    subtree
        Search the whole tree below (and including) the base object. This is
        the default.
    children
        Search the whole subtree below the base object, excluding the base object itself.

Note: children scope requires LDAPv3 subordinate feature extension.

=back

=head3 Other options

=over 8

=item B<userattr> => ATTRNAME

If the search B<filter> (for indirect bind) is not specified, it is constructed
internally as I<"($userattr=[% LOGIN %])">, where I<$userattr> represents the
value of B<userattr> parameter.

=item B<groupattr> => ATTRNAME

If B<groupdn> is specified by caller, the B<groupattr> defines an attribute
within B<groupdn> object which shall be compared against the DN of the user
being authenticated in order to check its participation to the group. Defaults
to I<'member'>.

=item B<groupdn> => DN

DN of an LDAP entry which defines a group of users allowed to be authenticated.
If not defined, the group participation is not checked.

=item B<indirect> => 1 | 0

Use indirect bind (default). Set to I<0> to disable indirect bind and use
direct bind.

=item B<ambiguous> => 0 | 1

Accept ambiguous search results when doing indirect-bind authentication. By
default, this option is disabled.

=back

=head2 Return values

1 if the password matches, 0 if the user is found but the password does not
match and undef if the user is not found (or it's found but group check
failed).

=head2 Limitations

User names are limited to so called I<valueencoding> syntax defined by RFC4515.
We allow non-ascii (utf-8) characters and non-printable characters. Invalid
names are treated as not found.

=cut

# vim: set expandtab tabstop=4 shiftwidth=4:
