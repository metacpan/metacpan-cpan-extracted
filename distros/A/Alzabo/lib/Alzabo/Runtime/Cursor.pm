package Alzabo::Runtime::Cursor;

use strict;
use vars qw($VERSION);

use Alzabo::Runtime;

$VERSION = 2.0;

1;

sub new
{
    shift->_virtual;
}

sub next
{
    shift->_virtual;
}

sub all_rows
{
    shift->_virtual;
}

sub _virtual
{
    my $self = shift;

    my $sub = (caller(1))[3];
    Alzabo::Exception::VirtualMethod->throw
            ( error =>
              "$sub is a virtual method and must be subclassed in " . ref $self );
}

sub reset
{
    my $self = shift;

    $self->{statement}->execute( $self->{statement}->bind );

    $self->{count} = 0;
}

sub count
{
    my $self = shift;

    return $self->{count};
}

sub next_as_hash
{
    my $self = shift;

    my @next = $self->next or return;

    return map { defined $_ ? ( $_->table->name => $_ ) : () } @next;
}

__END__

=head1 NAME

Alzabo::Runtime::Cursor - Base class for Alzabo cursors

=head1 SYNOPSIS

  use Alzabo::Runtime::Cursor;

=head1 DESCRIPTION

This is the base class for cursors.

=head1 METHODS

=head2 new

Virtual method.

=head2 all_rows

Virtual method.

=head2 reset

Resets the cursor so that the next C<next> call will return the first
row of the set.

=head2 count

Returns the number of rows returned by the cursor so far.

=head2 next_as_hash

Returns the next row or rows in a hash, where the hash key is the
table name and the hash value is the row object.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
