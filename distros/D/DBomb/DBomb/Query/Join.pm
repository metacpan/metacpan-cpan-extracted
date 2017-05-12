package DBomb::Query::Join;

=head1 NAME

DBomb::Query::Join - Abstract a join between two DBomb sources.


=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.9 $';

use DBomb::Util qw(ctx_0);
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(left right type on_obj using_list)],
    ;

## new Join($left, $right)
sub init
{
    my $self = shift;

        assert(@_ == 2, 'valid parameters');

    $self->left(shift);
    $self->right(shift);
    $self->type(''); ## inner
    $self->on_obj(new DBomb::Query::Expr());
    $self->using_list([]);
}

sub sql
{
    my ($self, $dbh) = @_;
    my $sql = $self->left->sql($dbh) . ' ' . $self->type . ' JOIN ' . $self->right;

    assert( $self->on_obj->is_not_empty || @{$self->using_list} > 0, "JOIN requires a USING clause or ON clause");

    if ($self->on_obj->is_not_empty){
        my $on_sql   = $self->on_obj->sql($dbh);
        $sql .= " ON $on_sql " if length $on_sql;
    }
    else{
        $sql .= " USING ( ". join(',',@{$self->using_list}) .") ";
    }
    return ctx_0($sql);
}

## on(EXPR, @bind_values)
sub on
{
    my $self = shift;
        assert(@_ && defined($_[0]), "on requires an EXPR");
    $self->on_obj->append(@_);
    return $self;
}

## using([columns...])
sub using
{
    my $self = shift;
        assert(@_ && defined($_[0]), "USING requires a list");
    push @{$self->using_list}, @_;
    return $self;
}

sub bind_values
{
    my $self = shift;
    return $self->on_obj->bind_values;
}

1;
__END__

=head1 DESCRIPTION

This is not the module you are looking for. Move along.
(You probably want the docs for DBomb::Join instead.)

=cut

