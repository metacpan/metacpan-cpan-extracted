package Catalyst::Authentication::Store::DBIx::Class;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

our $VERSION= "0.1506";


BEGIN {
    __PACKAGE__->mk_accessors(qw/config/);
}


sub new {
    my ( $class, $config, $app ) = @_;

    ## figure out if we are overriding the default store user class
    $config->{'store_user_class'} = (exists($config->{'store_user_class'})) ? $config->{'store_user_class'} :
                                        "Catalyst::Authentication::Store::DBIx::Class::User";

    ## make sure the store class is loaded.
    Catalyst::Utils::ensure_class_loaded( $config->{'store_user_class'} );

    ## fields can be specified to be ignored during user location.  This allows
    ## the store to ignore certain fields in the authinfo hash.

    $config->{'ignore_fields_in_find'} ||= [ ];

    my $self = {
                    config => $config
               };

    bless $self, $class;

}

## --jk note to self:
## let's use DBIC's get_columns method to return a hash and save / restore that
## from the session.  Then we can respond to get() calls, etc. in most cases without
## resorting to a DB call.  If user_object is called, THEN we can hit the DB and
## return a real object.
sub from_session {
    my ( $self, $c, $frozenuser ) = @_;

#    return $frozenuser if ref $frozenuser;

    my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
    return $user->from_session($frozenuser, $c);
}

sub for_session {
    my ($self, $c, $user) = @_;

    return $user->for_session($c);
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $user = $self->config->{'store_user_class'}->new($self->{'config'}, $c);

    return $user->load($authinfo, $c);

}

sub user_supports {
    my $self = shift;
    # this can work as a class method on the user class
    $self->config->{'store_user_class'}->supports( @_ );
}

sub auto_create_user {
    my( $self, $authinfo, $c ) = @_;
    my $res = $self->config->{'store_user_class'}->new($self->{'config'}, $c);
    return $res->auto_create( $authinfo, $c );
}

sub auto_update_user {
    my( $self, $authinfo, $c, $res ) = @_;
    $res->auto_update( $authinfo, $c );
    return $res;
}

__PACKAGE__;

__END__

=head1 NAME

Catalyst::Authentication::Store::DBIx::Class - A storage class for Catalyst Authentication using DBIx::Class

=head1 VERSION

This documentation refers to version 0.1506.

=head1 SYNOPSIS

    use Catalyst qw/
                    Authentication
                    Authorization::Roles/;

    __PACKAGE__->config('Plugin::Authentication' => {
        default_realm => 'members',
        realms => {
            members => {
                credential => {
                    class => 'Password',
                    password_field => 'password',
                    password_type => 'clear'
                },
                store => {
                    class => 'DBIx::Class',
                    user_model => 'MyApp::User',
                    role_relation => 'roles',
                    role_field => 'rolename',
                }
            }
        }
    });

    # Log a user in:

    sub login : Global {
        my ( $self, $ctx ) = @_;

        $ctx->authenticate({
                          screen_name => $ctx->req->params->{username},
                          password => $ctx->req->params->{password},
                          status => [ 'registered', 'loggedin', 'active']
                          }))
    }

    # verify a role

    if ( $ctx->check_user_roles( 'editor' ) ) {
        # do editor stuff
    }

=head1 DESCRIPTION

The Catalyst::Authentication::Store::DBIx::Class class provides
access to authentication information stored in a database via DBIx::Class.

=head1 CONFIGURATION

The DBIx::Class authentication store is activated by setting the store
config's B<class> element to DBIx::Class as shown above. See the
L<Catalyst::Plugin::Authentication> documentation for more details on
configuring the store. You can also use
L<Catalyst::Authentication::Realm::SimpleDB> for a simplified setup.

The DBIx::Class storage module has several configuration options


    __PACKAGE__->config('Plugin::Authentication' => {
        default_realm => 'members',
        realms => {
            members => {
                credential => {
                    # ...
                },
                store => {
                    class => 'DBIx::Class',
                    user_model => 'MyApp::User',
                    role_relation => 'roles',
                    role_field => 'rolename',
                    ignore_fields_in_find => [ 'remote_name' ],
                    use_userdata_from_session => 1,
                }
            }
        }
    });

=over 4

=item class

Class is part of the core Catalyst::Plugin::Authentication module; it
contains the class name of the store to be used.

=item user_model

Contains the model name (as passed to C<< $ctx->model() >>) of the DBIx::Class schema
to use as the source for user information. This config item is B<REQUIRED>.

(Note that this option used to be called C<< user_class >>. C<< user_class >> is
still functional, but should be used only for compatibility with previous configs.
The setting called C<< user_class >> on other authentication stores is
present, but named C<< store_user_class >> in this store)

=item role_column

If your role information is stored in the same table as the rest of your user
information, this item tells the module which field contains your role
information.  The DBIx::Class authentication store expects the data in this
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
C<< $ctx->authenticate() >> routine (and therefore find_user in the storage class), but
which should be ignored when creating the DBIx::Class search to retrieve a
user. This makes it possible to avoid problems when a credential requires an
authinfo element whose name overlaps with a column name in your users table.
If this doesn't make sense to you, you probably don't need it.

=item use_userdata_from_session

Under normal circumstances, on each request the user's data is re-retrieved
from the database using the primary key for the user table.  When this flag
is set in the configuration, it causes the DBIx::Class store to avoid this
database hit on session restore.  Instead, the user object's column data
is retrieved from the session and used as-is.

B<NOTE>: Since the user object's column
data is only stored in the session during the initial authentication of
the user, turning this on can potentially lead to a situation where the data
in C<< $ctx->user >> is different from what is stored the database.  You can force
a reload of the data from the database at any time by calling C<< $ctx->user->get_object(1); >>
Note that this will update C<< $ctx->user >> for the remainder of this request.
It will NOT update the session.  If you need to update the session
you should call C<< $ctx->update_user_in_session() >> as well.

=item store_user_class

This allows you to override the authentication user class that the
DBIx::Class store module uses to perform its work.  Most of the
work done in this module is actually done by the user class,
L<Catalyst::Authentication::Store::DBIx::Class::User>, so
overriding this doesn't make much sense unless you are using your
own class to extend the functionality of the existing class.
Chances are you do not want to set this.

=item id_field

In most cases, this config variable does not need to be set, as
Catalyst::Authentication::Store::DBIx::Class will determine the primary
key of the user table on its own.  If you need to override the default,
or your user table has multiple primary keys, then id_field
should contain the column name that should be used to restore the user.
A given value in this column should correspond to a single user in the database.
Note that this is used B<ONLY> when restoring a user from the session and
has no bearing whatsoever in the initial authentication process.  Note also
that if use_userdata_from_session is enabled, this config parameter
is not used at all.

=back

=head1 USAGE

The L<Catalyst::Authentication::Store::DBIx::Class> storage module
is not called directly from application code.  You interface with it
through the $ctx->authenticate() call.

There are three methods you can use to retrieve information from the DBIx::Class
storage module.  They are Simple retrieval, and the advanced retrieval methods
Searchargs and Resultset.

=head2 Simple Retrieval

The first, and most common, method is simple retrieval. As its name implies
simple retrieval allows you to simply to provide the column => value pairs
that should be used to locate the user in question. An example of this usage
is below:

    if ($ctx->authenticate({
                          screen_name => $ctx->req->params->{'username'},
                          password => $ctx->req->params->{'password'},
                          status => [ 'registered', 'active', 'loggedin']
                         })) {

        # ... authenticated user code here
    }

The above example would attempt to retrieve a user whose username column (here,
screen_name) matched the username provided, and whose status column matched one of the
values provided. These name => value pairs are used more or less directly in
the DBIx::Class search() routine, so in most cases, you can use DBIx::Class
syntax to retrieve the user according to whatever rules you have.

NOTE: Because the password in most cases is encrypted - it is not used
directly but its encryption and comparison with the value provided is usually
handled by the Password Credential. Part of the Password Credential's behavior
is to remove the password argument from the authinfo that is passed to the
storage module. See L<Catalyst::Authentication::Credential::Password>.

One thing you need to know about this retrieval method is that the name
portion of the pair is checked against the user class's column list. Pairs are
only used if a matching column is found. Other pairs will be ignored. This
means that you can only provide simple name-value pairs, and that some more
advanced DBIx::Class constructs, such as '-or', '-and', etc. are in most cases
not possible using this method. For queries that require this level of
functionality, see the 'searchargs' method below.

=head2 Advanced Retrieval

The Searchargs and Resultset retrieval methods are used when more advanced
features of the underlying L<DBIx::Class> schema are required. These methods
provide a direct interface with the DBIx::Class schema and therefore
require a better understanding of the DBIx::Class module.

=head3 The dbix_class key

Since the format of these arguments are often complex, they are not keys in
the base authinfo hash.  Instead, both of these arguments are placed within
a hash attached to the store-specific 'dbix_class' key in the base $authinfo
hash.  When the DBIx::Class authentication store sees the 'dbix_class' key
in the passed authinfo hash, all the other information in the authinfo hash
is ignored and only the values within the 'dbix_class' hash are used as
though they were passed directly within the authinfo hash.  In other words, if
'dbix_class' is present, it replaces the authinfo hash for processing purposes.

The 'dbix_class' hash can be used to directly pass arguments to the
DBIx::Class authentication store. Reasons to do this are to avoid credential
modification of the authinfo hash, or to avoid overlap between credential and
store key names. It's a good idea to avoid using it in this way unless you are
sure you have an overlap/modification issue. However, the two advanced
retrieval methods, B<searchargs>, B<result> and B<resultset>, require its use,
as they are only processed as part of the 'dbix_class' hash.

=over 4

=item Searchargs

The B<searchargs> method of retrieval allows you to specify an arrayref containing
the two arguments to the search() method from L<DBIx::Class::ResultSet>.  If provided,
all other args are ignored, and the search args provided are used directly to locate
the user.  An example will probably make more sense:

    if ($ctx->authenticate(
        {
            password => $password,
            'dbix_class' =>
                {
                    searchargs => [ { -or => [ username => $username,
                                              email => $email,
                                              clientid => $clientid ]
                                   },
                                   { prefetch => qw/ preferences / }
                                 ]
                }
        } ) )
    {
        # do successful authentication actions here.
    }

The above would allow authentication based on any of the three items -
username, email, or clientid - and would prefetch the data related to that user
from the preferences table. The searchargs array is passed directly to the
search() method associated with the user_model.

=item Result

The B<result> method of retrieval allows you to look up the user yourself and
pass on the loaded user to the authentication store.

    my $user = $ctx->model('MyApp::User')->find({ ... });

    if ($ctx->authenticate({ dbix_class => { result => $user } })) {
        ...
    }

Be aware that the result method will not verify that you are passing a result
that is attached to the same user_model as specified in the config or even
loaded from the database, as opposed to existing only in memory. It's your
responsibility to make sure of that.

=item Resultset

The B<resultset> method of retrieval allows you to directly specify a
resultset to be used for user retrieval. This allows you to create a resultset
within your login action and use it for retrieving the user. A simple example:

    my $rs = $ctx->model('MyApp::User')->search({ email => $ctx->request->params->{'email'} });
       ... # further $rs adjustments

    if ($ctx->authenticate({
                           password => $password,
                           'dbix_class' => { resultset => $rs }
                         })) {
       # do successful authentication actions here.
    }

Be aware that the resultset method will not verify that you are passing a
resultset that is attached to the same user_model as specified in the config.

NOTE: The resultset and searchargs methods of user retrieval, consider the first
row returned to be the matching user. In most cases there will be only one
matching row, but it is easy to produce multiple rows, especially when using the
advanced retrieval methods. Remember, what you get when you use this module is
what you would get when calling search(...)->first;

NOTE ALSO:  The user info used to save the user to the session and to retrieve
it is the same regardless of what method of retrieval was used.  In short,
the value in the id field (see 'id_field' config item) is used to retrieve the
user from the database upon restoring from the session.  When the DBIx::Class storage
module does this, it does so by doing a simple search using the id field.  In other
words, it will not use the same arguments you used to request the user initially.
This is especially important to those using the advanced methods of user retrieval.
If you need more complicated logic when reviving the user from the session, you will
most likely want to subclass the L<Catalyst::Authentication::Store::DBIx::Class::User> class
and provide your own for_session and from_session routines.

=back


=head1 METHODS

There are no publicly exported routines in the DBIx::Class authentication
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
L<Catalyst::Authentication::Store::DBIx::Class::User>'s load() method.

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
and L<Catalyst::Plugin::Authorization::Roles>

=head1 AUTHOR

Jason Kuri (jayk@cpan.org)

=head1 LICENSE

Copyright (c) 2007 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
