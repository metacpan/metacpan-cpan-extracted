package DBomb::Meta::OneToMany;

=head1 NAME

DBomb::Meta::OneToMany - A One to N relationship.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.3 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(one_key),
                  qw(many_key),
                ];

## new OneToMany($one_key, $many_key)
sub init
{
    my ($self,$one_key,$many_key) = @_;

        assert(UNIVERSAL::isa($one_key,'DBomb::Meta::Key'), 'OneToMany->new requires a one_key');
        assert(UNIVERSAL::isa($many_key,'DBomb::Meta::Key'), 'OneToMany->new requires a many_key');

    $self->one_key($one_key);
    $self->many_key($many_key);

    ## TODO: Register with both tables?
}

## return the tableinfo for the "one" end of this relationship
sub one_table_info
{
    my $self = shift;
        assert(@_ == 0);
    $self->one_key->table_info;
}

## return the tableinfo for the "many" end of this relationship
sub many_table_info
{
    my $self = shift;
        assert(@_ == 0);
    $self->many_key->table_info;
}

sub resolve
{
    my $self = shift;
    $self->many_key->resolve && $self->one_key->resolve;
}

1;
__END__

