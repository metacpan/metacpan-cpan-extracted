package DBomb::Meta::HasA;

=head1 NAME

DBomb::Meta::HasA - One side of a one-to-many relationship.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(one_to_many), ## The relationship object
                  qw(attr),     ## The accessor
                ];

## new HasA($one_to_many, $opts)
sub init
{
    my ($self, $one_to_many, $opts) = @_;
    $opts ||= {};

        assert(2 <= @_ && @_ <= 3, 'parameter count');
        assert(UNIVERSAL::isa($one_to_many,'DBomb::Meta::OneToMany'), 'HasA->new requires OneToMany');

    $self->one_to_many($one_to_many);
    $self->attr($opts->{'attr'} || join(q//, "_dbo_has_a_attr: ",
                $one_to_many->many_key->table_info->name, "(", 
                join(', ', @{$one_to_many->many_key->column_names}), ") =>",
                $one_to_many->one_key->table_info->name, "(", 
                join(', ', @{$one_to_many->one_key->column_names}), ") =>",
                ));

    ## Register with table_info
    push @{$one_to_many->many_table_info->has_as}, $self;
}

sub resolve
{
    my $self = shift;
    return 1;
}

1;
__END__

