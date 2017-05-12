package App::Standby::Service::Pingdom;
$App::Standby::Service::Pingdom::VERSION = '0.04';
BEGIN {
  $App::Standby::Service::Pingdom::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Pingdom Service

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
use Try::Tiny;
use Pingdom::Client;

# extends ...
extends 'App::Standby::Service';
# has ...
has 'pingdom_contact_ids' => (
    'is'    => 'rw',
    'isa'   => 'ArrayRef',
    'lazy'  => 1,
    'builder'   => '_init_pingdom_contact_ids',
);

has 'pingdom' => (
    'is'    => 'rw',
    'isa'   => 'Pingdom::Client',
    'lazy'  => 1,
    'builder' => '_init_pingdom',
);
# with ...
# initializers ...
sub _init_pingdom_contact_ids {
    my $self = shift;

    return $self->_config_values($self->name().'_contact_id');
}

sub _init_pingdom {
    my $self = shift;

    my $username = $self->_config_values($self->name().'_username')->[0];
    my $password = $self->_config_values($self->name().'_password')->[0];
    my $apikey = $self->_config_values($self->name().'_apikey')->[0];

    my $Pingdom = Pingdom::Client::->new({
        'username' => $username,
        'password' => $password,
        'apikey' => $apikey,
    });

    return $Pingdom;
}

# your code here ...
sub _update {
    my $self = shift;
    my $user_ref = shift;

    # set the contact number for each listed contact to the first person
    # in the user list (remember: the first person always is the one currently
    # on duty)
    foreach my $contact_id (@{$self->pingdom_contact_ids()}) {
        try {
            my $status = $self->pingdom()->contact_modify($contact_id, {
                'cellphone' => $user_ref->[0]->{'cellphone'},
                'countrycode' => 49,
                'countryiso'  => 'DE',
            });
            if($status) {
                $self->logger()->log( message => "Successfully updated pingdom contact id $contact_id", level => 'debug', );
            } else {
                $self->logger()->log(
                                    message => "Failed to update pingdom contact id $contact_id. Error: ".
                                     $self->pingdom()->lasterror()->{'statuscode'}.' - '.
                                     $self->pingdom()->lasterror()->{'statusdesc'}.' - '.
                                     $self->pingdom()->lasterror()->{'errormessage'},
                                    level => 'error',
                                    );
            }
        } catch {
            $self->logger()->log( message => "Failed to update contact id ".$contact_id. " w/ error: ".$_, level => 'warning', );
        };
    }

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Service::Pingdom - Pingdom Service

=head1 NAME

App::Standby::Service::Pingdom - Pingdom Service

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
