package DBomb::Meta::HasQuery;

=head1 NAME

DBomb::Meta::HasQuery - A column based on a Query object.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.3 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(query), ## The query object
                  qw(attr),  ## The accessor
                  qw(table_info), ## tableinfo object
                  qw(f_table), ## foreign table
                  qw(bind_subs), ## [coderef, coderef,...]
                ];

## new HasQuery($table, $query, [@bind_subs] $opts)
sub init
{
    my ($self, $table, $f_table, $query, $bind_subs, $opts) = @_;
    $opts ||= {};

        assert(5 <= @_ && @_ <= 6, 'parameter count');
        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(UNIVERSAL::isa($table,'DBomb::Meta::TableInfo'), 'HasQuery requires a foreign table info');
        assert(UNIVERSAL::isa($query,'DBomb::Query'), 'HasQuery->new requires DBomb::Query');
        assert(UNIVERSAL::isa($bind_subs, 'ARRAY'));
        for (@$bind_subs){
            assert(UNIVERSAL::isa($_,'CODE'));
        }
        assert(UNIVERSAL::isa($opts, 'HASH'));

    $self->query($query);
    $self->attr($opts->{'attr'} || join(q//, "_dbo_has_query: ", @{$query->column_names}, " $query"));
    $self->table_info($table);
    $self->f_table($f_table);

    $self->bind_subs([]);
    for (@$bind_subs){
        push @{$self->bind_subs}, $_
    }
}

sub resolve
{
    my $self = shift;

    my $t = $self->f_table;
    unless (UNIVERSAL::isa($t, 'DBomb::TableInfo')){
        die "could not resolve HasQuery table_info '$t'" unless defined $self->f_table(DBomb->resolve_table_name(undef,$t));
    }
    return 1;
}

1;
__END__

