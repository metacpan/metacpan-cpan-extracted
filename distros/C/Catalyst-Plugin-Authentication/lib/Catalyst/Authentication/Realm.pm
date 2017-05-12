package Catalyst::Authentication::Realm;
use Moose;
use namespace::autoclean;

with 'MooseX::Emulate::Class::Accessor::Fast';
use String::RewritePrefix;
use Try::Tiny qw/ try catch /;

__PACKAGE__->mk_accessors(qw/store credential name config/);

## Add use_session config item to realm.

sub new {
    my ($class, $realmname, $config, $app) = @_;

    my $self = { config => $config };
    bless $self, $class;

    $self->name($realmname);

    if (!exists($self->config->{'use_session'})) {
        if (exists($app->config->{'Plugin::Authentication'}{'use_session'})) {
            $self->config->{'use_session'} = $app->config->{'Plugin::Authentication'}{'use_session'};
        } else {
            $self->config->{'use_session'} = 1;
        }
    }

    $app->log->debug("Setting up auth realm $realmname") if $app->debug;

    # use the Null store as a default - Don't complain if the realm class is being overridden,
    # as the new realm may behave differently.
    if( ! exists($config->{store}{class}) ) {
        $config->{store}{class} = '+Catalyst::Authentication::Store::Null';
        if (! exists($config->{class})) {
            $app->log->debug( qq(No Store specified for realm "$realmname", using the Null store.) );
        }
    }
    my $storeclass = $config->{'store'}{'class'};

    ## follow catalyst class naming - a + prefix means a fully qualified class, otherwise it's
    ## taken to mean C::P::A::Store::(specifiedclass)
    $storeclass = String::RewritePrefix->rewrite({
        '' => 'Catalyst::Authentication::Store::',
        '+' => '',
    }, $storeclass);

    # a little niceness - since most systems seem to use the password credential class,
    # if no credential class is specified we use password.
    $config->{credential}{class} ||= '+Catalyst::Authentication::Credential::Password';

    my $credentialclass = $config->{'credential'}{'class'};

    ## follow catalyst class naming - a + prefix means a fully qualified class, otherwise it's
    ## taken to mean C::A::Credential::(specifiedclass)
    $credentialclass = String::RewritePrefix->rewrite({
        '' => 'Catalyst::Authentication::Credential::',
        '+' => '',
    }, $credentialclass);

    # if we made it here - we have what we need to load the classes

    ### BACKWARDS COMPATIBILITY - DEPRECATION WARNING:
    ###  we must eval the ensure_class_loaded - because we might need to try the old-style
    ###  ::Plugin:: module naming if the standard method fails.

    ## Note to self - catch second exception and bitch in detail?

    try {
        Catalyst::Utils::ensure_class_loaded( $credentialclass );
    }
    catch {
        # If the file is missing, then try the old-style fallback,
        # but re-throw anything else for the user to deal with.
        die $_ unless /^Can't locate/;
        $app->log->warn( qq(Credential class "$credentialclass" not found, trying deprecated ::Plugin:: style naming. ) );
        my $origcredentialclass = $credentialclass;
        $credentialclass =~ s/Catalyst::Authentication/Catalyst::Plugin::Authentication/;

        try { Catalyst::Utils::ensure_class_loaded( $credentialclass ); }
        catch {
            # Likewise this croak is useful if the second exception is also "not found",
            # but would be confusing if it's anything else.
            die $_ unless /^Can't locate/;
            Carp::croak "Unable to load credential class, " . $origcredentialclass . " OR " . $credentialclass .
                        " in realm " . $self->name;
        };
    };

    try {
        Catalyst::Utils::ensure_class_loaded( $storeclass );
    }
    catch {
        # If the file is missing, then try the old-style fallback,
        # but re-throw anything else for the user to deal with.
        die $_ unless /^Can't locate/;
        $app->log->warn( qq(Store class "$storeclass" not found, trying deprecated ::Plugin:: style naming. ) );
        my $origstoreclass = $storeclass;
        $storeclass =~ s/Catalyst::Authentication/Catalyst::Plugin::Authentication/;
        try { Catalyst::Utils::ensure_class_loaded( $storeclass ); }
        catch {
            # Likewise this croak is useful if the second exception is also "not found",
            # but would be confusing if it's anything else.
            die $_ unless /^Can't locate/;
            Carp::croak "Unable to load store class, " . $origstoreclass . " OR " . $storeclass .
                        " in realm " . $self->name;
        };
    };

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

    ## a little cruft to stay compatible with some poorly written stores / credentials
    ## we'll remove this soon.
    if ($storeclass->can('new')) {
        $self->store($storeclass->new($config->{'store'}, $app, $self));
    }
    else {
        $app->log->error("THIS IS DEPRECATED: $storeclass has no new() method - Attempting to use uninstantiated");
        $self->store($storeclass);
    }
    if ($credentialclass->can('new')) {
        $self->credential($credentialclass->new($config->{'credential'}, $app, $self));
    }
    else {
        $app->log->error("THIS IS DEPRECATED: $credentialclass has no new() method - Attempting to use uninstantiated");
        $self->credential($credentialclass);
    }

    return $self;
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $res = $self->store->find_user($authinfo, $c);

    if (!$res) {
      if ($self->config->{'auto_create_user'} && $self->store->can('auto_create_user') ) {
          $res = $self->store->auto_create_user($authinfo, $c);
      }
    } elsif ($self->config->{'auto_update_user'} && $self->store->can('auto_update_user')) {
        $res = $self->store->auto_update_user($authinfo, $c, $res);
    }

    return $res;
}

sub authenticate {
     my ($self, $c, $authinfo) = @_;

     my $user = $self->credential->authenticate($c, $self, $authinfo);
     if (ref($user)) {
         $c->set_authenticated($user, $self->name);
         return $user;
     } else {
         return undef;
     }
}

sub user_is_restorable {
    my ($self, $c) = @_;

    return unless
         $c->can('session')
         and $self->config->{'use_session'}
         and $c->session_is_valid;

    return $c->session->{__user};
}

sub restore_user {
    my ($self, $c, $frozen_user) = @_;

    $frozen_user ||= $self->user_is_restorable($c);
    return unless defined($frozen_user);

    my $user = $self->from_session( $c, $frozen_user );

    if ($user) {
        $c->_user( $user );

        # this sets the realm the user originated in.
        $user->auth_realm($self->name);
    }
    else {
        $self->failed_user_restore($c) ||
            $c->error("Store claimed to have a restorable user, but restoration failed.  Did you change the user's id_field?");
    }

    return $user;
}

## this occurs if there is a session but the thing the session refers to
## can not be found.  Do what you must do here.
## Return true if you can fix the situation and find a user, false otherwise
sub failed_user_restore {
    my ($self, $c) = @_;

    $self->remove_persisted_user($c);
    return;
}

sub persist_user {
    my ($self, $c, $user) = @_;

    if (
        $c->can('session')
        and $self->config->{'use_session'}
        and $user->supports("session")
    ) {
        $c->session->{__user_realm} = $self->name;

        # we want to ask the store for a user prepared for the session.
        # but older modules split this functionality between the user and the
        # store.  We try the store first.  If not, we use the old method.
        if ($self->store->can('for_session')) {
            $c->session->{__user} = $self->store->for_session($c, $user);
        } else {
            $c->session->{__user} = $user->for_session;
        }
    }
    return $user;
}

sub remove_persisted_user {
    my ($self, $c) = @_;

    if (
        $c->can('session')
        and $self->config->{'use_session'}
        and $c->session_is_valid
    ) {
        delete @{ $c->session }{qw/__user __user_realm/};
    }
}

## backwards compatibility - I don't think many people wrote realms since they
## have only existed for a short time - but just in case.
sub save_user_in_session {
    my ( $self, $c, $user ) = @_;

    return $self->persist_user($c, $user);
}

sub from_session {
    my ($self, $c, $frozen_user) = @_;

    return $self->store->from_session($c, $frozen_user);
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Authentication::Realm - Base class for realm objects.

=head1 DESCRIPTION

=head1 CONFIGURATION

=over 4

=item class

By default this class is used by
L<Catalyst::Plugin::Authentication|Catalyst::Plugin::Authentication> for all
realms. The class parameter allows you to choose a different class to use for
this realm. Creating a new Realm class can allow for authentication methods
that fall outside the normal credential/store methodology.

=item auto_create_user

Set this to true if you wish this realm to auto-create user accounts when the
user doesn't exist (most useful for remote authentication schemes).

=item auto_update_user

Set this to true if you wish this realm to auto-update user accounts after
authentication (most useful for remote authentication schemes).

=item use_session

Sets session usage for this particular realm - overriding the global use_sesion setting.


=back

=head1 METHODS

=head2 new( $realmname, $config, $app )

Instantiantes this realm, plus the specified store and credential classes.

=head2 store( )

Returns an instance of the store object for this realm.

=head2 credential( )

Returns an instance of the credential object for this realm.

=head2 find_user( $authinfo, $c )

Retrieves the user given the authentication information provided.  This
is most often called from the credential.  The default realm class simply
delegates this call the store object.  If enabled, auto-creation and
auto-updating of users is also handled here.

=head2 authenticate( $c, $authinfo)

Performs the authentication process for the current realm.  The default
realm class simply delegates this to the credential and sets
the authenticated user on success.  Returns the authenticated user object;

=head1 USER PERSISTENCE

The Realm class allows complete control over the persistance of users
between requests.  By default the realm attempts to use the Catalyst
session system to accomplish this.  By overriding the methods below
in a custom Realm class, however, you can handle user persistance in
any way you see fit.

=head2 persist_user($c, $user)

persist_user is the entry point for saving user information between requests
in most cases this will utilize the session.  By default this uses the
catalyst session system to store the user by calling for_session on the
active store.  The user object must be a subclass of
Catalyst::Authentication::User.  If you have updated the user object, you
must call persist_user again to ensure that the persisted user object reflects
your updates.

=head2 remove_persisted_user($c)

Removes any persisted user data.  By default, removes the user from the session.

=head2 user_is_restorable( $c )

Returns whether there is a persisted user that may be restored.  Returns
a token used to restore the user.  With the default session persistance
it returns the raw frozen user information.

=head2 restore_user($c, [$frozen_user])

Restores the user from the given frozen_user parameter, or if not provided,
using the response from $self->user_is_restorable();  Uses $self->from_session()
to decode the frozen user.

=head2 failed_user_restore($c)

If there is a session to restore, but the restore fails for any reason then this method
is called. This method supplied just removes the persisted user, but can be overridden
if required to have more complex logic (e.g. finding a the user by their 'old' username).

=head2 from_session($c, $frozenuser )

Decodes the frozenuser information provided and returns an instantiated
user object.  By default, this call is delegated to $store->from_session().

=head2 save_user_in_session($c, $user)

DEPRECATED.  Use persist_user instead.  (this simply calls persist_user)

=cut
