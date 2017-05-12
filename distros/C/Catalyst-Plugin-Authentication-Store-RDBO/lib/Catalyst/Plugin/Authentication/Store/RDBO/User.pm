package Catalyst::Plugin::Authentication::Store::RDBO::User;
$VERSION = 0.002;

use strict;
use warnings;

use base qw(Catalyst::Plugin::Authentication::User
            Class::Accessor::Fast
           );

use Rose::DB::Object::Manager;
use Set::Object ();

use overload ('""'     => sub { shift->id },
              bool     => sub { 1 },
              fallback => 1,
             );


__PACKAGE__->mk_accessors(qw(id config store _obj));


sub new {
    my ($class, $id, $config) = @_;

    my $self = {id     => $id,
                config => $config,
               };

    return bless $self, $class;
}

sub obj {
    my ($self) = @_;

    my $config = $self->{config};

    unless ($self->_obj) {
        my %rose    = ();
        my $manager = $config->{auth}{manager_class};

        # no custom manager used
        unless ($manager) {
            $manager = 'Rose::DB::Object::Manager';
            $rose{object_class} = $config->{auth}{user_class};
        }

        $rose{query} = [$config->{auth}{user_field} => $self->id];
        $rose{limit} = 1;

        my $user = $manager->get_objects(%rose);

        $self->_obj($user->[0]) if @$user;
    }

    return $self->_obj;
}

*user             = \&obj;
*crypted_password = \&password;
*hashed_password  = \&password;

sub hash_algorithm     { shift->config->{auth}{password_hash_type} }

sub password_pre_salt  { shift->config->{auth}{password_pre_salt} }

sub password_post_salt { shift->config->{auth}{password_post_salt} }

sub password_salt_len  { shift->config->{auth}{password_salt_len} }

sub password {
    my ($self) = @_;

    return undef unless defined $self->obj;

    my $password_field = $self->config->{auth}->{password_field};
    return $self->obj->$password_field;
}

sub supported_features {
    my ($self) = @_;

    return {password => {$self->config->{auth}{password_type} => 1},
            session  => 1,
            roles    => {self_check => 1},
           };
}

sub check_roles {
    my ($self, @wanted_roles) = @_;

    my $have = Set::Object->new($self->roles(@wanted_roles));
    my $need = Set::Object->new(@wanted_roles);

    return $have->superset($need);
}

sub roles {
    my ($self, @wanted_roles) = @_;

    unless ($self->config->{authz}) {
        Catalyst::Exception->throw(message => 'No authorization configuration defined');
    }

    my $rel   = $self->config->{authz}{role_rel};
    my $field = $self->config->{authz}{role_field};

    my $roles = $self->obj->$rel;

    my @roles = map { $_->$field } @$roles;

    if (@wanted_roles) {
        my %wanted = map { $_ => 1 } @wanted_roles;
        @roles = grep { $wanted{$_} } @roles;
    }

    return @roles;
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
