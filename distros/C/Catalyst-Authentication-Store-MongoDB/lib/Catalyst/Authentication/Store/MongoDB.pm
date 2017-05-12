package Catalyst::Authentication::Store::MongoDB;

use 5.006;
use strict;
use warnings;

=head1 NAME

Catalyst::Authentication::Store::MongoDB - L<MongoDB> backend for
Catalyst::Plugin::Authentication

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module links a subclass of MongoDB to your Catalyst application as a user
store for the Authentication plugin.

    <Plugin::Authentication>
        <default>
            <credential>
                class Password
                password_type self_check
            </credential>
            <store>
                class MongoDB
                user_collection user
                user_class Catalyst::Authentication::User::Hash
                model MongoDB
                database db
            </store>
        </default>
    </Plugin::Authentication>

Then use it as normal

    sub login : Local {
        my ($self, $c) = @_;
        $c->authenticate({
            username => $username,
            password => $password
        });
    }

=head1 CONFIGURATION

=head2 class

The configuration required by L<Catalyst::Plugin::Authentication> to load this
store in the first place.

=head2 user_collection

The collection in your database that holds users.

=head2 user_class

Some subclass of Catalyst::Authentication::User to bless the returned objects
as.

=head2 model

The model name that you'd give to $c->model. It is expected that your model
is a L<MongoDB> subclass.

=head2 database

The database that your user_collection is a collection in.

=cut

sub new {
    my ($class, $config, $app) = @_;

    $config->{user_class} //= 'Catalyst::Authentication::User::Hash';

    my $self = {
        config => $config
    };

    bless $self, $class;
}

sub from_session {
    my ($self, $c, $frozen) = @_;

    my $user = $c->model($self->{config}->{model})
            ->connection
            ->get_database($self->{config}->{database})
            ->get_collection($self->{config}->{user_collection})
            ->find_one({
                _id => MongoDB::OID->new(value => $frozen)
            });

    bless $user, $self->{config}->{user_class} if $user;
    return $user;
}

sub for_session {
    my ($self, $c, $user) = @_;

    return $user->{_id}->{value};
}

sub find_user {
    my ($self, $authinfo, $c) = @_;

    # note to self before I forget: password is deleted from $authinfo by the
    # realm when finding the user. kthx
    my $user = $c->model($self->{config}->{model})
        ->connection
        ->get_database($self->{config}->{database})
        ->get_collection($self->{config}->{user_collection})
        ->find_one($authinfo);
    
    return undef unless $user;

    bless $user, $self->{config}->{user_class};
}

sub user_supports {
    my $self = shift;
    $self->{config}->{user_class}->supports( @_ );
}

=head1 AUTHOR

Altreus, C<< <altreus at cpan.org> >>

=head1 BUGS

I'll be amazed if this works for you at all.

Bugs and requests to github please -
https://github.com/Altreus/Catalyst-Authentication-Store-MongoDB/issues

=head1 SUPPORT

You are reading all the support you're likely to get.

=head1 ACKNOWLEDGEMENTS

Thanks to BOBTFISH for wracking his brains to try to remember how this stuff
works.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Altreus.

MIT licence. Go nuts.


=cut

1; # End of Catalyst::Authentication::Store::MongoDB
