package DBomb::Query::GroupBy;

=head1 NAME

DBomb::Query::GroupBy - An ORDER BY clause.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.2 $';

use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [qw(names)],
    ;

## new GroupBy([cols,...])
## new GroupBy(cols,...)
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

sub sql {
    my ($self, $dbh) = @_;
    my $names = $self->names;
    return '' unless @$names;
    return join(",", @$names);
}


1;
__END__

