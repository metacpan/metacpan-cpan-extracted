package BPM::Engine::Store::ResultSet::ActivityInstance;
BEGIN {
    $BPM::Engine::Store::ResultSet::ActivityInstance::VERSION   = '0.01';
    $BPM::Engine::Store::ResultSet::ActivityInstance::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
extends 'DBIx::Class::ResultSet';

sub active {
    my ($self, @args) = @_;
    $self->search({ completed => \'IS NULL', deferred => \'IS NULL' },
                  { order_by => \'created ASC' })->search(@args);
    }

sub active_or_deferred {
    my ($self, @args) = @_;
    $self->search({ completed => \'IS NULL' },
                  { order_by => \'created ASC' })->search(@args);
    }

sub active_or_completed {
    my ($self, @args) = @_;
    $self->search({ deferred => \'IS NULL' },
                  { order_by => \'created ASC' })->search(@args);
    }

sub deferred {
    my ($self, @args) = @_;
    $self->search({ deferred => \'IS NOT NULL' },
                  { order_by => \'deferred ASC' })->search(@args);
    }

sub completed {
    my ($self, @args) = @_;
    $self->search({ completed => \'IS NOT NULL' },
                  { order_by => \'deferred ASC' })->search(@args);
    }

sub TO_JSON {
    my $rs = shift;
    my @instances = ();
    while(my $row = $rs->next) {
        my $instance = $row->TO_JSON;
        $instance->{uri} = '/wfcs/activities/' . $row->id;
        push(@instances, $instance);
        }
    
    return {
        total     => $rs->pager->total_entries, # scalar @instances, totalResultsAvailable
        row_count => $rs->pager->entries_on_this_page, # totalResultsReturned
        page      => $rs->pager->current_page, # firstResultPosition
        results   => [ @instances ],
        };
    }

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
__END__

