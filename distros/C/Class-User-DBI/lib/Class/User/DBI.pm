## no critic (RCS,VERSION)
package Class::User::DBI;

use 5.008;

use strict;
use warnings;

use Carp;

use Socket qw( inet_ntoa inet_aton );

use List::MoreUtils qw( any );

use Authen::Passphrase::SaltedSHA512;

use Class::User::DBI::DB qw( %USER_QUERY db_run_ex );
use Class::User::DBI::Roles;

use Class::User::DBI::RolePrivileges;
use Class::User::DBI::UserDomains;

our $VERSION = '0.10';
# $VERSION = eval $VERSION;    ## no critic (eval)

sub new {
    my ( $class, $db_conn, $userid ) = @_;
    croak 'Constructor called without a DBIx::Connector object.'
      if !ref $db_conn || !$db_conn->isa('DBIx::Connector');
    croak 'User ID must be defined, and at least one character in length.'
      if !defined $userid || !length $userid;
    my $self = bless {}, $class;
    $self->{_db_conn}    = $db_conn;
    $self->{userid}      = $userid;
    $self->{validated}   = 0;          # Start out with a non-validated user.
    $self->{exists_user} = 0;          # Start with an unproven existence.
    return $self;
}

# Accessors.

sub _db_conn {
    my $self = shift;
    return $self->{_db_conn};
}

# Prepares and executes a database command using DBIx::Connector's 'run'
# method.  Pass bind values as 2nd+ parameter(s).  If the first bind-value
# element is an array ref, bind value params will be executed in a loop,
# dereferencing each element's list upon execution:
# $self->_db_run( 'SQL GOES HERE', @execute_params ); .... OR....
# $self->_db_run(
#     'SQL GOES HERE',
#     [ first param list ], [ second param list ], ...
# );

sub _db_run {
    my ( $self, $sql, @ex_params ) = @_;
    my $conn = $self->_db_conn;

    # We import db_run_ex() from Class::User::DBI::DB.
    return db_run_ex( $conn, $sql, @ex_params );
}

sub userid {
    my $self = shift;
    return $self->{userid};
}

# $userinfo = { username=>...,   email=>..., ip_req=>...,
#               ips_aref=>[...], role=>...,  password=>... };
sub add_user {
    my ( $self, $userinfo ) = @_;
    my $password = $userinfo->{password};
    croak 'Cannot create a user without a password.'
      if !defined $password || !length $password;
    return if $self->exists_user;    # Don't add a user already in the DB.

    # Default to IP not required.
    my $ip_req   = defined $userinfo->{ip_req}   ? $userinfo->{ip_req}   : 0;
    my $username = defined $userinfo->{username} ? $userinfo->{username} : q{};
    my $email    = defined $userinfo->{email}    ? $userinfo->{email}    : q{};
    my $role     = defined $userinfo->{role}     ? $userinfo->{role}     : q{};
    my $ips_aref =
      exists $userinfo->{ips_aref} ? $userinfo->{ips_aref} : $userinfo->{ips};

    croak 'If an IP is required "ips_aref" attribute must also be provided.'
      if $ip_req && !ref $ips_aref eq 'ARRAY';
    my $r = Class::User::DBI::Roles->new( $self->_db_conn );
    croak 'Can\'t add a user with a role that isn\'t previously defined.'
      if length $role && !$r->exists_role($role);

    my $passgen =
      Authen::Passphrase::SaltedSHA512->new( passphrase => $password );
    my ( $salt_hex, $hash_hex ) = ( $passgen->salt_hex, $passgen->hash_hex );
    local $@;
    my $success = eval {
      $self->_db_conn->txn(
          fixup => sub {
              die "User already exists." if $self->exists_user;
              my $sth = $_->prepare( $USER_QUERY{SQL_add_user} );
              $sth->execute( $self->userid, $salt_hex, $hash_hex, $ip_req,
                  $username, $email, $role );
              $self->add_ips( @{$ips_aref} ) if ref($ips_aref) eq 'ARRAY';
              if ( exists $userinfo->{domains}
                  && ref $userinfo->{domains} eq 'ARRAY' )
              {
                  $self->user_domains->add_domains( @{ $userinfo->{domains} } );
              }
          }
      );
      1; # Eval guard.
    }; # Eval.
    if( ! $success ) {
      return;  # User already existed, perhaps.
    }
    else {
      return $self->{exists_user} = $self->userid; # Success.
    }
}

sub delete_user {
    my $self = shift;
    return if !$self->exists_user;    # undef if user wasn't in the DB.

    $self->_db_conn->txn(
        fixup => sub {

            # Fetch the ud object before we delete user from users database.
            # Otherwise, the ud constructor will fail a validity check.
            my $ud  = $self->user_domains;
            my $sth = $_->prepare( $USER_QUERY{SQL_delete_user} );
            $sth->execute( $self->userid );
            my $sth2 = $_->prepare( $USER_QUERY{SQL_delete_user_ips} );
            $sth2->execute( $self->userid );
            if ( my @domains = $ud->fetch_domains ) {
                $ud->delete_domains(@domains);    # Transactions are great!
            }
        }
    );

    # Invalidate the caches.
    $self->validated(0);
    $self->{exists_user} = 0;
    return 1;
}

# Quick check whether a userid exists inf the database.
# Return 0 if user doesn't exist.  Caches result.
sub exists_user {
    my $self = shift;
    return 1 if $self->{exists_user};
    my $sth = $self->_db_run( $USER_QUERY{SQL_exists_user}, $self->userid );
    return defined $sth->fetchrow_array ? 1 : 0;
}

# Fetch user's salt_hex, pass_hex, ip_required, and valid ip's from database.
sub get_credentials {
    my $self = shift;
    my $sth = $self->_db_run( $USER_QUERY{SQL_get_credentials}, $self->userid );
    my ( $salt_hex, $pass_hex, $ip_required ) = $sth->fetchrow_array;
    return if not defined $salt_hex;    # User wasn't found.
    my @valid_ips = $self->get_valid_ips;
    return {
        userid      => $self->userid,
        salt_hex    => $salt_hex,
        pass_hex    => $pass_hex,
        ip_required => $ip_required,
        valid_ips   => [@valid_ips],
    };
}

# Validate returns 0 or 1.
# 0 for any of the following conditions:
#     Invalid userid (doesn't exist in the database).
#     Password doesn't match.
#     IP required but no IP parameter passed.
#     IP required but IP doesn't match whitelist.
sub validate {
    my ( $self, $password, $ip, $force_revalidate ) = @_;
    croak 'Cannot validate without a passphrase.'
      if !defined $password || !length $password;
    return 0 if !$self->exists_user;

    # Save ourselves work if user is already authenticated.
    if ( !$force_revalidate && $self->validated ) {
        return 1;
    }
    my $credentials = $self->get_credentials;
    my $auth        = Authen::Passphrase::SaltedSHA512->new(
        salt_hex => $credentials->{salt_hex},
        hash_hex => $credentials->{pass_hex}
    );

    if ( !$auth->match($password) ) {
        $self->validated(0);
        return 0;
    }

    # Return 0 if an IP is required, and IP param is not in whitelist,
    # or no IP parameter passed.
    if ( $credentials->{ip_required} ) {
        if (   !defined $ip
            || !any { $ip eq $_ } @{ $credentials->{valid_ips} } )
        {
            $self->validated(0);
            return 0;
        }
    }

    # We passed! Authenticate.
    $self->{validated} = 1;    # Set in object that we're authenticated.
    return 1;
}

# Check validated status.  Also allow for invalidation by passing a false
# parameter to the method.
sub validated {
    my ( $self, $new_value ) = @_;
    if ( defined $new_value && !$new_value ) {
        $self->{validated} = 0;
    }
    return $self->{validated};
}

# May be useful later on if we add user information.
sub load_profile {
    my $self = shift;
    my $sth  = $self->_db_run( $USER_QUERY{SQL_load_profile}, $self->userid );
    my $hr   = $sth->fetchrow_hashref;
    if ( $self->get_role ) {
        my $rp = $self->role_privileges;
        $hr->{privileges} = [ $rp->fetch_privileges ];
    }
    my $ud = $self->user_domains;
    $hr->{domains} = [ $ud->fetch_domains ];
    return $hr;
}

sub add_ips {
    my ( $self, @ips ) = @_;
    return if !$self->exists_user;

    # We don't want to insert IP's already in the DB.
    my @ips_in_db = $self->get_valid_ips;
    my %uniques;
    @uniques{@ips_in_db} = ();
    my @ips_to_insert = grep { !exists $uniques{$_} } @ips;
    return 0 if !@ips_to_insert;

    # Prepare the userid,ip bundles for our insert query.
    my @execution_param_bundles =
      map { [ $self->userid, unpack( 'N', inet_aton($_) ) ] } @ips_to_insert;
    my $sth =
      $self->_db_run( $USER_QUERY{SQL_add_ips}, @execution_param_bundles );

    return scalar @ips_to_insert;    # Return a count of IP's inserted.
}

sub delete_ips {
    my ( $self, @ips ) = @_;
    return if !$self->exists_user;
    my @ips_in_db = $self->get_valid_ips;
    my %found;
    @found{@ips_in_db} = ();
    my @ips_for_deletion = grep { exists $found{$_} } @ips;
    my @execution_param_bundles =
      map { [ $self->userid, unpack( 'N', inet_aton($_) ) ] } @ips_for_deletion;
    my $sth =
      $self->_db_run( $USER_QUERY{SQL_delete_ips}, @execution_param_bundles );
    return scalar @ips_for_deletion;    # Return a count of IP's deleted.
}

# Fetches all IP's that are whitelisted for the user.
sub get_valid_ips {
    my $self = shift;
    my $sth = $self->_db_run( $USER_QUERY{SQL_get_valid_ips}, $self->userid );
    my @rv;
    while ( defined( my $row = $sth->fetchrow_arrayref ) ) {
        if ( defined $row->[0] ) {
            push @rv, inet_ntoa( pack 'N', $row->[0] );
        }
    }
    return @rv;
}

sub update_password {
    my ( $self, $newpass, $oldpass ) = @_;

    return if !$self->exists_user;

    # If an old passphrase is supplied, only update if it validates.
    if ( defined $oldpass ) {
        my $credentials = $self->get_credentials;
        my $auth        = Authen::Passphrase::SaltedSHA512->new(
            salt_hex => $credentials->{salt_hex},
            hash_hex => $credentials->{pass_hex}
        );

        # Return undef if password doesn't authenticate for the user.
        return unless $auth->match($oldpass);    ## no critic (postfix)
    }

    my $passgen =
      Authen::Passphrase::SaltedSHA512->new( passphrase => $newpass );
    my $salt_hex = $passgen->salt_hex;
    my $hash_hex = $passgen->hash_hex;
    $self->_db_conn->txn(
        fixup => sub {
            my $sth = $_->prepare( $USER_QUERY{SQL_update_password} );
            $sth->execute( $salt_hex, $hash_hex, $self->userid );
        }
    );
    return $self->userid;
}

sub set_email {
    my ( $self, $new_email ) = @_;
    croak 'Can\'t set a user email for a user ID that doesn\'t exist.'
      if !$self->exists_user;
    my $sth =
      $self->_db_run( $USER_QUERY{SQL_set_email}, $new_email, $self->userid );
    return $new_email;
}

sub set_username {
    my ( $self, $new_username ) = @_;
    croak 'Can\'t set a user name for a user ID that doesn\'t exist.'
      if !$self->exists_user;
    my $sth = $self->_db_run( $USER_QUERY{SQL_set_username},
        $new_username, $self->userid );
    return 1;
}

sub set_ip_required {
    my ( $self, $required ) = @_;
    croak 'Can\'t set an IP requirement for a user ID that doesn\'t exist.'
      if ! $self->exists_user;
    $required = defined $required ? $required : 0;
    $required = $required ? 1 : 0;
    my $sth = $self->_db_run( $USER_QUERY{SQL_set_ip_required},
        $required, $self->userid );
    return 1;
}

sub get_ip_required {
    my $self = shift;
    return if ! $self->exists_user;
    my $sth = $self->_db_run( $USER_QUERY{SQL_get_ip_required}, $self->userid );
    my $required = ( $sth->fetchrow_array )[0];
    return $required;
}
  
sub get_role {
    my $self = shift;
    return if !$self->exists_user;
    my $sth = $self->_db_run( $USER_QUERY{SQL_get_role}, $self->userid );
    my $role = ( $sth->fetchrow_array )[0];
    return $role;
}

sub set_role {
    my ( $self, $role ) = @_;
    croak 'Can\'t set a role for a user ID that doesn\'t exist.'
      if !$self->exists_user;
    my $r = Class::User::DBI::Roles->new( $self->_db_conn );
    croak 'Can\'t set to an undefined role.'
      if !$r->exists_role($role);
    my $sth = $self->_db_run( $USER_QUERY{SQL_set_role}, $role, $self->userid );
    return 1;
}

sub is_role {
    my ( $self, $role ) = @_;
    return if !$self->exists_user;
    my $sth = $self->_db_run( $USER_QUERY{SQL_is_role}, $self->userid, $role );
    return 1 if $sth->fetchrow_array;
    return 0;
}

sub role_privileges {
    my $self = shift;
    return $self->{role_privileges_obj}
      if exists $self->{role_privileges_obj};
    $self->{role_privileges_obj} =
      Class::User::DBI::RolePrivileges->new( $self->_db_conn, $self->get_role );
    croak 'Couldn\'t instantiate a Class::User::DBI::RolePrivileges object.'
      if ref( $self->{role_privileges_obj} ) ne
          'Class::User::DBI::RolePrivileges';
    return $self->{role_privileges_obj};
}

sub user_domains {
    my $self = shift;
    return $self->{user_domains_obj}
      if exists $self->{user_domains_obj};
    $self->{user_domains_obj} =
      Class::User::DBI::UserDomains->new( $self->_db_conn, $self->userid );
    croak 'Couldn\'t instantiate a Class::User::DBI::UserDomains object.'
      if ref( $self->{user_domains_obj} ) ne 'Class::User::DBI::UserDomains';
    return $self->{user_domains_obj};
}

# Class methods

sub list_users {
    my ( $class, $conn ) = @_;
    my $self = $class->new( $conn, 'dummy_class_user' );
    my $sth = $self->_db_run( $USER_QUERY{SQL_list_users} );
    return @{ $sth->fetchall_arrayref };
}

sub configure_db {
    my ( $class, $conn ) = @_;
    my @SQL_keys = qw(
      SQL_configure_db_users
      SQL_configure_db_user_ips
    );
    foreach my $sql_key (@SQL_keys) {
        $conn->run(
            fixup => sub {
                $_->do( $USER_QUERY{$sql_key} );
            }
        );
    }
    return 1;
}

1;

__END__

=head1 NAME

Class::User::DBI - A User class: Login credentials, roles, privileges, domains.

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

This module models a "User" class, with login credentials, and Roles Based
Access Control.  Additionally, IP whitelists may be used as an additional
validation measure. Domain (locality) based access control is also provided
independently of role based access control.

A brief description of authentication:  Passphrases are stored as randomly
salted SHA2-512 hashes.  Optional whitelisting of IP's is also available.

A brief description of this RBAC implementation:  Users have roles and domains
(localities).  Roles carry privileges.  Roles with privileges, and domains
act independently, allowing for sophisticated access control.


    # Set up a connection using DBIx::Connector:
    # MySQL database settings:

    my $conn = DBIx::Connector->new(
        'dbi:mysql:database=cudbi_tests, 'testing_user', 'testers_pass',
        {
            RaiseError => 1,
            AutoCommit => 1,
        }
    );


    # Now we can play with Class::User::DBI:

    Class::User::DBI->configure_db( $conn );  # Set up the tables for a user DB.

    my @user_list = Class::User::DBI->list_users;

    my $user = new( $conn, $userid );

    my $user_id  = $user->add_user(
        {
            password => $password,
            ip_req   => $bool_ip_req,
            ips      => [ '192.168.0.100', '201.202.100.5' ], # aref ip's.
            username => $full_name,
            email    => $email,
            role     => $role,
        }
    );

    my $userid      = $user->userid;
    my $validated   = $user->validated;
    my $invalidated = $user->validated(0);           # Cancel authentication.
    my $is_valid    = $user->validate( $pass, $ip ); # Validate including IP.
    my $is_valid    = $user->validate( $pass );      # Validate without IP.
    my $info_href   = $user->load_profile;
    my $credentials = $user->get_credentials;        # Returns a useful hashref.
    my @valid_ips   = $user->get_valid_ips;
    my $ip_required = $user->get_ip_required;
    my $success     = $user->set_ip_required(1);
    my $ exists     = $user->exists_user;
    my $success     = $user->delete_user;
    my $del_count   = $user->delete_ips( @ips );
    my $add_count   = $user->add_ips( @ips );
    my $success     = $user->set_email( 'new@email.address' );
    my $success     = $user->set_username( 'Cool New User Name' );
    my $success     = $user->update_password( 'Old Pass', 'New Pass' );
    my $success     = $user->update_password( 'New Pass' );
    my $success     = $user->set_role( $role );
    my $has         = $user->is_role( $role );
    my $role        = $user->get_role;
    
    # Accessors for the RolePrivileges and UserDomains classes.
    my $rp          = $user->role_privileges;
    my $has_priv    = $user->role_privileges->has_privilege( 'some_privilg' );
    my $ud          = $user->user_domains;
    my $has_domain  = $user->user_domains->has_domain( 'some_domain' );


=head1 DESCRIPTION

The module is designed to simplify user logins, authentication, role based
access control (authorization), as well as domain (locality) constraint access
control.

It stores user credentials, roles, and basic user information in a database via
a DBIx::Connector database connection.

User passphrases are salted with a 512 bit random salt (unique per user) using
a cryptographically strong random number generator, and converted to a SHA2-512
digest before being stored in the database.  All subsequent passphrase
validation checks test against the salt and passphrase SHA2 hash.

IP whitelists may be maintained per user.  If a user is set to require an IP
check, then the user validates only if his passphrase authenticates AND his
IP is found in the whitelist associated with his user id.

Users may be given a role, which is conceptually similar to a Unix 'group'.
Roles are simple strings.  Furthermore, multiple privileges (also simple strings)
are granted to roles.

Users may be given multiple domains, which might be used to model localities or
jurisdictions.  Domains act independently from roles and privileges, but are a
convenient way of constraining a role and its privileges to a specific set of
localities.


=head1 EXPORT

Nothing is exported.  There are many object methods, and three class methods,
described in the next section.

=head1 SETTING UP AN AUTHENTICATION AND ROLES BASED ACCESS CONTROL MODEL

First, use L<Class::User::DBI::Roles> to set up a list of roles and their
corresponding descriptions.

Next, use L<Class::User::DBI::Privileges> to set up a list of privileges and
their corresponding descriptions.

Use L<Class::User::DBI::RolePrivileges> to associate one or more privileges with
each role.

Use L<Class::User::DBI::Domains> to create a list of domains (localities), along
with their descriptions.

Use L<Class::User::DBI> (This module) to create a set of users, establish
login credentials such as passphrases and optional IP whitelists, and assign
them roles.

Use L<Class::User::DBI::UserDomains> to associate one or more localities
(domains) with each user.

=head1 USING AN AUTHENTICATION AND ROLES BASED ACCESS CONTROL MODEL

Use L<Class::User::DBI> (This module) to instantiate a user, and validate him
by passphrase and optional whitelist.

Use the instantiated user object to get the user's 'RolePrivileges' object.
Use the instantiated user object to get the user's 'UserDomains' object.

Use the L<Class::User::DBI::RolePrivileges> object obtained via a call to
C<< $user->get_role_privilege_object >> to verify that a user has a given access
privilege.

Use the L<Class::User::DBI::UserDomains> object obtained via a call to
C<< $user->user_domains >> to verify that a user has a given
domain/jurisdiction/locality.

=head1 SUBROUTINES/METHODS

All methods will be listed alphabetically, class methods first, object methods
thereafter.

=head2 CLASS METHODS

=head2  new
(The constructor -- Class method.)

    my $user_obj = Class::User::DBI->new( $connector, $userid );

Instantiates a new Class::User::DBI object in behalf of a target user on a
database handled by the DBIx::Connector.

The user object may be accessed and manipulated through the methods listed
below.

=head2  list_users
(Class method)

    my @users = Class::User::DBI->list_users( $connector );
    foreach my $listed_user ( @users ) {
        my( $userid, $username, $email ) = @{$listed_user};
        print "userid: ($userid).  username: ($username).  email: ($email).\n";
    }

This is a class method.  Pass a valid DBIx::Connector as a parameter. Returns
a list of arrayrefs.  Each anonymous array contains C<userid>, C<username>,
C<email>, C<role>, and C<ip_required>.


=head2  configure_db
(Class method)

    Class::User::DBI->configure_db( $connector );

This is a class method.  Pass a valid DBIx::Connector as a parameter.  Builds
a minimal set of database tables in support of the Class::User::DBI.

The tables created will be C<users>, C<user_ips>, and C<user_roles>.

=head2 USER OBJECT METHODS


=head2  add_ips

    my $quantity_added = $user->add_ips ( @whitelisted_ips );

Pass a list of IP's to add to the IP whitelist for this user.  Any IP's that
are already in the database will be silently skipped.

Returns a count of how many were added.


=head2  add_user

    my $success = $self->add_user( {
        username    => $user_full_name,     # Optional field. Default q{}.

        password    => $user_passphrase,    # Clear text password.
                                            # Required field. No length limit.

        email       => $user_email,         # Optional field.  Default q{}.

        ip_req      => $ip_validation_reqd  # Boolean value determining whether
                                            # this user requires IP whitelist
                                            # validation. ( 0 = no, 1 = yes ).
                                            # Optional field.  Default 0.

        ips_aref    => [                    # Optional field.  Default is empty
            '127.0.0.1',                    # list.  If 'ip_req' is set and no
            '192.168.0.1',                  # list is provided here, then valid
        ],                                  # IP's will need to be added later
                                            # before user can validate.
        role        => $role,               # A string representing user's role.
    } );

This method creates a new user in the database with the C<userid> supplied when
the user object was instantiated.  The password field is the only required
field.  It must contain a clear-text passphrase.  There is no length limitation.

Other fields are optional, but convenient.  If IP whitelisting is needed
for this user, the C<ip_req> field must be supplied, and must be set to C<1>
(true).

If C<ip_req> is set to C<1> (true), a list of valid IP's may also be provided
in an arrayref keyed off of C<ips_aref>.  As a convenience, the C<ips> key is
synonymous with C<ips_aref>.  The IP's provided will then be added to the
C<user_ips> database table.  If an IP is required but none are added via
C<add_user>, they will have to be added manually with C<add_ips> before the
user can be validated.

The user's passphrase will be salted with a cryptographically sound random
salt of 512 bits (128 hex digits).  It will then be digested using a SHA2-512
hash, and both the salt and the digest will be stored in the C<users> database.

This is a reliable and secure means of storing a passphrase.  In fact, the
passphrase is not stored at all.  Just a salt and the digest.  Even if the
salt and hash were to be discovered by an attacker, they would not be useful
in side-stepping user validation, as they cannot be used to decrypt the
passphrase.  SHA512 is the strongest of the SHA2 family.  A salt length of
512 bits guarantees a maximum entropy for any given passphrase.

Though it is beyond the scope of this module to enforce, users should be
encouraged to use passphrases that are both resistant to dictionary attacks, and
dissimilar to passphrases used in other applications.  No minimum passphrase
size is enforced by this module.  But a strong passphrase should be of ample
length, and should contain characters beyond the standard alphabet.

Users may also be assigned a role that will be used in RBAC.

=head2  delete_ips

    my $quantity_deleted = $user->delete_ips( @ips_to_remove );

Pass a list of IP's to remove from the IP whitelist for this user.  Any IP's
that weren't found in the database will be silently skipped.

Returns a count of how many IP's were dropped.


=head2  delete_user

    $user->delete_user;

Removes the user from the database, along with the user's IP whitelist, and
any associated domains.  Also sets the C<< $user->validated >>, and
C<< $user->exists_user >> flags to false.


=head2  exists_user

Checks the database to verify that the user exists.  As this method is used
internally frequently its B<positive> result is cached to minimize database
queries.  Methods that would invalidate the existence of the user in the
database, such as C<< $user->delete_user >> will remove the cache entry, and
subsequent tests will access the database on each call to C<exists_user()>,
until such time that the result flips to positive again.


=head2  get_credentials

    my $credentials_href = $user->get_credentials;
    my @fields = qw( userid salt_hex pass_hex ip_required );
    foreach my $field ( @fields ) {
        print "$field => $credentials_href->{$field}\n";
    }
    my @valid_ips = @{$valid_ips};
    foreach my $ip ( @valid_ips ) {
        print "Whitelisted IP: $ip\n";
    }

Accepts no parameters.  Returns a hashref holding a small datastructure that
describes the user's credentials.  The structure looks like this:

    $href = {
        userid      => $userid,     # The target user's userid.

        salt_hex    => $salt,       # A 128 hex-character representation of
                                    # the user's random salt.

        pass_hex    => $pass,       # A 128 hex-character representation of
                                    # the user's SHA2-512 digested passphrase.

        ip_required => $ip_req,     # A Boolean value indicating whether this
                                    # user requires IP whitelist validation.

        valid_ips   => [            # Whitelisted IP's for user. (optional)
            '127.0.0.1',            # Some example whitelisted IP's.
            '129.168.0.10',
        ],
    };

A typical usage probably won't require calling this function directly very
often, if at all.  In most cases where it would be useful to look at the salt,
the passphrase digest, and IP whitelists, the
C<< $user->validate( $passphrase, $ip ) >> method is easier to use and less
prone to error.  But for those cases I haven't considered, the
C<get_credentials()> method exists.


=head2 get_role

    my $user_role = $user->get_role;

Returns the user's assigned role.  If no role is assigned, returns an empty
string.

=head2 role_privileges

Returns a Class::User::DBI::RolePrivileges object associated with this user's
role.  See L<Class::User::DBI::RolePrivileges> to read how to manipulate the
object.

=head2 user_domains

Returns a Class::User::DBI::UserDomains object associated with this user.  See
L<Class::User::DBI::UserDomains> to read how to manipulate the object.

=head2  get_valid_ips

    my @valid_ips = $user->get_valid_ips;

Returns a list containing the whitelisted IP's for this user.  Each
IP will be a string in the form of C<192.168.0.198>.  If the user doesn't use
IP validation, or there are no IP's stored for this user, the list will be
empty.

=head2 is_role

    my $is = $user->is_role( 'worker' );
    
Returns true if this user's role matches the parameter.

=head2  load_profile

    my $user_info_href = $user->load_profile;
    foreach my $field ( qw/ userid username email role / ) {
        print "$field   => $user_info_href->{$field}\n";
    }

Returns a reference to an anonymous hash containing the user's basic
profile and RBAC information.  The datastructure looks like this:

    my $user_info_href = {
        userid      => $userid,     # The primary user ID.
        username    => $username,   # The full user name as stored in the DB.
        email       => $email,      # The email stored in the DB for this user.
        role        => $role,       # The user's assigned role (may be blank).
        privileges  => [ @privs ],  # A reference to an array of user's privs.
        domains     => [ @doms  ],  # A reference to an array of user's domains.
        ip_required => $required,   # 0 or 1.
    };

The privileges, and domains array refs will always contain a reference to an
anonymous array, but that array may be empty if the user has no assigned domains
or privileges.

=head2 get_ip_required

    my $required = $user->get_ip_required;

Returns 0 if this user doesn't require IP verification.  1 if user requires IP
verification.  undef if the user doesn't exist in the database.

=head2 set_ip_required

    my $success = $user->set_ip_required( $new_setting );

Pass 1 to set this user for IP validation. Pass 0 to turn off IP validation for
this user.  Returns 1 on success.  Croaks if user isn't in the database.

=head2  set_email

    my $success = $user->set_email( $new_email_address );

Email addresses are not verified for validity in any way.  However, the default
database field used for storing email addresses provides 320 bytes of storage,
which is the maximum length possible for a valid email address.


=head2 set_role

    my $success = $user->set_role( $new_role );

Set's (or changes) the user's role.  There is a validity check: The role must
have been already defined via L<Class::User::DBI::Roles>.

=head2  set_username

    my $success = $user->set_username( $new_user_full_name );

There's probably not much need for explaining this method.  The default database
table's C<username> field accepts user names up to fourty characters.


=head2  update_password

    # Update with validation of old password first.
    my $success = $user->update_password( $new_pass, $old_pass );

    # Update without validation of old password first.
    my $success = $user->update_password( $new_pass );

Using the same algorithms of C< add_user( { password => $passphrase } ); >>,
creates a new password for the user.  If the old passphrase is supplied as
a second parameter, the update will only take place if the old passphrase
validates.

The "with validation" method is useful for allowing a user to update her own
password.  The "without validation" version is useful for allowing an
administrator (or automated process) to reset a user's forgotten password.


=head2  userid

    my $userid = $user->userid;

A simple accessor returning the C<userid> that is the target of the
C<Class::User::DBI> object.


=head2  validate

    # If no IP whitelist verification is required:
    my $is_valid  = $user->validate( $passphrase );

    # If IP whitelist verification is required:
    my $is_valid = $user->validate( $passphrase, $current_ip );

    my $forced_revalidate
        = $user->validate( $passphrase, $current_ip, 1 ); # 3rd arg true.

Returns Boolean C<true> if and only if the user can be validated.  What that
means will be described in the paragraphs below.  If the user cannot be
validated, the return value will be Boolean C<false>.  It doesn't matter what
the reason for failure to authenticate might have been: Invalid user ID, invalid
password, or invalid IP address; all three reasons result in a return value of
Boolean C<false>.

This design decision encourages the best practice of not divulging to the user
why his authentication failed.  The less information provided, the less an
attacker can user to narrow the field.  If it is necessary to explicitly test
whether a userid actually exists, or whether the user's IP matches the whitelist,
separate accessors are provided to facilitate that requirement. 

If you wish to force a revalidation (assume a dirty cache) you have two options:

    $user->validated(0);    # Invalidate the cache.
    print "Ok.\n" if $user->validate( $pass, $ip );

Or you can do that as a single operation:

    print "Ok.\n" if $user->validate( $pass, $ip, 1 );


=head3 What Validation (or Authentication) Means To This Module

If the user has been configured for no IP testing, validation means that the
C<userid> exists (case insensitively) within the database, and that the
passphrase passed to C<validate()>, when salted with the stored salt and
digested using a SHA2-512 hashing algorithm results in the same 512 bit hash
as the one generated when the passphrase was originally set up.

If the user has been configured to require IP testing, validation I<also> means
that the IP supplied to the C<validate()> method matches one of the IP's stored
in the database for this user.  IP's are stored in the clear, which shouldn't
matter.  User input should never be used for the IP field of C<validate()>.
It is assumed that within the application, the user's IP will be detected, and
that IP will be passed for cross-checking with the whitelist database.

The C<validate()> method caches its B<positive> result.  Any action that might
change the authentication status will remove the cached status.  Actions that
will result in C<validate()> to perform all tests again include
C<delete_user()>, C<update_password()>, or C<validated(0)> (passing the
C<validated()> method a '0'.


=head2  validated

    # Test.
    my $has_been_validated = $user->validated;

    # Invalidate.
    $user->validated(0);

Returns true if the user has been validated, as described above.  Does not
perform a full validation; simply tests whether the previous call to
C<validate()> succeeded, and that nothing has happened to remove that "is valid"
status.

Pass a parameter of 'C<0>' to force all future calls to C<validated()> to return
false.  Also, after resetting C<validated()> to false, future calls to
C<validate()> will go through the full authentication process again until such
time as the authentication is successful.

=head1 EXAMPLE

Please refer to the contents of the C<examples/> directory from this
distribution's build directory.  There you will find a working example that
creates some roles, some privileges, assigns the privileges to a role, 
creates some domains, creates a user, and associates a role and several domains
to that user.  Though the example doesn't exercise every method contained in 
the distribution, it provides a nice concise demonstration of setting up the
basic elements of Authentication and RBAC, and using them.

=head1 DEPENDENCIES

This module requires DBIx::Connector, Authen::Passphrase::SaltedSHA512, and
List::MoreUtils. It also requires a database connection.  The test suite will
use DBD::SQLite, but it has also been tested with DBD::mysql.  None of these
dependencies with the exception of List::MoreUtils could be considered
light-weight.  The dependency chain of this module is indicative of the
difficulty in assuring cryptographically strong random salt generation,
reliable SHA2-512 hashing of passphrases, fork-safe database connectivity, and
transactional commits for inserts and updates spanning multiple tables.


=head1 CONFIGURATION AND ENVIRONMENT

The database used will need seven tables to be set up.

For convenience, a class method has been provided with each of this
distribution's classes that will auto-generate the minimal schema within a
SQLite or MySQL database.  The SQLite database is probably only useful for
testing, as it lacks many of the security measures present in web-stack quality
databases.

Within the C<./scripts/> directory of this distribution you will find a script
that accepts a database type (mysql or sqlite), database name, database
username, and database password on the command line.  It then opens the given
database and creates the appropriate tables.  The script is named
C<cudbi-configdb>.  Run it once without any command line parameters to see
details on usage.

After creating the database framework, it might be useful to alter the tables
that have been generated by customizing field widths, text encoding, and so on.
It may be advisable to enable UTF8 for the C<userid>, C<email>, C<username>
fields, and  possibly even for the C<role> field.

There is no explicit size requirement for the C<userid>, C<username>, and
C<role> fields.  They could be made wider if it's deemed useful.  Don't be
tempted to reduce the size of the email address field: The best practice of
coding to the standard dictates that the field needs to be 320 characters wide.

The C<salt> and C<password> fields are used to store a 128 hex-digit
representation of the 512 bit salt and 512 bit SHA2 hash of the user's
passphrase.  More digits is not useful, and less won't store the full salt
and hash.


=head1 DIAGNOSTICS

If you find that your particular database engine is not playing nicely with the
test suite from this module, it may be necessary to provide the database login 
credentials for a test database using the same engine that your application 
will actually be using.  You may do this by setting C<$ENV{CUDBI_TEST_DSN}>,
C<$ENV{CUDBI_TEST_DATABASE}>, C<$ENV{CUDBI_TEST_USER}>, 
and C<$ENV{CUDBI_TEST_PASS}>.

Currently the test suite tests against a SQLite database since it's such a
lightweight dependency for the testing.  The author also uses this module
with several MySQL databases.  As you're configuring your database, providing
its credentials to the tests and running the test scripts will offer really 
good diagnostics if some aspect of your database tables proves to be at odds 
with what this module needs.

Be advised that the the test suite drops its tables after completion, so be sure
to run the test suite only against a database set up explicitly for testing
purposes.

=head1 INCOMPATIBILITIES

This module has only been tested on MySQL and SQLite database engines.  If you
are successful in using it with other engines, please send me an email detailing
any additional configuration changes you had to make so that I can document
the compatibility, and improve the documentation for the configuration process.

=head1 BUGS AND LIMITATIONS

This module is still in beta testing.  The API of any version number in the
form of 'xxx.yyy_zzz' could still change.  Once the version reaches the form
of 'xxx.yyy', the API may be considered stable.

=head1 AUTHOR


David Oswald, C<< <davido at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-user-dbi at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-User-DBI>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::User::DBI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-User-DBI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-User-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-User-DBI>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-User-DBI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Class::User::DBI
