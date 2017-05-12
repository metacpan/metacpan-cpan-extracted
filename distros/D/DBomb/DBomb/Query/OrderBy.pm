package DBomb::Query::OrderBy;

=head1 NAME

DBomb::Query::OrderBy - An ORDER BY clause.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(names)],
    'boolean' => [qw(is_desc)],
    ;

## new OrderBy([cols,...])
## new OrderBy(cols,...)
sub init {
    my $self = shift;
    assert(@_ > 0, 'valid parameters');
    assert(@_ == 1 ? (ref($_[0])? ref($_[0]) eq 'ARRAY' : 1) : 1, 'valid parameters');
    $self->names([]);
    $self->append(@_);
}

sub append {
    my $self = shift;

    if (UNIVERSAL::isa($_[0],__PACKAGE__)){
        push @{$self->names}, @{$_[0]->names};
    }
    elsif (ref($_[0]) eq 'ARRAY'){
        push @{$self->names}, @{$_->[0]}
    }
    else {
        push @{$self->names}, @_;
    }
}

sub asc {
    my $self = shift;
    assert(@_ == 0, 'asc takes no arguments');
    $self->is_desc(0);
}

sub desc {
    my $self = shift;
    assert(@_ == 0, 'desc takes no arguments');
    $self->is_desc(1);
}

sub sql {
    my ($self, $dbh) = @_;
    my $names = $self->names;
    return '' unless @$names;
    return join(",", @$names) . ($self->is_desc ? ' DESC ' : ' ASC ');
}


1;
__END__

=head1 DESCRIPTION

=head1 METHODS

=over

=item asc()

Corresponds to SQL ORDER BY ASC

=item desc()

Corresponds to SQL ORDER BY DESC

=back

=cut

