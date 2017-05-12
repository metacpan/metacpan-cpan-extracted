package Buffer::Transactional::Buffer::File;
use Moose;
use Moose::Util::TypeConstraints;

use IO::File;
use Data::UUID;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:STEVAN';

class_type 'IO::File';

has 'uuid' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { Data::UUID->new->create_str },
);

has '_buffer' => (
    is      => 'ro',
    isa     => 'IO::File',
    lazy    => 1,
    default => sub { IO::File->new( (shift)->uuid, 'w' ) },
    handles => {
        'put' => 'print'
    }
);

# *sigh* Moose
with 'Buffer::Transactional::Buffer';

sub as_string {
    my $self = shift;
    $self->_buffer->flush;
    join "" => IO::File->new( $self->uuid, 'r' )->getlines;
}

sub DEMOLISH {
    my $self = shift;
    unlink $self->uuid;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Buffer::Transactional::Buffer::File - A file based buffer

=head1 DESCRIPTION

This buffer will write a file for each buffer it creates and
name it with a UUID. Upon destruction it will cleanup the file.

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
