package Provider::ConfigExtended;

use Carp qw(croak);
use DateTime;
use Dancer2::Core::Types qw(Int);
use List::Util qw(first);
use Moo;
extends "Dancer2::Plugin::Auth::Extensible::Provider::Config";
use namespace::clean;

has password_expiry_days => (
    is  => 'ro',
    isa => Int,
);

around authenticate_user => sub {
    my ( $orig, $self, $username, $password, %options) = @_;
    my $ret = $orig->($self, $username, $password, %options);
    if ( $ret && $options{lastlogin} ) {
        my $user = $self->get_user_details($username);
        if ( $user->{lastlogin} ) {
            $self->plugin->app->session->write(
                $options{lastlogin} => $user->{lastlogin}->epoch );
        }
        $user->{lastlogin} = DateTime->now;
    }
    return $ret;
};

sub create_user {
    my $self = shift;
    my %user = @_ == 1 && ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;

    my $username = delete $user{username};
    croak "Username not supplied in args"
      unless defined $username && $username ne '';
    croak "User already exists"
      if first { $_->{user} eq $username } @{ $self->users };

    push @{ $self->users }, { user => $username };

    $self->set_user_details( $username, %user );
}

sub get_user_by_code {
    my ( $self, $code ) = @_;
    croak "code needs to be specified"
      unless $code && $code ne '';
    my $user = first { $_->{pw_reset_code} && $_->{pw_reset_code} eq $code }
      @{ $self->users };
    return unless $user;
    return $user->{user};
}

sub set_user_details {
    my ( $self, $username, %update ) = @_;
    croak "Username to update needs to be specified"
      unless $username && $username ne '';
    my $user = first { $_->{user} eq $username } @{ $self->users };
    return unless $user;
    foreach my $key ( keys %update ) {
        $user->{$key} = $update{$key};
    }
    return $self->get_user_details( $user->{user} );
}

sub set_user_password {
    my ( $self, $username, $password ) = @_;

    croak "username and password must be defined"
      unless defined $username && defined $password;

    my $encrypted = $self->encrypt_password($password);
    $self->set_user_details(
        $username,
        pass      => $encrypted,
        pw_changed => DateTime->now
    );
}

sub password_expired {
    my ( $self, $user ) = @_;

    croak "user must be specified"
      unless defined $user && ref($user) eq 'HASH' && defined $user->{user};

    my $expiry = $self->password_expiry_days or return 0;
    my $last_changed = $user->{pw_changed};
    return 1 unless $last_changed;

    my $duration = $last_changed->delta_days( DateTime->now );
    $duration->in_units('days') > $expiry ? 1 : 0;
}

1;
