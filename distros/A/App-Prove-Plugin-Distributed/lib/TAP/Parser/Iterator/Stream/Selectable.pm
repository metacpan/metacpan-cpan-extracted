package TAP::Parser::Iterator::Stream::Selectable;
use strict;
use vars (qw($VERSION @ISA));

use TAP::Parser::Iterator::Stream ();
@ISA = 'TAP::Parser::Iterator::Stream';

=head1 NAME

TAP::Parser::Iterator::Stream::Selectable - Stream TAP from an L<IO::Handle> or a GLOB.

=head1 VERSION

Version 0.01

=cut

$VERSION = '0.01';

sub _initialize {
    my ( $self, $args ) = @_;
    unless ( $args->{handle} ) {
        die "handle argument must be specified.\n";
    }
    my $chunk_size = delete $args->{_chunk_size} || 65536;
    return unless ( $self->SUPER::_initialize( $args->{handle} ) );
    $self->{out}        = $args->{handle};
    $self->{err}        = $args->{handle};
    $self->{sel}        = IO::Select->new( $args->{handle} );
    $self->{pid}        = '';
    $self->{exit}       = undef;
    $self->{chunk_size} = $chunk_size;
    return $self;
}

=head3 C<get_select_handles>

Return a list of filehandles that may be used upstream in a select()
call to signal that this Iterator is ready. Iterators that are not
handle based should return an empty list.

=cut

sub get_select_handles {
    my $self = shift;
    return grep $_, ( $self->{out}, $self->{err} );
}

1;

__END__

##############################################################################
