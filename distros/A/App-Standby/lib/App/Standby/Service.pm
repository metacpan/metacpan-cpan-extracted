package App::Standby::Service;
$App::Standby::Service::VERSION = '0.04';
BEGIN {
  $App::Standby::Service::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Service Plugin baseclass

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'App::Standby';
# has ...
has 'name' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);

has 'description' => (
    'is'        => 'rw',
    'isa'       => 'Str',
    'required'  => 0,
);

has 'group_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 1,
);
# with ...
# initializers ...

# your code here ...
sub update {
    my $self = shift;
    my $user_ref = shift;

    # this base class does nothing here
    # subclasses should override this method
    # and update their services here ...
    my $new_user_ref = $self->_inject_per_user_config($user_ref);

    return $self->_update($new_user_ref);
}

sub _update {
    my $self = shift;
    my $user_ref = shift;
    # this base class does nothing here
    # subclasses should override this method
    # and update their services here ...
    return;
}

sub _inject_per_user_config {
    my $self = shift;
    my $user_ref = shift;

    my $sql = 'SELECT id,key,value FROM config_contacts WHERE contact_id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return;
    }

    my @new_users = ();

    foreach my $user (@{$user_ref}) {
        if(!$sth->execute($user->{'id'})) {
            $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
        }

        # copy existing values
        my $new_user = {};
        foreach my $key (keys %{$user}) {
            $new_user->{$key} = $user->{$key};
        }
        # add new values
        while(my ($cconfig_id,$cconfig_key,$cconfig_value) = $sth->fetchrow_array()) {
            my $service_name = $self->name();
            # only use config items for this service
            next unless $cconfig_key =~ m/^${service_name}_/;
            # strip leading serice name prefix
            $cconfig_key =~ s/^${service_name}_//i;
            if($new_user->{$cconfig_key}) {
                $self->logger()->log( message => 'Per-user config item '.$cconfig_key.' collides w/ existing value. Overwriting global item with per-user item', level => 'warning', );
            }
            $new_user->{$cconfig_key} = $cconfig_value;
        }

        push(@new_users,$new_user);
    }

    $sth->finish();

    return \@new_users;
}

sub _config_values {
    my $self = shift;
    my $key = shift;

    return $self->SUPER::_config_values($key, $self->group_id());
}

sub _config_value {
    my $self = shift;
    my $key = shift;

    my $vals = $self->_config_values($key);
    if(ref($vals) eq 'ARRAY') {
        return $vals->[0];
    } else {
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Service - Service Plugin baseclass

=head1 ATTRIBUTES

=head2 name

The name of this plugin. SHOULD be lowercase. SHOULD also used as a key prefix in the
config table.

=head2 description

A human readable description of this service plugin. Used for display and logging.
MAY be empty.

=head2 group_id

The numeric group id of the group this service plugins instance is associated with.
MUST be numeric and MUST NOT be empty.

=head1 METHODS

=head2 update

This method is called with a array_ref containing the new ordering on any changed.

=head1 NAME

App::Standby::Service - Service Plugin baseclass

=head1 ADDING A NEW SERVICE

First of all there are two kinds of services: Simple HTTP endpoints and complex plugins.

The simple HTTP plugins just receive the whole queue in as JSON encoded array.
Those only need to subclass App::Standby::Service::HTTP and provide an implementation
for _init_endpoints. Have a look at the simple example.

All other services will need to subclass App::Standby::Service and implement an
update() method. Have a look at App::Standby::Service::Pingom for an example.

The method _config_values helps with getting values to known keys from
the config table. A service plugin MUST always prepend its name to
the key to allow for multiple instances of one plugin registered at
the same time.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
