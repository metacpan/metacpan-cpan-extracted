package BioX::Workflow::Command::run::Rules::Directives::Types::Stash;

use Moose::Role;
use namespace::autoclean;

use Data::Merger qw(merger);

=head2 stash

This isn't ever used in the code. Its just there incase you want to persist objects across rules

It uses Moose::Meta::Attribute::Native::Trait::Hash and supports all the methods.

        set_stash     => 'set',
        get_stash     => 'get',
        has_no_stash => 'is_empty',
        num_stashs    => 'count',
        delete_stash  => 'delete',
        stash_pairs   => 'kv',

=cut

has 'stash' => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        set_stash    => 'set',
        get_stash    => 'get',
        has_no_stash => 'is_empty',
        num_stashs   => 'count',
        delete_stash => 'delete',
        stash_pairs  => 'kv',
    },
);

sub merge_stash {
    my $self   = shift;
    my $target = shift;

    my $merged_data = merger( $target, $self->stash );
    $self->stash($merged_data);
}

1;
