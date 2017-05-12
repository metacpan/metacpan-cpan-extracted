package Catalyst::Action::Fixup::XHTML;

use Moose;

our $VERSION = '0.05';

extends 'Catalyst::Action';
with 'Catalyst::View::ContentNegotiation::XHTML';

use MRO::Compat;

sub process {} # Make the role happy.

sub execute {
    my $self = shift;
    my ($controller, $c ) = @_;
    my $ret = $self->next::method( @_ );
    $self->process($c);
    return $ret;
}

1;
__END__

=head1 NAME

Catalyst::Action::Fixup::XHTML - Catalyst action which serves application/xhtml+xml content if the browser accepts it.

=head1 SYNOPSIS

    sub end : ActionClass('Fixup::XHTML') {}

=head1 DESCRIPTION

A simple module to use L<Catalyst::View::ContentNegotiation::XHTML>

It's an action because I think it can be used in other views like Mason.

=head1 RenderView

Since Catalyst doesn't support two ActionClass attributes now, you need do follows to make them together.

    sub render : ActionClass('RenderView') { }
    sub end : ActionClass('Fixup::XHTML') {
        my ( $self, $c ) = @_;
        
        $c->forward('render');
    }

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

Tomas Doran for the great L<Catalyst::View::TT::XHTML>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
