package DBomb::Meta::Key;

=head1 NAME

DBomb::Meta::Key - An vector of columns.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.13 $';

use Tie::IxHash;
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(columns)], # IxHash{ column_name => column_info }
    'boolean' => [qw(is_pk)],
    ;

## init( $cols_list, $opts)
sub init
{
    my ($self, $cols_list, $opts) = @_;
    my %h;
    tie %h, 'Tie::IxHash';
    $self->columns(\%h);

    $cols_list = [$cols_list] if ref($cols_list) ne 'ARRAY';
    for my $cinfo (@$cols_list){
        $self->columns->{$cinfo->name} = $cinfo;
    }

    ## Register with table info
    push @{$self->table_info->keys}, $self;
}

sub table_info
{
    my $self = shift;
        assert(@_ == 0);
    tied(%{$self->columns})->Values(0)->table_info;
}

sub columns_list
{
    my $self = shift;
        assert(@_ == 0);
    [values %{$self->columns}]
}

sub column_names
{
    my $self = shift;
        assert(@_ == 0);
    [keys %{$self->columns}]
}

sub column_count
{
    my $self = shift;
        assert(@_ == 0);
    tied(%{$self->columns})->Length;
}

sub resolve
{
    ## No action.
    return 1;
}

## returns a where clause optionally with bind values
## mk_where(@bind_values)
sub mk_where
{
    my $self = shift;
    my $where =  new DBomb::Query::Expr();

    for (values %{$self->columns}){
        $where->and(+{$_->fq_name => '?'});
    }
    push @{$where->bind_values}, @_ if @_;

    return $where;
}


1;
__END__

