package DBomb::Query::Expr;

=head1 NAME

DBomb::Query::Expr - Abstraction of a WHERE or ON clause.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.11 $';

use Carp::Assert;
use DBomb::Util qw(ctx_0 is_same_value);
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(_expr bind_values)],
    ;

## Export the '_expr()' routine
use base qw(Exporter);
our %EXPORT_TAGS = ('all' => [qw(expr)]);
Exporter::export_ok_tags('all');

## new Expr()
## new Expr(+{where_expr}, @bind_values)
## new Expr([where_expr], @bind_values)
## new Expr($plain_sql, @bind_values)
sub init
{
    my $self = shift;
    $self->_expr([]);
    $self->bind_values([]);

    return unless @_;

    my $e = shift;
    push @{$self->bind_values}, @_ if @_;

    if (ref($e) eq 'HASH'){
        $self->_expr([$e]);
    }
    elsif (UNIVERSAL::isa($e,__PACKAGE__)){
        $self->append($e);
    }
    elsif (not ref($e)) {
        $self->_expr([$e]);
    }
    else {
        $self->_expr($e);
    }
}

## subroutine -- NOT a method.
## Same as new DBomb::Query::Expr(@_)
sub expr
{
    new DBomb::Query::Expr(@_)
}

sub append
{
    my $self = shift;
    return $self->and(@_);
}

## and( EXPR, @bind_values)
sub and
{
    my ($self,$_expr) = (shift,shift);
    if(not UNIVERSAL::isa($_expr,__PACKAGE__)){
        $_expr = $self->new($_expr,@_);
    }
    push @{$self->_expr}, ' AND ' if $self->is_not_empty;
    push @{$self->_expr},  @{$_expr->_expr};
    push @{$self->bind_values}, @{$_expr->bind_values};
    return $self;
}

## or( EXPR, @bind_values)
sub or
{
    my ($self,$_expr) = (shift,shift);
    if(not UNIVERSAL::isa($_expr,__PACKAGE__)){
        $_expr = $self->new($_expr,@_);
    }
    push @{$self->_expr}, ' OR ' if @{$self->_expr};
    push @{$self->_expr},  @{$_expr->_expr};
    push @{$self->bind_values}, @{$_expr->bind_values};
    return $self;
}


## syntax like DBIx::Abstract
sub walk_expr
{
    my ($self,$e,$dbh) = @_;
    return 'NULL' if not defined $e;
    return '?' if $e eq DBomb::Query->PlaceHolder;
    return $e->walk_expr($e->_expr,$dbh) if UNIVERSAL::isa($e,__PACKAGE__);
    return $e if not ref $e;

    if (UNIVERSAL::isa($e,'ARRAY')){
        my $sql = join ' ', map { $self->walk_expr($_,$dbh) } @$e;
        return "($sql)";
    }

    if (ref($e) eq 'HASH'){
        my $sql = join ' AND ',  map {
                # Promote scalar values to '=' operations.
                $e->{$_} = [ '=', $e->{$_}] if not ref $e->{$_};

                join(' ', $_, map{$self->walk_expr($_,$dbh)} @{$e->{$_}})

            } keys %$e;
        return $sql;
    }
    die "Unrecognized expression $e";
}

sub sql
{
    my ($self,$dbh) = @_;
    return ctx_0('') unless defined($self->_expr) && @{$self->_expr};
    return ctx_0($self->_expr,@{$self->bind_values}) if not ref $self->_expr; ## plain sql... actually, the ctor should have ruled this out.

    return ctx_0($self->walk_expr($self->_expr,$dbh), @{$self->bind_values});
}

sub is_not_empty { scalar @{shift->_expr} }
sub is_empty { not shift->is_not_empty }


1;
__END__

