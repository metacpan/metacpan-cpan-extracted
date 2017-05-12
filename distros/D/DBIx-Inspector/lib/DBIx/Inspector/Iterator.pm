package DBIx::Inspector::Iterator;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw/sth callback skip_cb/);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless {%args}, $class;
}

sub next {
    my $self = shift;

    if (my $row = $self->sth->fetchrow_hashref('NAME_uc')) {
        if ($self->skip_cb && $self->skip_cb->($row)) {
            return $self->next();
        }
        $self->callback->($row);
    } else {
        return;
    }
}

sub all {
    my $self = shift;
    my @rows;
    while (my $row = $self->next) {
        push @rows, $row;
    }
    return @rows;
}

1;
__END__

=head1 NAME

DBIx::Inspector::Iterator - iterator for DBIx::Inspector

=head1 DESCRIPTION

Iterator class for L<DBIx::Inspector>. This is very useful for saving memory space.

=head1 METHODS

=over 4

=item my $row = $iter->next();

Get next row.

This method returns row object. Return undef if finished.

=item my @rows = $iter->all;

Get all elements in iterator at once.

=back

=head1 SEE ALSO

L<DBIx::Inspector>

