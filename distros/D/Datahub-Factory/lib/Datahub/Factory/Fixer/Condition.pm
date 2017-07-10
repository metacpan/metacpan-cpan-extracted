package Datahub::Factory::Fixer::Condition;

use strict;
use warnings;

use Datahub::Factory;

use Moo;
use Catmandu;
use Catmandu::Util qw(data_at);
use namespace::clean;

has options         => (is => 'ro', required => 1);
has fixers => (is => 'ro', is => 'lazy');

sub _build_fixers {
    my ($self, $args) = @_;
    my $fixers;
    my $fix_file_name;

    if (!defined($self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'condition'})) {
        $fix_file_name = $self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'file_name'};

        $fixers->{'default'} = Datahub::Factory->fixer($self->options->{'fixer'})->new(
            'file_name' => $fix_file_name
        );

        return $fixers;
    }

    # @todo
    #   Move this to PipeLineConfig.pm
    if (
        !defined($self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'fixers'}) ||
        scalar @{$self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'fixers'}} == 0
        ) {
        Catmandu::BadArg->throw(
            'message' => sprintf('Missing or empty "fixers" option in [plugin_fixer_%s]', $self->options->{'fixer'})
        );
    }

    foreach my $fixer (@{$self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'fixers'}}) {
        $fixer = sprintf('fixer_%s', $fixer);

        # @todo
        #   Move this to PipeLineConfig.pm
        if (!defined($self->options->{$fixer}->{'condition'})) {
            Catmandu::BadArg->throw(
                'message' => sprintf('Missing "condition" option in [plugin_%s]', $fixer)
            );
        }

        $fix_file_name = $self->options->{$fixer}->{'file_name'};

        # @todo
        #   Move this to PipeLineConfig.pm
        if (!defined($fix_file_name) || $fix_file_name eq '') {
            Catmandu::BadArg->throw(
                'message' => sprintf('Missing "file_name" option in [plugin_%s]', $fixer)
            );
        }

        $fixers->{$fixer} = Datahub::Factory->fixer($self->options->{'fixer'})->new(
           'file_name' => $fix_file_name
        );
    }

    return $fixers;
}

sub fix_module {
    my ($self, $item) = @_;

    if (defined($self->fixers->{'default'})) {
        return $self->fixers->{'default'};
    }

    my $condition = data_at($self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'condition'}, $item);

    foreach my $fixer (@{$self->options->{sprintf('fixer_%s', $self->options->{'fixer'})}->{'fixers'}}) {
        # @todo
        #   Move this to PipeLineConfig.pm
        if (!defined($self->options->{$fixer}->{'condition'})) {
            Catmandu::BadArg->throw(
                'message' => sprintf('Missing "condition" option in [plugin_%s]', $fixer)
            );
        }

        if ($self->options->{sprintf('%s', $fixer)}->{'condition'} eq $condition) {
            return $self->fixers->{$fixer};
        }
    }

    # @todo
    #   return false or throw an exception
}

1;

__END__

