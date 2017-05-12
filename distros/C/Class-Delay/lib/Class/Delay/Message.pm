use strict;
package Class::Delay::Message;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( package method args is_trigger ));

sub resume {
    my $self = shift;
    my @args = @{ $self->args };
    my $invocant = shift @args;
    my $method   = $self->method;
    $invocant->$method( @args );
}

1;
__END__

=head1 NAME

Class::Delay::Message - class that represents a delayed message

=head1 METHODS

=head2 package

The package that the delaying method was installed into.

=head2 method

The method being called

=head2 args

The arguments the method was called with.

=head2 is_trigger

True if the Message is a release method.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
