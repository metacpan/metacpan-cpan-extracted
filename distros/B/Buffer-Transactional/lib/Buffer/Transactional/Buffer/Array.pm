package Buffer::Transactional::Buffer::Array;
use Moose;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

has '_buffer' => (
    traits  => [ 'Array' ],
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
    handles => {
        'put'       => 'push',
        'as_string' => [ 'join', '' ],
        '_flatten'  => 'elements',
    }
);

# *sigh* Moose
with 'Buffer::Transactional::Buffer';

sub subsume {
    my ($self, $buffer) = @_;
    $self->put( $buffer->_flatten );
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Buffer::Transactional::Buffer::Array - An arrayref based buffer

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
