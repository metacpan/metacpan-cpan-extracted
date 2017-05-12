package Catalyst::Plugin::Authentication::Store::RDBO::Backend;
$VERSION = 0.001;

use strict;
use warnings;


sub new {
    my ($class, $config) = @_;

    my $uc = $config->{auth}{catalyst_user_class};
    eval "require $uc";
    die $@ if $@;

    my $self = {%$config};

    return bless $self, $class;
}

sub from_session {
    my ($self, $c, $id) = @_;

    # user object
    return $id if ref $id;

    return $self->{auth}{catalyst_user_class}->new($id, {%$self});
}

sub get_user {
    my ($self, $id) = @_;

    my $user = $self->{auth}{catalyst_user_class}->new($id, {%$self});

    if ($user) {
        $user->store($self);
        return $user;
    }

    return undef;
}

sub user_supports {
    my $self = shift;

    $self->{auth}{catalyst_user_class}->supports(@_);
}


1;
