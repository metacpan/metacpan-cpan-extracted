package Catalyst::Plugin::Authentication::Store::DBIC::User;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Authentication::User Class::Accessor::Fast/;
use Set::Object ();
use Carp qw/confess/;
use Data::Dumper;

use overload '""' => sub { shift->id }, 'bool' => sub { 1 }, fallback => 1;

__PACKAGE__->mk_accessors(qw/id config store _obj/);


sub new {
    my ( $class, $id, $config ) = @_;
    bless {
        id     => $id,
        config => $config
    }, $class;
}

sub obj {
    my $self=shift;
    my $config=$self->config;
    my $id=$self->id;
    unless (ref $self->_obj) {
        my $query = @{$config->{auth}{user_field}} > 1
            ? { -or => [ map { { $_ => $id } } @{$config->{auth}{user_field}} ] }
            : { $config->{auth}{user_field}[0] => $id };
        $self->_obj($config->{auth}{user_class}->search($query)->first);
    }
    return $self->_obj;
}

sub canonical_id {
    my $self=shift;
    return undef unless $self->obj();
    my $field = $self->config->{auth}{user_field}[0];
    return $self->obj->$field,
}


*user = \&obj;
*crypted_password = \&password;
*hashed_password = \&password;

sub hash_algorithm { shift->config->{auth}{password_hash_type} }

sub password_pre_salt { shift->config->{auth}{password_pre_salt} }

sub password_post_salt { shift->config->{auth}{password_post_salt} }

sub password_salt_len { shift->config->{auth}{password_salt_len} }

sub password {
    my $self = shift;

    return undef unless defined $self->obj;
    my $password_field = $self->config->{auth}{password_field};
    return $self->obj->$password_field;
}

sub supported_features {
    my $self = shift;
    $self->config->{auth}{password_type} ||= 'clear';

    return {
        password => {
            $self->config->{auth}{password_type} => 1,
        },
        session         => 1,
        session_data    => $self->{config}{auth}{session_data_field} ? 1 : 0,
        roles           => { self_check => 1 },
    };
}

sub get_session_data {
    my ( $self ) = @_;
    my $col = $self->config->{auth}{session_data_field};
    return $self->obj->$col;
}

sub store_session_data {
    my ( $self, $data ) = @_;
    my $col = $self->config->{auth}{session_data_field};
    my $obj = $self->obj;
    $obj->result_source->schema->txn_do(sub {
        $obj->$col($data);
        $obj->update;
    });
}

sub check_roles {
    my ( $self, @wanted_roles ) = @_;

    my $have = Set::Object->new( $self->roles( @wanted_roles ) );
    my $need = Set::Object->new( @wanted_roles );

    $have->superset( $need );
}

sub roles {
    my ( $self, @wanted_roles ) = @_;

    unless ( $self->config->{authz} ) {
        Catalyst::Exception->throw(
            message => 'No authorization configuration defined'
        );
    }

    return $self->_role_search(@wanted_roles);
}

# optimized join if using DBIC
sub _role_search {
    my ($self, @wanted_roles) = @_;
    my $cfg = $self->config->{authz};
    my $role_field = $cfg->{role_field};
    
    my $search = {
        $cfg->{role_rel} . '.' . $cfg->{user_role_user_field}
            => $self->obj->id
    };    
    $search->{ "me.$role_field" } = { -in => \@wanted_roles } if @wanted_roles;

    my $rs = $cfg->{role_class}->search(
        $search,
        {
            join => $cfg->{role_rel},
            columns => [ "me.$role_field" ],
        }
    );
    return map { $_->$role_field } $rs->all;
}

sub for_session {
    shift->id;
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    $self->obj->$method(@_);
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIC::User - A user object
representing an entry in a database.

=head1 SYNOPSIS

    use Catalyst::Plugin::Authentication::Store::DBIC::User;

=head1 DESCRIPTION

This class implements a user object.

=head1 INTERNAL METHODS

=head2 new

=head2 crypted_password

=head2 hashed_password

=head2 hash_algorithm

=head2 password_pre_salt

=head2 password_post_salt

=head2 password_salt_len

=head2 password

=head2 supported_features

=head2 roles

=head2 check_roles

=head2 for_session

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication::Store::DBIC>

=head1 AUTHORS

David Kamholz, <dkamholz@cpan.org>

Andy Grundman

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
