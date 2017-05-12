package Catalyst::Authentication::Store::RDBO;
use strict;
use warnings;
use 5.008_001;
use base qw/Class::Accessor::Fast/;

our $VERSION = "0.1000";

BEGIN {
        __PACKAGE__->mk_accessors(qw/config/);
}

sub new
{
        my ($class, $config, $app) = @_;

        ## figure out if we are overriding the default store user class
        $config->{'store_user_class'} = exists($config->{'store_user_class'})
          ? $config->{'store_user_class'}
          : "Catalyst::Authentication::Store::RDBO::User";

        ## make sure the store class is loaded.
        Catalyst::Utils::ensure_class_loaded($config->{'store_user_class'});

        ## fields can be specified to be ignored during user location.  This allows
        ## the store to ignore certain fields in the authinfo hash.

        $config->{'ignore_fields_in_find'} ||= [];

        my $self = { config => $config };

        bless $self, $class;

}

sub from_session
{
        my ($self, $c, $frozenuser) = @_;

        my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
        return $user->from_session($frozenuser, $c);
}

sub for_session
{
        my ($self, $c, $user) = @_;

        return $user->for_session($c);
}

sub find_user
{
        my ($self, $authinfo, $c) = @_;

        my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);

        return $user->load($authinfo, $c);
}

sub user_supports
{
        my $self = shift;

        # this can work as a class method on the user class
        $self->config->{'store_user_class'}->supports(@_);
}

sub auto_create_user
{
        my ($self, $authinfo, $c) = @_;
        my $res = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
        return $res->auto_create($authinfo, $c);
}

sub auto_update_user
{
        my ($self, $authinfo, $c, $res) = @_;
        $res->auto_update($authinfo, $c);
        return $res;
}

1;  # End of Catalyst::Authentication::Store::RDBO

__END__

=head1 NAME

Catalyst::Authentication::Store::RDBO - A storage class for Catalyst Authentication using RDBO

=head1 VERSION

This documentation refers to version 0.1000

=head1 SYNOPSIS

    use Catalyst qw/
                    Authentication
                    Authorization::Roles/;

    __PACKAGE__->config->{authentication} =
                    {
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    class => 'Password',
                                    password_field => 'password',
                                    password_type => 'clear'
                                },
                                store => {
                                    class => 'RDBO',
                                        user_class => 'MyApp::User',
                                        role_relation => 'roles',
                                        role_field => 'rolename',
                                    }
                            }
                            }
                    };

    # Log a user in:

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate({
                          screen_name => $c->req->params->username,
                          password => $c->req->params->password,
                          status => [ 'registered', 'loggedin', 'active']
                          }))
    }

    # verify a role

    if ( $c->check_user_roles( 'editor' ) ) {
        # do editor stuff
    }


=head1 DESCRIPTION

The Catalyst::Authentication::Store::RDBO class provides
access to authentication information stored in a database via a
L<Rose::DB::Object> class.

=head1 CONFIGURATION

The RDBO authentication store is activated by setting the store
config's B<class> element to RDBO as shown above. See the
L<Catalyst::Plugin::Authentication> documentation for more details on
configuring the store.

The RDBO storage module has several configuration options


    __PACKAGE__->config->{authentication} =
                    {
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    # ...
                                },
                                store => {
                                    class => 'RDBO',
                                        user_class => 'MyApp::User',
                                        role_relation => 'roles',
                                        role_field => 'rolename',
                                    ignore_fields_in_find => [ 'remote_name' ],
                                    }
                            }
                            }
                    };

=over 4

=item class

Class is part of the core Catalyst::Plugin::Authentication module; it
contains the class name of the store to be used.

=item user_class

Class name of a L<Rose::DB::Object> subclass to use as the source for user
information.  This config item is B<REQUIRED>.

=item role_column

If your role information is stored in the same table as the rest of your user
information, this item tells the module which field contains your role
information.  The RDBO authentication store expects the data in this
field to be a series of role names separated by some combination of spaces,
commas, or pipe characters.

=item role_relation

If your role information is stored in a separate table, this is the name of
the relation that will lead to the roles the user is in.  If this is
specified, then a role_field is also required.  Also when using this method
it is expected that your role table will return one row for each role
the user is in.

=item role_field

This is the name of the field in the role table that contains the string
identifying the role.

=item ignore_fields_in_find

This item is an array containing fields that may be passed to the
$c->authenticate() routine (and therefore find_user in the storage class), but
which should be ignored when creating the RDBO search to retrieve a
user. This makes it possible to avoid problems when a credential requires an
authinfo element whose name overlaps with a column name in your users table.
If this doesn't make sense to you, you probably don't need it.

=item store_user_class

This allows you to override the authentication user class that the
RDBO store module uses to perform its work.  Most of the
work done in this module is actually done by the user class,
L<Catalyst::Authentication::Store::RDBO::User>, so
overriding this doesn't make much sense unless you are using your
own class to extend the functionality of the existing class.
Chances are you do not want to set this.

=item id_field

In most cases, this config variable does not need to be set, as
Catalyst::Authentication::Store::RDBO will determine the primary key of the
user table on its own via Rose::DB::Object::Metadata.  If you need to override
the default, or your user table has multiple primary keys, then id_field
should contain the column name that should be used to restore the user.
A given value in this column should correspond to a single user in the database.
Note that this is used B<ONLY> when restoring a user from the session and
has no bearing whatsoever in the initial authentication process.

=back

=head1 USAGE

The L<Catalyst::Authentication::Store::RDBO> storage module
is not called directly from application code.  You interface with it
through the $c->authenticate() call.

There are two methods you can use to retrieve information from the RDBO
storage module.  They are Simple retrieval, and the advanced retrieval method
Searchargs

=head2 Simple Retrieval

The first, and most common, method is simple retrieval. As its name implies
simple retrieval allows you to simply to provide the column => value pairs
that should be used to locate the user in question. An example of this usage
is below:

    if ($c->authenticate({
                          screen_name => $c->req->params->{'username'},
                          password => $c->req->params->{'password'},
                          status => [ 'registered', 'active', 'loggedin']
                         })) {

        # ... authenticated user code here
    }

The above example would attempt to retrieve a user whose username column (here,
screen_name) matched the username provided, and whose status column matched one of the
values provided. These name => value pairs are used more or less directly in
the Rose::DB::Object::Manager 'get_objects()' routine, so in most cases, you
can use Rose syntax to retrieve the user according to whatever rules you
have.

NOTE: Because the password in most cases is encrypted - it is not used
directly but its encryption and comparison with the value provided is usually
handled by the Password Credential. Part of the Password Credential's behavior
is to remove the password argument from the authinfo that is passed to the
storage module. See L<Catalyst::Authentication::Credential::Password>.

One thing you need to know about this retrieval method is that the name
portion of the pair is checked against the user class's column list. Pairs are
only used if a matching column is found. Other pairs will be ignored. This
means that you can only provide simple name-value pairs, and that some more
advanced Rose::DB::Object::QueryBuilder constructs, such as 'or', 'and', etc. are in most cases
not possible using this method. For queries that require this level of
functionality, see the 'searchargs' method below.

=head2 Advanced Retrieval

The Searchargs retrieval method is used when more advanced features of the
underlying L<Rose::DB::Object> are required. These methods provide a direct
interface with the RDBO schema and therefore require a better understanding of
the Rose::DB::Object module.

=head3 The rdbo key

Since the format of these arguments are often complex, they are not keys in
the base authinfo hash.  Instead, both of these arguments are placed within
a hash attached to the store-specific 'rdbo' key in the base $authinfo
hash.  When the RDBO authentication store sees the 'rdbo' key
in the passed authinfo hash, all the other information in the authinfo hash
is ignored and only the values within the 'rdbo' hash are used as
though they were passed directly within the authinfo hash.  In other words, if
'rdbo' is present, it replaces the authinfo hash for processing purposes.

The 'rdbo' hash can be used to directly pass arguments to the
RDBO authentication store. Reasons to do this are to avoid credential
modification of the authinfo hash, or to avoid overlap between credential and
store key names. It's a good idea to avoid using it in this way unless you are
sure you have an overlap/modification issue.

=over 4

=item Searchargs

The B<searchargs> method of retrieval allows you to specify an arrayref
containing the search arguments to be passed as the 'query' parameter of the
get_objects() method from L<Rose::DB::Object::Manager>.  If provided, all other
args are ignored, and the search args provided are used directly to locate the
user.  An example will probably make more sense:

    if ($c->authenticate(
        {
            password => $password,
            'rdbo' =>
                {
                    searchargs => [
                            or => [
                                username => $username,
                                email => $email,
                                clientid => $clientid
                        ]
                    ]
                }
        } ) )
    {
        # do successful authentication actions here.
    }

The above would allow authentication based on any of the three items -
username, email, or clientid.

NOTE: Both of these methods of user retrieval consider the first row returned
to be the matching user. In most cases there will be only one matching row, but
it is easy to produce multiple rows, especially when using the advanced
retrieval methods. Remember, what you get when you use this module is equivalent to:

    shift @{ MyApp::User::Manager->get_objects(...) }

NOTE ALSO:  The user info used to save the user to the session and to retrieve
it is the same regardless of what method of retrieval was used.  In short,
the value in the id field (see 'id_field' config item) is used to retrieve the
user from the database upon restoring from the session.  When the RDBO storage
module does this, it does so by doing a simple search using the id field.  In other
words, it will not use the same arguments you used to request the user initially.
This is especially important to those using the advanced methods of user retrieval.
If you need more complicated logic when reviving the user from the session, you will
most likely want to subclass the L<Catalyst::Authentication::Store::RDBO::User> class
and provide your own for_session and from_session routines.

=back


=head1 METHODS

There are no publicly exported routines in the RDBO authentication
store (or indeed in most authentication stores). However, below is a
description of the routines required by L<Catalyst::Plugin::Authentication>
for all authentication stores.  Please see the documentation for
L<Catalyst::Plugin::Authentication::Internals> for more information.


=head2 new ( $config, $app )

Constructs a new store object.

=head2 find_user ( $authinfo, $c )

Finds a user using the information provided in the $authinfo hashref and
returns the user, or undef on failure. This is usually called from the
Credential. This translates directly to a call to
L<Catalyst::Authentication::Store::RDBO::User>'s load() method.

=head2 for_session ( $c, $user )

Prepares a user to be stored in the session. Currently returns the value of
the user's id field (as indicated by the 'id_field' config element)

=head2 from_session ( $c, $frozenuser)

Revives a user from the session based on the info provided in $frozenuser.
Currently treats $frozenuser as an id and retrieves a user with a matching id.

=head2 user_supports

Provides information about what the user object supports.

=head2 auto_update_user( $authinfo, $c, $res )

This method is called if the realm's auto_update_user setting is true. It
will delegate to the user object's C<auto_update> method.

=head2 auto_create_user( $authinfo, $c )

This method is called if the realm's auto_create_user setting is true. It
will delegate to the user class's (resultset) C<auto_create> method.

=head1 NOTES

As of the current release, session storage consists of simply storing the user's
id in the session, and then using that same id to re-retrieve the user's information
from the database upon restoration from the session.  More dynamic storage of
user information in the session is intended for a future release.

=head1 BUGS AND LIMITATIONS

None known currently; please email the author if you find any.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<Catalyst::Plugin::Authentication::Internals>,
L<Catalyst::Plugin::Authorization::Roles>, L<Catalyst::Plugin::Authentication::Store::DBIx::Class>

=head1 AUTHOR

Dave O'Neill (dmo@dmo.ca)

Based heavily on L<Catalyst::Authentication::Store::DBIx::Class> by Jason Kuri (jayk@cpan.org)

=head1 LICENSE

Copyright (c) 2008 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
