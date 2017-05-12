package Catalyst::Plugin::Authentication;

use Moose;
use namespace::clean -except => 'meta';
use MRO::Compat;
use Tie::RefHash;
use Class::Inspector;
use Catalyst::Authentication::Realm;

with 'MooseX::Emulate::Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/_user/);

our $VERSION = "0.10023";

sub set_authenticated {
    my ( $c, $user, $realmname ) = @_;

    $c->user($user);
    $c->request->{user} = $user;    # compatibility kludge

    if (!$realmname) {
        $realmname = 'default';
    }
    my $realm = $c->get_auth_realm($realmname);

    if (!$realm) {
        Catalyst::Exception->throw(
                "set_authenticated called with nonexistant realm: '$realmname'.");
    }
    $user->auth_realm($realm->name);

    $c->persist_user();

    $c->maybe::next::method($user, $realmname);
}

sub user {
    my $c = shift;

    if (@_) {
        return $c->_user(@_);
    }

    if ( defined($c->_user) ) {
        return $c->_user;
    } else {
        return $c->auth_restore_user;
    }
}

# change this to allow specification of a realm - to verify the user is part of that realm
# in addition to verifying that they exist.
sub user_exists {
    my $c = shift;
    return defined($c->_user) || defined($c->find_realm_for_persisted_user);
}

# works like user_exists - except only returns true if user
# exists AND is in the realm requested.
sub user_in_realm {
    my ($c, $realmname) = @_;

    if (defined($c->_user)) {
        return ($c->_user->auth_realm eq $realmname);
    } else {
        my $realm = $c->find_realm_for_persisted_user;
        if ($realm) {
            return ($realm->name eq $realmname);
        } else {
            return undef;
        }
    }
}

sub __old_save_user_in_session {
    my ( $c, $user, $realmname ) = @_;

    $c->session->{__user_realm} = $realmname;

    # we want to ask the store for a user prepared for the session.
    # but older modules split this functionality between the user and the
    # store.  We try the store first.  If not, we use the old method.
    my $realm = $c->get_auth_realm($realmname);
    if ($realm->{'store'}->can('for_session')) {
        $c->session->{__user} = $realm->{'store'}->for_session($c, $user);
    } else {
        $c->session->{__user} = $user->for_session;
    }
}

sub persist_user {
    my $c = shift;

    if ($c->user_exists) {

        ## if we have a valid session handler - we store the
        ## realm in the session.  If not - we have to hope that
        ## the realm can recognize its frozen user somehow.
        if ($c->can('session') &&
            $c->config->{'Plugin::Authentication'}{'use_session'} &&
            $c->session_is_valid) {

            $c->session->{'__user_realm'} = $c->_user->auth_realm;
        }

        my $realm = $c->get_auth_realm($c->_user->auth_realm);

        # used to call $realm->save_user_in_session
        $realm->persist_user($c, $c->user);
    }
}


## this was a short lived method to update user information -
## you should use persist_user instead.
sub update_user_in_session {
    my $c = shift;

    return $c->persist_user;
}

sub logout {
    my $c = shift;

    $c->user(undef);

    my $realm = $c->find_realm_for_persisted_user;
    if ($realm) {
        $realm->remove_persisted_user($c);
    }

    $c->maybe::next::method(@_);
}

sub find_user {
    my ( $c, $userinfo, $realmname ) = @_;

    $realmname ||= 'default';
    my $realm = $c->get_auth_realm($realmname);

    if (!$realm) {
        Catalyst::Exception->throw(
                "find_user called with nonexistant realm: '$realmname'.");
    }
    return $realm->find_user($userinfo, $c);
}

## Consider making this a public method. - would make certain things easier when
## dealing with things pre-auth restore.
sub find_realm_for_persisted_user {
    my $c = shift;

    my $realm;
    if ($c->can('session')
        and $c->config->{'Plugin::Authentication'}{'use_session'}
        and $c->session_is_valid
        and exists($c->session->{'__user_realm'})) {

        $realm = $c->auth_realms->{$c->session->{'__user_realm'}};
        if ($realm->user_is_restorable($c)) {
            return $realm;
        }
    } else {
        ## we have no choice but to ask each realm whether it has a persisted user.
        foreach my $realmname (@{$c->_auth_realm_restore_order}) {
            my $realm = $c->auth_realms->{$realmname}
                || Catalyst::Exception->throw("Could not find authentication realm '$realmname'");
            return $realm
                if $realm->user_is_restorable($c);
        }
    }
    return undef;
}

sub auth_restore_user {
    my ( $c, $frozen_user, $realmname ) = @_;

    my $realm;
    if (defined($realmname)) {
        $realm = $c->get_auth_realm($realmname);
    } else {
        $realm = $c->find_realm_for_persisted_user;
    }
    return undef unless $realm; # FIXME die unless? This is an internal inconsistency

    $c->_user( my $user = $realm->restore_user( $c, $frozen_user ) );

    # this sets the realm the user originated in.
    $user->auth_realm($realm->name) if $user;

    return $user;

}

# we can't actually do our setup in setup because the model has not yet been loaded.
# So we have to trigger off of setup_finished.  :-(
sub setup {
    my $app = shift;

    $app->_authentication_initialize();
    $app->next::method(@_);
}

## the actual initialization routine. whee.
sub _authentication_initialize {
    my $app = shift;

    ## let's avoid recreating / configuring everything if we have already done it, eh?
    if ($app->can('_auth_realms')) { return };

    ## make classdata where it is used.
    $app->mk_classdata( '_auth_realms' => {});

    ## the order to attempt restore in - If we don't have session - we have
    ## no way to be sure where a frozen user came from - so we have to
    ## ask each realm if it can restore the user.  Unfortunately it is possible
    ## that multiple realms could restore the user from the data we have -
    ## So we have to determine at setup time what order to ask the realms in.
    ## The default is to use the user_restore_priority values defined in the realm
    ## config. if they are not defined - we go by alphabetical order.   Note that
    ## the 'default' realm always gets first chance at it unless it is explicitly
    ## placed elsewhere by user_restore_priority.  Remember this only comes
    ## into play if session is disabled.

    $app->mk_classdata( '_auth_realm_restore_order' => []);

    my $cfg = $app->config->{'Plugin::Authentication'};
    my $realmshash;
    if (!defined($cfg)) {
        if (exists($app->config->{'authentication'})) {
            $cfg = $app->config->{'authentication'};
            $app->config->{'Plugin::Authentication'} = $app->config->{'authentication'};
        } else {
            $cfg = {};
        }
    } else {
        # the realmshash contains the various configured realms.  By default this is
        # the main $app->config->{'Plugin::Authentication'} hash - but if that is
        # not defined, or there is a subkey {'realms'} then we use that.
        $realmshash = $cfg;
    }

    ## If we have a sub-key of {'realms'} then we use that for realm configuration
    if (exists($cfg->{'realms'})) {
        $realmshash = $cfg->{'realms'};
    }

    # old default was to force use_session on.  This must remain for that
    # reason - but if use_session is already in the config, we respect its setting.
    if (!exists($cfg->{'use_session'})) {
        $cfg->{'use_session'} = 1;
    }

    ## if we have a realms hash
    if (ref($realmshash) eq 'HASH') {

        my %auth_restore_order;
        my $authcount = 2;
        my $defaultrealm = 'default';

        foreach my $realm (sort keys %{$realmshash}) {
            if (ref($realmshash->{$realm}) eq 'HASH' &&
                (exists($realmshash->{$realm}{credential}) || exists($realmshash->{$realm}{class}))) {

                $app->setup_auth_realm($realm, $realmshash->{$realm});

                if (exists($realmshash->{$realm}{'user_restore_priority'})) {
                    $auth_restore_order{$realm} = $realmshash->{$realm}{'user_restore_priority'};
                } else {
                    $auth_restore_order{$realm} = $authcount++;
                }
            }
        }

        # if we have a 'default_realm' in the config hash and we don't already
        # have a realm called 'default', we point default at the realm specified
        if (exists($cfg->{'default_realm'}) && !$app->get_auth_realm('default')) {
            if ($app->_set_default_auth_realm($cfg->{'default_realm'})) {
                $defaultrealm = $cfg->{'default_realm'};
                $auth_restore_order{'default'} = $auth_restore_order{$cfg->{'default_realm'}};
                delete($auth_restore_order{$cfg->{'default_realm'}});
            }
        }

        ## if the default realm did not have a defined priority in its config - we put it at the front.
        if (!exists($realmshash->{$defaultrealm}{'user_restore_priority'})) {
            $auth_restore_order{'default'} = 1;
        }

        @{$app->_auth_realm_restore_order} = sort { $auth_restore_order{$a} <=> $auth_restore_order{$b} } keys %auth_restore_order;

    } else {

        ## BACKWARDS COMPATIBILITY - if realms is not defined - then we are probably dealing
        ## with an old-school config.  The only caveat here is that we must add a classname

        ## also - we have to treat {store} as {stores}{default} - because
        ## while it is not a clear as a valid config in the docs, it
        ## is functional with the old api. Whee!
        if (exists($cfg->{'store'}) && !exists($cfg->{'stores'}{'default'})) {
            $cfg->{'stores'}{'default'} = $cfg->{'store'};
        }

        push @{$app->_auth_realm_restore_order}, 'default';
        foreach my $storename (keys %{$cfg->{'stores'}}) {
            my $realmcfg = {
                store => { class => $cfg->{'stores'}{$storename} },
            };
            $app->setup_auth_realm($storename, $realmcfg);
        }
    }

}

# set up realmname.
sub setup_auth_realm {
    my ($app, $realmname, $config) = @_;

    my $realmclass = $config->{class};

    if( !$realmclass ) {
        $realmclass = 'Catalyst::Authentication::Realm';
    } elsif ($realmclass !~ /^\+(.*)$/ ) {
        $realmclass = "Catalyst::Authentication::Realm::${realmclass}";
    } else {
        $realmclass = $1;
    }

    Catalyst::Utils::ensure_class_loaded( $realmclass );

    my $realm = $realmclass->new($realmname, $config, $app);
    if ($realm) {
        $app->auth_realms->{$realmname} = $realm;
    } else {
        $app->log->debug("realm initialization for '$realmname' failed.");
    }
    return $realm;
}

sub auth_realms {
    my $self = shift;
    $self->_authentication_initialize(); # Ensure _auth_realms created!
    return($self->_auth_realms);
}

sub get_auth_realm {
    my ($app, $realmname) = @_;
    return $app->auth_realms->{$realmname};
}


# Very internal method.  Vital Valuable Urgent, Do not touch on pain of death.
# Using this method just assigns the default realm to be the value associated
# with the realmname provided.  It WILL overwrite any real realm called 'default'
# so can be very confusing if used improperly.  It's used properly already.
# Translation: don't use it.
sub _set_default_auth_realm {
    my ($app, $realmname) = @_;

    if (exists($app->auth_realms->{$realmname})) {
        $app->auth_realms->{'default'} = $app->auth_realms->{$realmname};
    }
    return $app->get_auth_realm('default');
}

sub authenticate {
    my ($app, $userinfo, $realmname) = @_;

    if (!$realmname) {
        $realmname = 'default';
    }

    my $realm = $app->get_auth_realm($realmname);

    ## note to self - make authenticate throw an exception if realm is invalid.

    if ($realm) {
        return $realm->authenticate($app, $userinfo);
    } else {
        Catalyst::Exception->throw(
                "authenticate called with nonexistant realm: '$realmname'.");

    }
    return undef;
}

## BACKWARDS COMPATIBILITY  -- Warning:  Here be monsters!
#
# What follows are backwards compatibility routines - for use with Stores and Credentials
# that have not been updated to work with C::P::Authentication v0.10.
# These are here so as to not break people's existing installations, but will go away
# in a future version.
#
# The old style of configuration only supports a single store, as each store module
# sets itself as the default store upon being loaded.  This is the only supported
# 'compatibility' mode.
#

sub get_user {
    my ( $c, $uid, @rest ) = @_;

    return $c->find_user( {'id' => $uid, 'rest'=>\@rest }, 'default' );
}


## this should only be called when using old-style authentication plugins.  IF this gets
## called in a new-style config - it will OVERWRITE the store of your default realm.  Don't do it.
## also - this is a partial setup - because no credential is instantiated... in other words it ONLY
## works with old-style auth plugins and C::P::Authentication in compatibility mode.  Trying to combine
## this with a realm-type config will probably crash your app.
sub default_auth_store {
    my $self = shift;

    my $realm = $self->get_auth_realm('default');
    if (!$realm) {
        $realm = $self->setup_auth_realm('default', { class => 'Compatibility' });
    }
    if ( my $new = shift ) {
        $realm->store($new);

        my $storeclass;
        if (ref($new)) {
            $storeclass = ref($new);
        } else {
            $storeclass = $new;
        }

        # BACKWARDS COMPATIBILITY - if the store class does not define find_user, we define it in terms
        # of get_user and add it to the class.  this is because the auth routines use find_user,
        # and rely on it being present. (this avoids per-call checks)
        if (!$storeclass->can('find_user')) {
            no strict 'refs';
            *{"${storeclass}::find_user"} = sub {
                                                    my ($self, $info) = @_;
                                                    my @rest = @{$info->{rest}} if exists($info->{rest});
                                                    $self->get_user($info->{id}, @rest);
                                                };
        }
    }

    return $self->get_auth_realm('default')->store;
}

## BACKWARDS COMPATIBILITY
## this only ever returns a hash containing 'default' - as that is the only
## supported mode of calling this.
sub auth_store_names {
    my $self = shift;

    my %hash = (  $self->get_auth_realm('default')->store => 'default' );
}

sub get_auth_store {
    my ( $self, $name ) = @_;

    if ($name ne 'default') {
        Carp::croak "get_auth_store called on non-default realm '$name'. Only default supported in compatibility mode";
    } else {
        $self->default_auth_store();
    }
}

sub get_auth_store_name {
    my ( $self, $store ) = @_;
    return 'default';
}

# sub auth_stores is only used internally - here for completeness
sub auth_stores {
    my $self = shift;

    my %hash = ( 'default' => $self->get_auth_realm('default')->store);
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication - Infrastructure plugin for the Catalyst authentication framework.

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
    /;

    # later on ...
    $c->authenticate({ username => 'myusername',
                       password => 'mypassword' });
    my $age = $c->user->get('age');
    $c->logout;

=head1 DESCRIPTION

The authentication plugin provides generic user support for Catalyst apps. It
is the basis for both authentication (checking the user is who they claim to
be), and authorization (allowing the user to do what the system authorises
them to do).

Using authentication is split into two parts. A Store is used to actually
store the user information, and can store any amount of data related to the
user. Credentials are used to verify users, using information from the store,
given data from the frontend. A Credential and a Store are paired to form a
'Realm'. A Catalyst application using the authentication framework must have
at least one realm, and may have several.

To implement authentication in a Catalyst application you need to add this
module, and specify at least one realm in the configuration.

Authentication data can also be stored in a session, if the application
is using the L<Catalyst::Plugin::Session> module.

B<NOTE> in version 0.10 of this module, the interface to this module changed.
Please see L</COMPATIBILITY ROUTINES> for more information.

=head1 INTRODUCTION

=head2 The Authentication/Authorization Process

Web applications typically need to identify a user - to tell the user apart
from other users. This is usually done in order to display private information
that is only that user's business, or to limit access to the application so
that only certain entities can access certain parts.

This process is split up into several steps. First you ask the user to identify
themselves. At this point you can't be sure that the user is really who they
claim to be.

Then the user tells you who they are, and backs this claim with some piece of
information that only the real user could give you. For example, a password is
a secret that is known to both the user and you. When the user tells you this
password you can assume they're in on the secret and can be trusted (ignore
identity theft for now). Checking the password, or any other proof is called
B<credential verification>.

By this time you know exactly who the user is - the user's identity is
B<authenticated>. This is where this module's job stops, and your application
or other plugins step in.

The next logical step is B<authorization>, the process of deciding what a user
is (or isn't) allowed to do. For example, say your users are split into two
main groups - regular users and administrators. You want to verify that the
currently logged in user is indeed an administrator before performing the
actions in an administrative part of your application. These decisions may be
made within your application code using just the information available after
authentication, or it may be facilitated by a number of plugins.

=head2 The Components In This Framework

=head3 Realms

Configuration of the Catalyst::Plugin::Authentication framework is done in
terms of realms. In simplest terms, a realm is a pairing of a Credential
verifier and a User storage (Store) backend. As of version 0.10003, realms are
now objects that you can create and customize.

An application can have any number of Realms, each of which operates
independent of the others. Each realm has a name, which is used to identify it
as the target of an authentication request. This name can be anything, such as
'users' or 'members'. One realm must be defined as the default_realm, which is
used when no realm name is specified. More information about configuring
realms is available in the configuration section.

=head3 Credential Verifiers

When user input is transferred to the L<Catalyst> application
(typically via form inputs) the application may pass this information
into the authentication system through the C<< $c->authenticate() >>
method.  From there, it is passed to the appropriate Credential
verifier.

These plugins check the data, and ensure that it really proves the user is who
they claim to be.

Credential verifiers compatible with versions of this module 0.10x and
upwards should be in the namespace
C<Catalyst::Authentication::Credential>.

=head3 Storage Backends

The authentication data also identifies a user, and the Storage backend modules
use this data to locate and return a standardized object-oriented
representation of a user.

When a user is retrieved from a store it is not necessarily authenticated.
Credential verifiers accept a set of authentication data and use this
information to retrieve the user from the store they are paired with.

Storage backends compatible with versions of this module 0.10x and
upwards should be in the namespace
C<Catalyst::Authentication::Store>.

=head3 The Core Plugin

This plugin on its own is the glue, providing realm configuration, session
integration, and other goodness for the other plugins.

=head3 Other Plugins

More layers of plugins can be stacked on top of the authentication code. For
example, L<Catalyst::Plugin::Session::PerUser> provides an abstraction of
browser sessions that is more persistent per user.
L<Catalyst::Plugin::Authorization::Roles> provides an accepted way to separate
and group users into categories, and then check which categories the current
user belongs to.

=head1 EXAMPLE

Let's say we were storing users in a simple Perl hash. Users are
verified by supplying a password which is matched within the hash.

This means that our application will begin like this:

    package MyApp;

    use Catalyst qw/
        Authentication
    /;

    __PACKAGE__->config( 'Plugin::Authentication' =>
                {
                    default => {
                        credential => {
                            class => 'Password',
                            password_field => 'password',
                            password_type => 'clear'
                        },
                        store => {
                            class => 'Minimal',
                            users => {
                                bob => {
                                    password => "s00p3r",
                                    editor => 'yes',
                                    roles => [qw/edit delete/],
                                },
                                william => {
                                    password => "s3cr3t",
                                    roles => [qw/comment/],
                                }
                            }
                        }
                    }
                }
    );

This tells the authentication plugin what realms are available, which
credential and store modules are used, and the configuration of each. With
this code loaded, we can now attempt to authenticate users.

To show an example of this, let's create an authentication controller:

    package MyApp::Controller::Auth;

    sub login : Local {
        my ( $self, $c ) = @_;

        if (    my $user     = $c->req->params->{user}
            and my $password = $c->req->params->{password} )
        {
            if ( $c->authenticate( { username => $user,
                                     password => $password } ) ) {
                $c->res->body( "hello " . $c->user->get("name") );
            } else {
                # login incorrect
            }
        }
        else {
            # invalid form input
        }
    }

This code should be self-explanatory. If all the necessary fields are supplied,
call the C<authenticate> method on the context object. If it succeeds the
user is logged in.

The credential verifier will attempt to retrieve the user whose
details match the authentication information provided to
C<< $c->authenticate() >>. Once it fetches the user the password is
checked and if it matches the user will be B<authenticated> and
C<< $c->user >> will contain the user object retrieved from the store.

In the above case, the default realm is checked, but we could just as easily
check an alternate realm. If this were an admin login, for example, we could
authenticate on the admin realm by simply changing the C<< $c->authenticate() >>
call:

    if ( $c->authenticate( { username => $user,
                             password => $password }, 'admin' ) ) {
        $c->res->body( "hello " . $c->user->get("name") );
    } ...


Now suppose we want to restrict the ability to edit to a user with an
'editor' value of yes.

The restricted action might look like this:

    sub edit : Local {
        my ( $self, $c ) = @_;

        $c->detach("unauthorized")
          unless $c->user_exists
          and $c->user->get('editor') eq 'yes';

        # do something restricted here
    }

(Note that if you have multiple realms, you can use
C<< $c->user_in_realm('realmname') >> in place of
C<< $c->user_exists(); >> This will essentially perform the same
verification as user_exists, with the added requirement that if there
is a user, it must have come from the realm specified.)

The above example is somewhat similar to role based access control.
L<Catalyst::Authentication::Store::Minimal> treats the roles field as
an array of role names. Let's leverage this. Add the role authorization
plugin:

    use Catalyst qw/
        ...
        Authorization::Roles
    /;

    sub edit : Local {
        my ( $self, $c ) = @_;

        $c->detach("unauthorized") unless $c->check_user_roles("edit");

        # do something restricted here
    }

This is somewhat simpler and will work if you change your store, too, since the
role interface is consistent.

Let's say your app grows, and you now have 10,000 users. It's no longer
efficient to maintain a hash of users, so you move this data to a database.
You can accomplish this simply by installing the L<DBIx::Class|Catalyst::Authentication::Store::DBIx::Class> Store and
changing your config:

    __PACKAGE__->config( 'Plugin::Authentication' =>
                    {
                        default_realm => 'members',
                        members => {
                            credential => {
                                class => 'Password',
                                password_field => 'password',
                                password_type => 'clear'
                            },
                            store => {
                                class => 'DBIx::Class',
                                user_model => 'MyApp::Users',
                                role_column => 'roles',
                            }
                        }
                    }
    );

The authentication system works behind the scenes to load your data from the
new source. The rest of your application is completely unchanged.


=head1 CONFIGURATION

    # example
    __PACKAGE__->config( 'Plugin::Authentication' =>
                {
                    default_realm => 'members',

                    members => {
                        credential => {
                            class => 'Password',
                            password_field => 'password',
                            password_type => 'clear'
                        },
                        store => {
                            class => 'DBIx::Class',
                            user_model => 'MyApp::Users',
                            role_column => 'roles',
                        }
                    },
                    admins => {
                        credential => {
                            class => 'Password',
                            password_field => 'password',
                            password_type => 'clear'
                        },
                        store => {
                            class => '+MyApp::Authentication::Store::NetAuth',
                            authserver => '192.168.10.17'
                        }
                    }
                }
    );

NOTE: Until version 0.10008 of this module, you would need to put all the
realms inside a "realms" key in the configuration. Please see
L</COMPATIBILITY CONFIGURATION> for more information

=over 4

=item use_session

Whether or not to store the user's logged in state in the session, if the
application is also using L<Catalyst::Plugin::Session>. This
value is set to true per default.

However, even if use_session is disabled, if any code touches $c->session, a session
object will be auto-vivified and session Cookies will be sent in the headers. To
prevent accidental session creation, check if a session already exists with
if ($c->sessionid) { ... }. If the session doesn't exist, then don't place
anything in the session to prevent an unecessary session from being created.

=item default_realm

This defines which realm should be used as when no realm is provided to methods
that require a realm such as authenticate or find_user.

=item realm refs

The Plugin::Authentication config hash contains the series of realm
configurations you want to use for your app. The only rule here is
that there must be at least one. A realm consists of a name, which is used
to reference the realm, a credential and a store.  You may also put your
realm configurations within a subelement called 'realms' if you desire to
separate them from the remainder of your configuration.  Note that if you use
a 'realms' subelement, you must put ALL of your realms within it.

You can also specify a realm class to instantiate instead of the default
L<Catalyst::Authentication::Realm> class using the 'class' element within the
realm config.

Each realm config contains two hashes, one called 'credential' and one called
'store', each of which provide configuration details to the respective modules.
The contents of these hashes is specific to the module being used, with the
exception of the 'class' element, which tells the core Authentication module the
classname to instantiate.

The 'class' element follows the standard Catalyst mechanism of class
specification. If a class is prefixed with a +, it is assumed to be a complete
class name. Otherwise it is considered to be a portion of the class name. For
credentials, the classname 'B<Password>', for example, is expanded to
Catalyst::Authentication::Credential::B<Password>. For stores, the
classname 'B<storename>' is expanded to:
Catalyst::Authentication::Store::B<storename>.

=back

=head1 METHODS

=head2 $c->authenticate( $userinfo [, $realm ])

Attempts to authenticate the user using the information in the $userinfo hash
reference using the realm $realm. $realm may be omitted, in which case the
default realm is checked.

=head2 $c->user( )

Returns the currently logged in user, or undef if there is none.
Normally the user is re-retrieved from the store.
For L<Catalyst::Authentication::Store::DBIx::Class> the user is re-restored
using the primary key of the user table.
Thus B<user> can throw an error even though B<user_exists>
returned true.

=head2 $c->user_exists( )

Returns true if a user is logged in right now. The difference between
B<user_exists> and B<user> is that user_exists will return true if a user is logged
in, even if it has not been yet retrieved from the storage backend. If you only
need to know if the user is logged in, depending on the storage mechanism this
can be much more efficient.
B<user_exists> only looks into the session while B<user> is trying to restore the user.

=head2 $c->user_in_realm( $realm )

Works like user_exists, except that it only returns true if a user is both
logged in right now and was retrieved from the realm provided.

=head2 $c->logout( )

Logs the user out. Deletes the currently logged in user from C<< $c->user >>
and the session.  It does not delete the session.

=head2 $c->find_user( $userinfo, $realm )

Fetch a particular users details, matching the provided user info, from the realm
specified in $realm.

    $user = $c->find_user({ id => $id });
    $c->set_authenticated($user); # logs the user in and calls persist_user

=head2 persist_user()

Under normal circumstances the user data is only saved to the session during
initial authentication.  This call causes the auth system to save the
currently authenticated user's data across requests.  Useful if you have
changed the user data and want to ensure that future requests reflect the
most current data.  Assumes that at the time of this call, $c->user
contains the most current data.

=head2 find_realm_for_persisted_user()

Private method, do not call from user code!

=head1 INTERNAL METHODS

These methods are for Catalyst::Plugin::Authentication B<INTERNAL USE> only.
Please do not use them in your own code, whether application or credential /
store modules. If you do, you will very likely get the nasty shock of having
to fix / rewrite your code when things change. They are documented here only
for reference.

=head2 $c->set_authenticated( $user, $realmname )

Marks a user as authenticated. This is called from within the authenticate
routine when a credential returns a user. $realmname defaults to 'default'.
You can use find_user to get $user

=head2 $c->auth_restore_user( $user, $realmname )

Used to restore a user from the session. In most cases this is called without
arguments to restore the user via the session. Can be called with arguments
when restoring a user from some other method.  Currently not used in this way.

=head2 $c->auth_realms( )

Returns a hashref containing realmname -> realm instance pairs. Realm
instances contain an instantiated store and credential object as the 'store'
and 'credential' elements, respectively

=head2 $c->get_auth_realm( $realmname )

Retrieves the realm instance for the realmname provided.

=head2 $c->update_user_in_session

This was a short-lived method to update user information - you should use persist_user instead.

=head2 $c->setup_auth_realm( )

=head1 OVERRIDDEN METHODS

=head2 $c->setup( )

=head1 SEE ALSO

This list might not be up to date.  Below are modules known to work with the updated
API of 0.10 and are therefore compatible with realms.

=head2 Realms

L<Catalyst::Authentication::Realm>

=head2 User Storage Backends

=over

=item L<Catalyst::Authentication::Store::Minimal>

=item L<Catalyst::Authentication::Store::DBIx::Class>

=item L<Catalyst::Authentication::Store::LDAP>

=item L<Catalyst::Authentication::Store::RDBO>

=item L<Catalyst::Authentication::Store::Model::KiokuDB>

=item L<Catalyst::Authentication::Store::Jifty::DBI>

=item L<Catalyst::Authentication::Store::Htpasswd>

=back

=head2 Credential verification

=over

=item L<Catalyst::Authentication::Credential::Password>

=item L<Catalyst::Authentication::Credential::HTTP>

=item L<Catalyst::Authentication::Credential::OpenID>

=item L<Catalyst::Authentication::Credential::Authen::Simple>

=item L<Catalyst::Authentication::Credential::Flickr>

=item L<Catalyst::Authentication::Credential::Testing>

=item L<Catalyst::Authentication::Credential::AuthTkt>

=item L<Catalyst::Authentication::Credential::Kerberos>

=back

=head2 Authorization

L<Catalyst::Plugin::Authorization::ACL>,
L<Catalyst::Plugin::Authorization::Roles>

=head2 Internals Documentation

L<Catalyst::Plugin::Authentication::Internals>

=head2 Misc

L<Catalyst::Plugin::Session>,
L<Catalyst::Plugin::Session::PerUser>

=head1 DON'T SEE ALSO

This module along with its sub plugins deprecate a great number of other
modules. These include L<Catalyst::Plugin::Authentication::Simple>,
L<Catalyst::Plugin::Authentication::CDBI>.

=head1 INCOMPATABILITIES

The realms-based configuration and functionality of the 0.10 update
of L<Catalyst::Plugin::Authentication> required a change in the API used by
credentials and stores.  It has a compatibility mode which allows use of
modules that have not yet been updated. This, however, completely mimics the
older api and disables the new realm-based features. In other words you cannot
mix the older credential and store modules with realms, or realm-based
configs. The changes required to update modules are relatively minor and are
covered in L<Catalyst::Plugin::Authentication::Internals>.  We hope that most
modules will move to the compatible list above very quickly.

=head1 COMPATIBILITY CONFIGURATION

Until version 0.10008 of this module, you needed to put all the
realms inside a "realms" key in the configuration.

    # example
    __PACKAGE__->config( 'Plugin::Authentication' =>
                {
                    default_realm => 'members',
                    realms => {
                        members => {
                            ...
                        },
                    },
                }
    );

If you use the old, deprecated C<< __PACKAGE__->config( 'authentication' ) >>
configuration key, then the realms key is still required.

=head1 COMPATIBILITY ROUTINES

In version 0.10 of L<Catalyst::Plugin::Authentication>, the API
changed. For app developers, this change is fairly minor, but for
Credential and Store authors, the changes are significant.

Please see the documentation in version 0.09 of
Catalyst::Plugin::Authentication for a better understanding of how the old API
functioned.

The items below are still present in the plugin, though using them is
deprecated. They remain only as a transition tool, for those sites which can
not yet be upgraded to use the new system due to local customizations or use
of Credential / Store modules that have not yet been updated to work with the
new API.

These routines should not be used in any application using realms
functionality or any of the methods described above. These are for reference
purposes only.

=head2 $c->login( )

This method is used to initiate authentication and user retrieval. Technically
this is part of the old Password credential module and it still resides in the
L<Password|Catalyst::Plugin::Authentication::Credential::Password> class. It is
included here for reference only.

=head2 $c->default_auth_store( )

Return the store whose name is 'default'.

This is set to C<< $c->config( 'Plugin::Authentication' => { store => # Store} ) >> if that value exists,
or by using a Store plugin:

    # load the Minimal authentication store.
    use Catalyst qw/Authentication Authentication::Store::Minimal/;

Sets the default store to
L<Catalyst::Plugin::Authentication::Store::Minimal>.

=head2 $c->get_auth_store( $name )

Return the store whose name is $name.

=head2 $c->get_auth_store_name( $store )

Return the name of the store $store.

=head2 $c->auth_stores( )

A hash keyed by name, with the stores registered in the app.

=head2 $c->register_auth_stores( %stores_by_name )

Register stores into the application.

=head2 $c->auth_store_names( )

=head2 $c->get_user( )

=head1 SUPPORT

Please use the rt.cpan.org bug tracker, and git patches are wecome.

Questions on usage should be directed to the Catalyst mailing list
or the #catalyst irc channel.

=head1 AUTHORS

Yuval Kogman, C<nothingmuch@woobling.org> - original author

Jay Kuri, C<jayk@cpan.org> - Large rewrite

=head1 PRIMARY MAINTAINER

Tomas Doran (t0m), C<bobtfish@bobtfish.net>

=head1 ADDITIONAL CONTRIBUTORS

=over

=item Jess Robinson

=item David Kamholz

=item kmx

=item Nigel Metheringham

=item Florian Ragwitz C<rafl@debian.org>

=item Stephan Jauernick C<stephanj@cpan.org>

=item Oskari Ojala (Okko), C<perl@okko.net>

=item John Napiorkowski (jnap) C<jjnapiork@cpan.org>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2005 - 2012
the Catalyst::Plugin::Authentication L</AUTHORS>,
L</PRIMARY MAINTAINER> and L</ADDITIONAL CONTRIBUTORS>
as listed above.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

