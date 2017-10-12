package Datahub::Factory::Fixer::Condition;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Datahub::Factory;
use Moo;
use Catmandu;
use Catmandu::Util qw(data_at);
use namespace::clean;

has fixer        => (is => 'ro', required => 1);
has fixer_module => (is => 'lazy' );

sub _build_fixer_module {
    my $self = shift;
    return $self->fixer->{'plugin'};
}

sub get_fixers {
    my ($self, $args) = @_;
    my $fixers;

    # Init the 'default' fixer if no conditionals are set in configuration.

    if (!defined($self->fixer->{'conditionals'})) {
        my $file_name = $self->fixer->{$self->fixer_module}->{'options'}->{'file_name'};
        $fixers->{'default'} = Datahub::Factory->fixer($self->fixer_module)->new(
            'file_name' => $file_name
        );

        return $fixers;
    }

    # Init conditional fixers if set

    my $conditionals = $self->fixer->{'conditionals'};
    foreach my $conditional (keys %$conditionals) {
        $fixers->{$conditional} = Datahub::Factory->fixer($self->fixer_module)->new(
           'file_name' => $conditionals->{$conditional}->{'options'}->{'file_name'}
        );
    }

    return $fixers;
}

sub fix_module {
    my ($self, $fixers, $item) = @_;

    # Fetch the 'default' fixer if no conditional fixers were defined

    if (defined($fixers->{'default'})) {
        return $fixers->{'default'};
    }

    # Fetch the appropriate conditional fixer

    my $condition_path = $self->fixer->{$self->fixer_module}->{'options'}->{'condition_path'};
    my $condition_r = data_at($condition_path, $item);

    $condition_r //= 'Undefined condition';

    if ($condition_r eq 'Undefined condition') {
        Catmandu::BadVal->throw(
            'message' => sprintf('Condition path "%s" did not yield a value from item.', $condition_path)
        );
    }

    my $conditionals = $self->fixer->{'conditionals'};
    foreach my $conditional (keys %$conditionals) {
        my $condition_l = $conditionals->{$conditional}->{'options'}->{'condition'};

        if ($condition_l eq $condition_r) {
            return $fixers->{$conditional};
        }
    }

    Catmandu::BadVal->throw(
        'message' => sprintf('Fixer condition "%s" did not yield a defined fixer', $condition_r)
    );
}

1;

__END__

=pod

=head1 NAME

Datahub::Factory::Fixer::Condition - Load fixer plugins based on a condition

=head1 SYNOPSIS

=head1 DESCRIPTION

This module loads and selects a fixer module during runtime. Depending on the
used pipeline configuration either a default fixer is loaded, or a fixer is
picked from a set of pre-defined 'conditional' fixers based on a condition which
matches to a value in a record field.

This mechanism allows data managers to apply multiple fixes selectively to a
set of records.

=head2 Default configuration

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    file_name = '/opt/datahub-factory/transformer.fix'

=head2 Conditional configuration

Given a set of records structured like this:

    [
        {
            'object_number' => '1234',
            'institution' => 'Museum of Foo'
        },
        {
            'object_number' => '2345',
            'institution' => 'Museum of Bar'
        }
    ]

Then let the configuration be:

    [Fixer]
    plugin = Fix

    [plugin_fixer_Fix]
    condition_path = "institution"
    fixers = FOO, BAR

    [plugin_fixer_FOO]
    condition = 'Museum of Foo'
    file_name = '/opt/datahub-factory/transformer_foo.fix'

    [plugin_fixer_BAR]
    condition = 'Museum of Bar'
    file_name = '/opt/datahub-factory/transformer_bar.fix'

=head2 Errors

The condition_path is used to fetch a value from the record which is currently
being processed. If no value could be retrieved, the module will throw an error
and the factory will skip to the next record.

If a value was found, but doesn't match with the condition property of each of
the defined conditional fixers, the module will throw an error
and the factory will skip to the next record.

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>
Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut

