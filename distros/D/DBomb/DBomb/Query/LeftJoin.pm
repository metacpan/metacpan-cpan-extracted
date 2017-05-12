package DBomb::Query::LeftJoin;

=head1 NAME

DBomb::Query::LeftJoin - Abstracts a LEFT OUTER JOIN

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.3 $';

use base qw(DBomb::Query::Join);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->type('LEFT');
    return $self;
}


1;
__END__

