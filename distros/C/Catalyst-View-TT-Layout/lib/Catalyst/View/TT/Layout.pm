package Catalyst::View::TT::Layout;

use strict;
use base 'Catalyst::View::TT';
use NEXT;

our $VERSION = '0.01';

sub process {
    my ( $self, $c ) = @_;

	$c->stash->{template_layout} ||= [];
	my @layouts = ( @{$c->stash->{template_layout}}, $c->stash->{template} );
	$c->stash->{LAYOUTS} = \@layouts;
	$c->stash->{template} = shift @layouts;
    return $self->NEXT::process($c);
}

=head1 NAME

Catalyst::View::TT::Layout - Layout TT template processing

=head1 SYNOPSIS

in the appliction:

 $c->stash->{template_layout} = [ 'main_layout.tpl', 'sub_layout.tpl' ];

in the template files ('main_layout.tpl' and 'sub_layout.tpl'):

 [% PROCESS $LAYOUTS.shift %]

=head1 DESCRIPTION

A Layout version of the Catalyst TT view.

=head2 OVERRIDDEN METHODS

=over 4

=item process

Overrides C<process> to let template could be layout.

=back

=cut

=head1 SEE ALSO

L<Catalyst>. L<Catalyst::View::TT>

=head1 AUTHOR

Chunzi, C<chunzi@chunzi.org>

=head1 THANK YOU

SRI, for writing the awesome Catalyst framework

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
