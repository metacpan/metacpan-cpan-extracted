package DataFlow::ProcWrapper;

use strict;
use warnings;

# ABSTRACT: Wrapper around a processor

our $VERSION = '1.121830';    # VERSION

use Moose;
with 'DataFlow::Role::Processor';

use Moose::Autobox;
use namespace::autoclean;

use DataFlow::Item;
use DataFlow::Types qw(Processor);

has 'input_chan' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'default',
);

has 'output_chan' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->input_chan },
);

has 'on_proc' => (
    is       => 'ro',
    isa      => 'Processor',
    required => 1,
    init_arg => 'wraps',
    coerce   => 1,
);

sub _itemize_response {
    my ( $self, $input_item, @response ) = @_;
    return ($input_item) unless @response;
    return @{
        @response->map(
            sub { $input_item->clone->set_data( $self->output_chan, $_ ) }
        )
      };
}

sub process {
    my ( $self, $item ) = @_;

    return unless defined $item;
    if ( ref($item) eq 'DataFlow::Item' ) {
        my $data = $item->get_data( $self->input_chan );
        return ($item) unless $data;
        return $self->_itemize_response( $item,
            $self->on_proc->process($data) );
    }
    else {
        my $data       = $item;
        my $empty_item = DataFlow::Item->new();
        return ($empty_item) unless $data;
        return $self->_itemize_response( $empty_item,
            $self->on_proc->process($data) );
    }
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=encoding utf-8

=head1 NAME

DataFlow::ProcWrapper - Wrapper around a processor

=head1 VERSION

version 1.121830

=head1 SYNOPSIS

    use DataFlow::ProcWrapper;
    use DataFlow::Item;

	my $wrapper = DataFlow::ProcWrapper->new( wraps => sub { lc } );
	my $item = DataFlow::Item->itemize( 'default', 'WAKAWAKAWAKA' );
	my @result = $wrapper->process($item);
	# $result[0]->get_data('default') equals to 'wakawakawaka'

=head1 DESCRIPTION

This class C<DataFlow::ProcWrapper> consumes the L<DataFlow::Role::Processor>
role, but this is not a "common" processor and it should not be used as such.
Actually, it is supposed to be used internally by DataFlow alone, so in theory,
if not in practice, we should be able to ignore its existence.

C<ProcWrapper> will, as the name suggests, wraps around a processor (read
a Proc, a DataFlow, a naked sub or a named processor), and provides a layer
of control on the input and output channels.

=head1 ATTRIBUTES

=head2 input_chan

Name of the input channel. The L<DataFlow::Item> may carry data in distinct
"channels", and here we can select which channel we will take the data from.
If not specified, it will default to the literal string C<< 'default' >>.

=head2 output_chan

Similarly, the output channel's name. If not specified, it will default to
the same channel used for input.

=head1 METHODS

=head2 process

This works like the regular C<process()> method in a processor, except that
it expects to receive an object of the type L<DataFlow::Item>.

Additionaly, one can pass a random scalar as argument, and add a
second argument that evaluates to a true value, and the scalar argument will
be automagically "boxed" into a C<DataFlow::Item> object.

Once the data is within a C<DataFlow::Item>, data will be pulled from the
specified channel, will call the wrapped processor's C<process()> method.

It will always return an array with one or more elements, all of them of the
C<DataFlow::Item> type.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<DataFlow|DataFlow>

=back

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__


