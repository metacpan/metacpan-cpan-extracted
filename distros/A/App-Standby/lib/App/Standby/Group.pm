package App::Standby::Group;
$App::Standby::Group::VERSION = '0.04';
BEGIN {
  $App::Standby::Group::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Core logic

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
# use Data::Dumper;
use Try::Tiny;

# extends ...
extends 'App::Standby';
# has ...
has 'services' => (
    'is'    => 'rw',
    'isa'   => 'HashRef',
    'lazy'  => 1,
    'builder' => '_init_services',
);

has 'group_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 1,
);

has 'name' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 1,
);
# with ...
# initializers ...
sub _init_services {
    my $self = shift;

    my %want_sv;
    my %has_sv;
    my $sql = 'SELECT id,name,class,desc FROM group_services WHERE group_id = ?';
    my $sth = $self->dbh()->prepexec($sql,$self->group_id());
    if(!$sth) {
        $self->logger()->log( message => 'Failed to get required services from DB due to SQL error: '.$self->dbh()->errstr, level => 'error', );
        return \%has_sv;
    }
    while( my ($sv_id, $sv_name, $sv_class, $sv_desc) = $sth->fetchrow_array()) {
        $want_sv{$sv_name}->{'id'} = $sv_id;
        $want_sv{$sv_name}->{'class'} = 'App::Standby::Service::'.$sv_class;
        $want_sv{$sv_name}->{'desc'} = $sv_desc;
    }
    $sth->finish();

    # try to load each requested service
    foreach my $sv_name ( sort keys %want_sv) {
        my $sv_class = $want_sv{$sv_name}->{'class'};
        my $sv_desc  = $want_sv{$sv_name}->{'desc'};
        my $load_result = $self->_load_class($sv_class);
        if($load_result ne $sv_class) {
            $self->logger()->log( message => 'Failed to load required class: '.$sv_class.' w/ error: '.$load_result, level => 'error', );
            next;
        }
        try {
            my $Service = $sv_class->new({
                'name'      => $sv_name,
                'description' => $sv_desc,
                'group_id'  => $self->group_id(),
                'dbh'       => $self->dbh(),
                'logger'    => $self->logger(),
            });
            $has_sv{$sv_name} = $Service;
            $self->logger()->log( message => "Initialized $sv_name service for ".$self->name().' ('.$self->group_id().')', level => 'debug', );
        } catch {
            $self->logger()->log( message => "Failed to init $sv_name service for ".$self->name().' ('.$self->group_id().'):'.$_, level => 'warning', );
        };
    }

    return \%has_sv;;
}

# your code here ...
sub _config_values {
    my $self = shift;
    my $key = shift;

    return $self->SUPER::_config_values($key, $self->group_id());
}

sub _update_services {
    my $self = shift;
    my $contact_ref = shift;

    my $count = 0;
    foreach my $name (sort keys %{$self->services()}) {
        my $service = $self->services()->{$name};
        $self->logger()->log( message => "Service: ".$name.' starting ...', level => 'debug', );
        try {
            if($service->update($contact_ref)) {
                $self->logger()->log( message => "Updated service ".$name, level => 'debug', );
                $count++;
            } else {
                $self->logger()->log( message => "Failed to update service ".$name, level => 'warning', );
            }
        } catch {
            $self->logger()->log( message => "Failed to update service ".$name.'. Error: '.$_, level => 'warning', );
        };
        $self->logger()->log( message => "Service: ".$name.' done.', level => 'debug', );
    }

    return $count;
}

sub set_janitor {
    my $self = shift;
    my $contact_id = shift;

    my $contact_ref = $self->get_contacts();
    # set the last janitor as the last person in the list, so the chances of being notified
    # are the least for the last janitor
    push @$contact_ref, shift @$contact_ref;
    # put the new janitor on the first place, leave everything else as it was before
    # This didn't work: my @new_users = (grep { $_->{'id'} == $contact_id } @$contact_ref, grep { $_->{'id'} != $contact_id } @$contact_ref);
    my @l1 = grep { $_->{'id'} == $contact_id } @$contact_ref;
    my @l2 = grep { $_->{'id'} != $contact_id } @$contact_ref;
    my @new_contacts = (@l1, @l2);
    #$self->logger()->log( message => "New Ordering: ".Dumper(\@new_users), level => 'debug', );

    # Example:
    # Current queue: Jim (on duty), Jon, Paul, Dave
    # Paul wants to be the new janitor
    # Push Jim to the last position:
    # Jon, Paul, Dave, Jim
    # Push Paul to the first position:
    # Paul, Jon, Dave, Jim

    if($self->_update_services($self->_set_ordering(\@new_contacts))) {
        $self->logger()->log( message => "Updated all services", level => 'debug', );
    } else {
        $self->logger()->log( message => "Failed to update all services", level => 'debug', );
    }

    return \@new_contacts;
}

sub _set_ordering {
    my $self = shift;
    my $contact_ref = shift;

    my $sql = 'UPDATE contacts SET ordinal = ? WHERE group_id = ?';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => "Query prepare ($sql) failed w/ error: ".$self->dbh()->errstr, level => 'error', );
        return;
    }
    if(!$sth->execute(0,$contact_ref->[0]->{'group_id'})) {
        $self->logger()->log( message => "Query execute ($sql) failed w/ error: ".$sth->errstr, level => 'error', );
    }
    $sth->finish();

    $sql = 'UPDATE contacts SET ordinal = ? WHERE id = ?';
    $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => "Query prepare ($sql) failed w/ error: ".$self->dbh()->errstr, level => 'error', );
        return;
    }

    my $ordinal = 1;
    foreach my $user (@$contact_ref) {
        if(!$sth->execute($ordinal++,$user->{'id'})) {
            $self->logger()->log( message => "Query execute ($sql) failed w/ error: ".$sth->errstr, level => 'error', );
        }
    }
    $sth->finish();

    $contact_ref = $self->get_contacts();

    return $contact_ref;
}


sub enable_contact {
    my $self = shift;
    my $contact_id = shift;

    if($self->_trigger_contact($contact_id,1)) {
        if($self->_update_services($self->_set_ordering($self->get_contacts()))) {
            return 1;
        } else {
            return;
        }
    } else {
        return;
    }
}


sub disable_contact {
    my $self = shift;
    my $contact_id = shift;

    if($self->_trigger_contact($contact_id,0)) {
        if($self->_update_services($self->_set_ordering($self->get_contacts()))) {
            return 1;
        } else {
            return;
        }
    } else {
        return;
    }
}

sub _trigger_contact {
    my $self = shift;
    my $contact_id = shift;
    my $is_enabled = shift || 0;

    my $sql = 'UPDATE contacts SET is_enabled = ?, ordinal = ? WHERE id = ?';
    my $sth = $self->dbh()->prepare($sql);

    if(!$sth) {
        # prepare failed
        return;
    }

    if(!$sth->execute($is_enabled,9999,$contact_id)) {
        # update failed
        return;
    } else {
        return 1;
    }
}


sub get_contacts {
    my $self = shift;
    my $all  = shift;

    my @users = ();

    my $sql = 'SELECT id,name,cellphone,ordinal FROM contacts WHERE group_id = ? AND ordinal > 0';
    if(!$all) {
        $sql .= ' AND is_enabled = 1';
    }
    $sql .= ' ORDER BY ordinal';
    my $sth = $self->dbh()->prepare($sql);
    if(!$sth) {
        $self->logger()->log( message => 'Failed to prepare SQL '.$sql.' w/ error: '.$self->dbh()->errstr, level => 'error', );
        return \@users;
    }

    if(!$sth->execute($self->group_id())) {
        $self->logger()->log( message => 'Failed to execute stmt w/ error: '.$sth->errstr, level => 'error', );
        return \@users;
    }

    while(my ($id,$name,$cellphone,$ordinal) = $sth->fetchrow_array()) {
        push(@users, {
            'id'            => $id,
            'group_id'      => $self->group_id(),
            'name'          => $name,
            'cellphone'     => $cellphone,
            'ordinal'       => $ordinal,
        });
        $self->logger()->log( message => 'User: '.$name, level => 'debug', );
    }
    $sth->finish();

    return \@users;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby::Group - Core logic

=head1 METHODS

=head2 set_janitor

set the person on duty to the top of the list

=head2 enable_contact

Enable the given contact id.

=head2 disable_contact

Disable the given contact id.

=head2 get_contacts

Return an array ref containing all active users in the current group w/ their
current ordering.

If the second argument is true it will return disabled users, too.

=head1 NAME

App::Standby::Group - Core logic

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
