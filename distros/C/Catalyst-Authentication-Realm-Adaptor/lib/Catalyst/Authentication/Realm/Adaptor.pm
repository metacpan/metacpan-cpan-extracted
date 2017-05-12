package Catalyst::Authentication::Realm::Adaptor;

use warnings;
use strict;
use Carp;
use Moose;
extends 'Catalyst::Authentication::Realm';

=head1 NAME

Catalyst::Authentication::Realm::Adaptor - Adjust parameters of authentication processes on the fly

=head1 VERSION

Version 0.02

=cut

## goes in catagits@jules.scsys.co.uk:Catalyst-Authentication-Realm-Adaptor.git

our $VERSION = '0.02';

sub authenticate {
    my ( $self, $c, $authinfo ) = @_;

    my $newauthinfo;

    if (exists($self->config->{'credential_adaptor'})) {

        if ($self->config->{'credential_adaptor'}{'method'} eq 'merge_hash') {

            $newauthinfo = _munge_hash($authinfo, $self->config->{'credential_adaptor'}{'merge_hash'}, $authinfo);

        } elsif ($self->config->{'credential_adaptor'}{'method'} eq 'new_hash') {

            $newauthinfo = _munge_hash({}, $self->config->{'credential_adaptor'}{'new_hash'}, $authinfo);

        } elsif ($self->config->{'credential_adaptor'}{'method'} eq 'action') {

            my $controller = $c->controller($self->config->{'credential_adaptor'}{'controller'});
            if (!$controller) {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s credential_adaptor tried to use a controller that doesn't exist: " .
                                            $self->config->{'credential_adaptor'}{'controller'});
            }

            my $action = $controller->action_for($self->config->{'credential_adaptor'}{'action'});
            if (!$action) {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s credential_adaptor tried to use an action that doesn't exist: " .
                                            $self->config->{'credential_adaptor'}{'controller'} . "->" .
                                            $self->config->{'credential_adaptor'}{'action'});
            }
            $newauthinfo = $c->forward($action, $self->name, $authinfo, $self->config->{'credential_adaptor'});

        } elsif ($self->config->{'credential_adaptor'}{'method'} eq 'code' ) {

            if (ref($self->config->{'credential_adaptor'}{'code'}) eq 'CODE') {
                my $sub = $self->config->{'credential_adaptor'}{'code'};
                $newauthinfo = $sub->($self->name, $authinfo, $self->config->{'credential_adaptor'});
            } else {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s credential_adaptor is configured to use a code ref that doesn't exist");
            }
        }
        return $self->SUPER::authenticate($c, $newauthinfo);
    } else {
        return $self->SUPER::authenticate($c, $authinfo);
    }
}

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $newauthinfo;

    if (exists($self->config->{'store_adaptor'})) {

        if ($self->config->{'store_adaptor'}{'method'} eq 'merge_hash') {

            $newauthinfo = _munge_hash($authinfo, $self->config->{'store_adaptor'}{'merge_hash'}, $authinfo);

        } elsif ($self->config->{'store_adaptor'}{'method'} eq 'new_hash') {

            $newauthinfo = _munge_hash({}, $self->config->{'store_adaptor'}{'new_hash'}, $authinfo);

        } elsif ($self->config->{'store_adaptor'}{'method'} eq 'action') {

            my $controller = $c->controller($self->config->{'store_adaptor'}{'controller'});
            if (!$controller) {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s store_adaptor tried to use a controller that doesn't exist: " .
                                            $self->config->{'store_adaptor'}{'controller'});
            }

            my $action = $controller->action_for($self->config->{'store_adaptor'}{'action'});
            if (!$action) {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s store_adaptor tried to use an action that doesn't exist: " .
                                            $self->config->{'store_adaptor'}{'controller'} . "->" .
                                            $self->config->{'store_adaptor'}{'action'});
            }
            $newauthinfo = $c->forward($action, $self->name, $authinfo, $self->config->{'store_adaptor'});

        } elsif ($self->config->{'store_adaptor'}{'method'} eq 'code' ) {

            if (ref($self->config->{'store_adaptor'}{'code'}) eq 'CODE') {
                my $sub = $self->config->{'store_adaptor'}{'code'};
                $newauthinfo = $sub->($self->name, $authinfo, $self->config->{'store_adaptor'});
            } else {
                Catalyst::Exception->throw(__PACKAGE__ . " realm: " . $self->name . "'s store_adaptor is configured to use a code ref that doesn't exist");
            }
        }
        return $self->SUPER::find_user($newauthinfo, $c);
    } else {
        return $self->SUPER::find_user($authinfo, $c);
    }
}

sub _munge_hash {
    my ($sourcehash, $modhash, $referencehash) = @_;

    my $resulthash = { %{$sourcehash} };

    foreach my $key (keys %{$modhash}) {
        if (ref($modhash->{$key}) eq 'HASH') {
            if (ref($sourcehash->{$key}) eq 'HASH') {
                $resulthash->{$key} = _munge_hash($sourcehash->{$key}, $modhash->{$key}, $referencehash)
            } else {
                $resulthash->{$key} = _munge_hash({}, $modhash->{$key}, $referencehash);
            }
        } else {
            if (ref($modhash->{$key} eq 'ARRAY') && ref($sourcehash->{$key}) eq 'ARRAY') {
                push @{$resulthash->{$key}}, _munge_value($modhash->{$key}, $referencehash)
            }
            $resulthash->{$key} = _munge_value($modhash->{$key}, $referencehash);
            if (ref($resulthash->{$key}) eq 'SCALAR' && ${$resulthash->{$key}} eq '-') {
                ## Scalar reference to a string '-' means delete the element from the source array.
                delete($resulthash->{$key});
            }
        }
    }
    return($resulthash);
}

sub _munge_value {
    my ($modvalue, $referencehash) = @_;

    my $newvalue;
    if ($modvalue =~ m/^([+-])\((.*)\)$/) {
        my $action = $1;
        my $keypath = $2;
        ## do magic
        if ($action eq '+') {
            ## action = string '-' means delete the element from the source array.
            ## otherwise it means copy it from a field in the original hash with nesting
            ## indicated via '.' - IE similar to Template Toolkit handling of nested hashes
            my @hashpath = split /\./, $keypath;
            my $val = $referencehash;
            foreach my $subkey (@hashpath) {
                if (ref($val) eq 'HASH') {
                    $val = $val->{$subkey};
                } elsif (ref($val) eq 'ARRAY') {
                    $val = $val->[$subkey];
                } else {
                    ## failed to find that key in the hash / array
                    $val = undef;
                    last;
                }
            }
            $newvalue = $val;
        } else {
            ## delete the value... so we return a scalar ref to '-'
            $newvalue = \'-';
        }
    } elsif (ref($modvalue) eq 'ARRAY') {
        $newvalue = [];
        foreach my $row (0..$#{$modvalue}) {
            if (defined($modvalue->[$row])) {
                my $val = _munge_value($modvalue->[$row], $referencehash);
                ## this is the first time I've ever wanted  to use unless
                ## to make things clearer
                unless (ref($val) eq 'SCALAR' && ${$val} eq '-') {
                    $newvalue->[$row] = $val;
                }
            }
        }
    } else {
        $newvalue = $modvalue;
    }
    return $newvalue;
}


=head1 SYNOPSIS

The Catalyst::Authentication::Realm::Adaptor allows for modification of
authentication parameters within the catalyst application. It's basically a
filter used to adjust authentication parameters globally within the
application or to adjust user retrieval parameters provided by the credential
in order to be compatible with a different store. It provides for better
control over interaction between credentials and stores. This is particularly
useful when working with external authentication such as OpenID or OAuth.

 __PACKAGE__->config(
    'Plugin::Authentication' => {
            'default' => {
                class => 'Adaptor'
                credential => {
                    class => 'Password',
                    password_field => 'secret',
                    password_type  => 'hashed',
                    password_hash_type => 'SHA-1',
                },
                store => {
                    class      => 'DBIx::Class',
                    user_class => 'Schema::Person',
                },
                store_adaptor => {
                    method => 'merge_hash',
                    merge_hash => {
                        status => [ 'temporary', 'active' ]
                    }
                }
            },
        }
    }
 );


The above example ensures that no matter how $c->authenticate() is called
within your application, the key 'status' is added to the authentication hash.
This allows you to, among other things, set parameters that should always be
applied to your authentication process or modify the parameters to better
connect a credential and a store that were not built to work together. In the
above example, we are making sure that the user search is restricted to those
with a status of either 'temporary' or 'active.'

This realm works by intercepting the original authentication information
between the time C<< $c->authenticate($authinfo) >> is called and the time the
realm's C<< $realm->authenticate($c,$authinfo) >> method is called, allowing for
the $authinfo parameter to be modified or replaced as your application
requires. It can also operate after the call to the credential's
C<authenticate()> method but before the call to the store's C<find_user>
method.

If you don't know what the above means, you probably do not need this module.

=head1 CONFIGURATION

The configuration for this module goes within your realm configuration alongside your
credential and store options.

This module can operate in two points during authentication processing.
The first is prior the realm's C<authenticate> call (immediately after the call to
C<< $c->authenticate() >>.) To operate here, your filter options should go in a hash
under the key C<credential_adaptor>.

The second point is after the call to credential's C<authenticate> method but
immediately before the call to the user store's C<find_user> method. To operate
prior to C<find_user>, your filter options should go in a hash under the key
C<store_adaptor>.

The filtering options for both points are the same, and both the C<store_adaptor> and
C<credential_adaptor> can be used simultaneously in a single realm.

=head2 method

There are four ways to configure your filters.  You specify which one you want by setting
the C<method> configuration option to one of the following: C<merge_hash>, C<new_hash>,
C<code>, or C<action>.  You then provide the additional information based on which method
you have chosen.  The different options are described below.

=over 8

=item merge_hash

 credential_adaptor => {
     method => 'merge_hash',
     merge_hash => {
         status => [ 'temporary', 'active' ]
     }
 }

This causes the original authinfo hash to be merged with a hash provided by
the realm configuration under the key C<merge_hash> key. This is a deep merge
and in the case of a conflict, the hash specified by merge_hash takes
precedence over what was passed into the authenticate or find_user call. The
method of merging is described in detail in the L<HASH MERGING> section below.

=item new_hash

 store_adaptor => {
     method => 'new_hash',
     new_hash => {
         username => '+(user)',  # this sets username to the value of $originalhash{user}
         user_source => 'openid'
     }
 }

This causes the original authinfo hash to be set aside and replaced with a new hash provided under the
C<new_hash> key. The new hash can grab portions of the original hash.  This can be used to remap the authinfo
into a new format.  See the L<HASH MERGING> section for information on how to do this.

=item code

 store_adaptor => {
     method => 'code',
     code => sub {
         my ($realmname, $original_authinfo, $hashref_to_config ) = @_;
         my $newauthinfo = {};
         ## do something
         return $newauthinfo;
     }
 }

The C<code> method allows for more complex filtering by executing code
provided as a subroutine reference in the C<code> key. The realm name,
original auth info and the portion of the config specific to this filter are
passed as arguments to the provided subroutine. In the above example, it would
be the entire store_adaptor hash. If you were using a code ref in a
credential_adaptor, you'd get the credential_adapter config instead.

=item action

 credential_adaptor => {
     method => 'action',
     controller => 'UserProcessing',
     action => 'FilterCredentials'
 }

The C<action> method causes the adaptor to delegate filtering to a Catalyst
action. This is similar to the code ref above, except that instead of simply
calling the routine, the action specified is called via C<<$c->forward>>. The
arguments passed to the action are the same as the code method as well,
namely the realm name, the original authinfo hash and the config for the adaptor.

=back

=head1 HASH MERGING

The hash merging mechanism in Catalyst::Authentication::Realm::Adaptor is not
a simple merge of two hashes. It has some niceties which allow for both
re-mapping of existing keys, and a mechanism for removing keys from the
original hash. When using the 'merge_hash' method above, the keys from the
original hash and the keys for the merge hash are simply combined with the
merge_hash taking precedence in the case of a key conflict. If there are
sub-hashes they are merged as well.

If both the source and merge hash contain an array for a given hash-key, the
values in the merge array are appended to the original array.  Note that hashes
within arrays will not be merged, and will instead simply be copied.

Simple values are left intact, and in the case of a key existing in both
hashes, the value from the merge_hash takes precedence. Note that in the case
of a key conflict where the values are of different types, the value from the
merge_hash will be used and no attempt is made to merge or otherwise convert
them.

=head2 Advanced merging

Whether you are using C<merge_hash> or C<new_hash> as the method, you have access
to the values from the original authinfo hash.  In your new or merged hash, you
can use values from anywhere within the original hash.  You do this by setting
the value for the key you want to set to a special string indicating the key
path in the original hash.  The string is formatted as follows:
C<<'+(key1.key2.key3)'>>  This will grab the hash associated with key1, retrieve the hash
associated with key2, and finally obtain the value associated with key3.  This is easier to
show than to explain:

 my $originalhash = {
                        user => {
                                details => {
                                    age       => 27,
                                    haircolor => 'black',
                                    favoritenumbers => [ 17, 42, 19 ]
                                }
                        }
                    };

  my $newhash = {
                    # would result in a value of 'black'
                    haircolor => '+(user.details.haircolor)',

                    # bestnumber would be 42.
                    bestnumber => '+(user.details.favoritenumbers.1)'
                }

Given the example above, the value for the userage key would be 27, (obtained
via C<<'+(user.details.age)'>>) and the value for bestnumber would be 42. Note
that you can traverse both hashes and arrays using this method. This can be
quite useful when you need the values that were passed in, but you need to put
them under different keys.

When using the C<merge_hash> method, you sometimes may want to remove an item
from the original hash. You can do this by providing a key in your merge_hash
at the same point, but setting it's value to '-()'.  This will remove the key
entirely from the resultant hash.  This works better than simply setting the
value to undef in some cases.

=head1 NOTES and CAVEATS

The authentication system for Catalyst is quite flexible.  In most cases this
module is not needed.  Evidence of this fact is that the Catalyst auth system
was substantially unchanged for 2+ years prior to this modules first release.
If you are looking at this module, then there is a good chance your problem would
be better solved by adjusting your credential or store directly.

That said, there are some areas where this module can be particularly useful.
For example, this module allows for global application of additional arguments
to authinfo for a certain realm via your config.  It also allows for preliminary
testing of alternate configs before you adjust every C<< $c->authenticate() >> call
within your application.

It is also useful when combined with the various external authentication
modules available, such as OpenID, OAuth or Facebook. These modules expect to
store their user information in the Hash provided by the Minimal user store.
Often, however, you want to store user information locally in a database or
other storage mechanism. Doing this lies somewhere between difficult and
impossible normally. With the Adapter realm, you can massage the authinfo hash
between the credential's verification and the creation of the local user, and
instead use the information returned to look up a user instead.

Using the external auth mechanisms and the C<action> method, you can actually
trigger an action to create a user record on the fly when the user has
authenticated via an external method.  These are just some of the possibilities
that Adaptor provides that would otherwise be very difficult to accomplish,
even with Catalyst's flexible authentication system.

With all of that said, caution is warranted when using this module.  It modifies
the behavior of the application in ways that are not obvious and can therefore
lead to extremely hard to track-down bugs.  This is especially true when using
the C<action> filter method.  When a developer calls C<< $c->authenticate() >>
they are not expecting any actions to be called before it returns.

If you use the C<action> method, I strongly recommend that you use it only as a
filter routine and do not do other catalyst dispatch related activities (such as
further forwards, detach's or redirects).  Also note that it is B<EXTREMELY
DANGEROUS> to call authentication routines from within a filter action.  It is
extremely easy to accidentally create an infinite recursion bug which can crash
your Application.  In short - B<DON'T DO IT>.

=head1 AUTHOR

Jay Kuri, C<< <jayk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-authentication-realm-adaptor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-Realm-Adaptor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::Realm::Adaptor

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-Realm-Adaptor/>

=item * Catalyzed.org Wiki

L<http://wiki.catalyzed.org/cpan-modules/Catalyst-Authentication-Realm-Adaptor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jay Kuri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Catalyst::Authentication::Realm::Adaptor
