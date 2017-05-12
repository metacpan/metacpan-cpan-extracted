package Buffer::Transactional::Buffer;
use Moose::Role;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

requires 'put';
requires 'as_string';

sub subsume {
    my ($self, $buffer) = @_;
    $self->put( $buffer->as_string );
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Buffer::Transactional::Buffer - A role to represent a buffer

=head1 DESCRIPTION

This is a role to represent our buffer types.

=head1 METHODS

=over 4

=item B<put ( @items )>

This method is required, it is used to add elements to
the buffer.

=item B<as_string>

This method is required, it is used to collapse a buffer
into a string.

=item B<subsume ( $buffer )>

This method has a minimal implementation which simply puts
the results of calling C<to_string> on the C<$buffer> arg
into the local buffer. Feel free to override this if it is
not appropriate, see L<Buffer::Transactional::Buffer::Lazy>
for an example of this.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009, 2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
