package Data::Stack;
use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;

    my $self = [];
    if(@_) {
        push(@{ $self }, @_);
    }

    return bless($self, $class);
}

sub peek {
    my $self = shift();

    return $self->get(0);
}

sub clear {
    my $self = shift();

    $#{ $self } = -1;
}

sub get {
    my $self = shift();
    my $index = shift();

    return $self->[$index];
}

sub count {
    my $self = shift();

    return $#{ $self } + 1;
}

sub empty {
    my $self = shift();

    if($self->count() == 0) {
        return 1;
    }

    return 0;
}

sub pop {
    my $self = shift();

    return shift(@{ $self });
}

sub push {
    my $self = shift();

    unshift(@{ $self }, shift());
}

1;
__END__

=head1 NAME

Data::Stack - A Stack!

=head1 SYNOPSIS

  use Data::Stack;
  my $stack = new Data::Stack();

=head1 DESCRIPTION

Quite simple, really.  Just a stack implemented via an array.

=head1 METHODS

=over 4

=item new( [ @ITEMS ] )

Creates a new Data::Stack.  If passed an array, those items are added to the stack.

=item peek()

Returns the item at the top of the stack but does not remove it.

=item get($INDEX)

Returns the item at position $INDEX in the stack but does not remove it.  0 based.

=item count()

Returns the number of items in the stack.

=item empty()

Returns a true value if the stack is empty.  Returns a false value if not.

=item clear()

Completely clear the stack.

=item pop()

Removes the item at the top of the stack and returns it.

=item push($item)

Adds the item to the top of the stack.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

There are various Stack packages out there but none of them seemed simple enough. Here we are!

=head1 AUTHOR

Cory Watson, E<lt>cpan@onemogin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Cory Watson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
