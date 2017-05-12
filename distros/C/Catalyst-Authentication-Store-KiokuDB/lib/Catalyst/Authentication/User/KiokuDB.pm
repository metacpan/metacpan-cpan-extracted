package Catalyst::Authentication::User::KiokuDB;

use Moose;
use base qw/Catalyst::Authentication::User/;

has id => (
    isa => 'Str',
    is  => 'rw',
);

has username => (
    isa => 'Str',
    is  => 'rw',
);

has password => (
    isa => 'Str',
    is  => 'rw',
);

has crypted_password => (
    isa => 'Str',
    is  => 'rw',
);

has hashed_password => (
    isa => 'Str',
    is  => 'rw',
);

has hash_algorithm => (
    isa => 'Str',
    is  => 'rw',
);

has roles => (
    isa         => 'ArrayRef',
    is          => 'rw',
    auto_deref  => 1,
);

sub TO_JSON {
    my $self = shift;
    my %ret;
    for my $k (qw/id username password crypted_password hashed_password hash_algorithm roles/) {
        my $v = $self->$k;
        $ret{$k} = $v if defined $v;
    }
    return \%ret;
}


# all hail the gods of cut and paste
my %features = (
    password => {
        clear      => ["password"],
        crypted    => ["crypted_password"],
        hashed     => [qw/hashed_password hash_algorithm/],
        self_check => undef,
    },
    roles   => ["roles"],
    session => 1,
);

sub supports {
    my ($self, @spec) = @_;

    my $cursor = \%features;

    return 1 if @spec == 1 and $self->can($spec[0]);

    # XXX is this correct?
    for (@spec) {
        return if ref($cursor) ne "HASH";
        $cursor = $cursor->{$_};
    }

    if (ref $cursor) {
        die "Bad feature spec: '@spec'" unless ref $cursor eq "ARRAY";
        foreach my $key (@$cursor) {
            return undef unless $self->can($key);
        }
        return 1;
    }
    else {
        return $cursor;
    }
}

sub for_session {
    my $self = shift;
    return $self; # KiokuDB should be fine with storing objects in the session
}

sub from_session {
    my ($self, $c, $user) = @_;
    return $user; # normally we should have gotten ourselves back
}


no Moose;
1;

=pod

=head1 NAME

Catalyst::Authentication::User::KiokuDB - User object for KiokuDB

=head1 SYNOPSIS

	use Catalyst::Authentication::User::KiokuDB;
	
	Catalyst::Authentication::User::KiokuDB->new(
	    username    => "kitteh",
		password    => "baddog",
		roles       => [qw/sleep eat play purr/],
	);

=head1 DESCRIPTION

This implementation of authentication user object is intended to go hand in
hand with L<Catalyst::Authentication::Store::KiokuDB>.

=head1 METHODS

Implements nothing beyond the requisite interface from its superclass

=head1 AUTHOR

Robin Berjon, <robin@berjon.com>, L<http://robineko.com/>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
