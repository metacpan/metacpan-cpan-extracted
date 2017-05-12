package DataFlow::Role::ProcPolicy;

use strict;
use warnings;

# ABSTRACT: A role that defines how to use proc-handlers

our $VERSION = '1.121830';    # VERSION

use Moose::Role;

use namespace::autoclean;
use Scalar::Util 'reftype';

has 'handlers' => (
    'is'      => 'ro',
    'isa'     => 'HashRef[CodeRef]',
    'lazy'    => 1,
    'builder' => '_build_handlers',
);

sub _build_handlers {
    return {};
}

has 'default_handler' => (
    'is'       => 'ro',
    'isa'      => 'CodeRef',
    'required' => 1,
    'builder'  => '_build_default_handler',
);

sub _build_default_handler {
    return;
}

sub apply {
    my ( $self, $p, $item ) = @_;
    my $type = _param_type($item);

    my $handler =
      exists $self->handlers->{$type}
      ? $self->handlers->{$type}
      : $self->default_handler;

    return $handler->( $p, $item );
}

sub _param_type {
    my $p = shift;
    my $r = reftype($p);
    return $r ? $r : 'SVALUE';
}

sub _make_apply_ref {
    my ( $self, $p ) = @_;
    return sub { $self->apply( $p, $_ ) };
}

sub _run_p {
    my ( $p, $item ) = @_;
    local $_ = $item;
    return $p->();
}

sub _nop_handle {
    my @param = @_;      # ( p, item )
    return $param[1];    # nop handle: ignores p, returns item itself
}

sub _handle_svalue {
    my ( $p, $item ) = @_;
    return _run_p( $p, $item );
}

sub _handle_scalar_ref {
    my ( $p, $item ) = @_;
    my $r = _run_p( $p, $$item );
    return \$r;
}

sub _handle_array_ref {
    my ( $p, $item ) = @_;

    #use Data::Dumper; warn 'handle_array_ref :: item = ' . Dumper($item);
    my @r = map { _run_p( $p, $_ ) } @{$item};
    return [@r];
}

sub _handle_hash_ref {
    my ( $p, $item ) = @_;
    my %r = map { $_ => _run_p( $p, $item->{$_} ) } keys %{$item};
    return {%r};
}

sub _handle_code_ref {
    my ( $p, $item ) = @_;
    return sub { _run_p( $p, $item->() ) };
}

1;



__END__
=pod

=encoding utf-8

=head1 NAME

DataFlow::Role::ProcPolicy - A role that defines how to use proc-handlers

=head1 VERSION

version 1.121830

=head2 apply P ITEM

Applies this policy to the data ITEM using function P.

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

