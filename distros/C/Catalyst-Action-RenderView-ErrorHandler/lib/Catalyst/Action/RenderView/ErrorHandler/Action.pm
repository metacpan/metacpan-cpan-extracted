package Catalyst::Action::RenderView::ErrorHandler::Action;
{
  $Catalyst::Action::RenderView::ErrorHandler::Action::VERSION = '0.100166';
}
#ABSTRACT: A Role for any actions that want to react to errors.

use strict;
use warnings;
use Moose::Role;


has 'id' => (is => 'ro', isa => 'Str', required => 1);


has 'ignore_path' => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    init_arg => 'ignorePath',
    predicate => 'has_ignore_path',
);


sub ignore {
    my ( $self, $path ) = @_;
    return unless $self->has_ignore_path;
    my $re = $self->ignore_path;
    $re = qr/\Q$re\E/;
    return $path =~ m/$re/;
}

requires 'perform';

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Catalyst::Action::RenderView::ErrorHandler::Action - A Role for any actions that want to react to errors.

=head1 VERSION

version 0.100166

=head1 SYNOPSIS

    use Moose;

    with 'Catalyst::Action::RenderView::ErrorHandler::Action';

=head2 REQUIRED METHODS

=head3 perform

This method need to be implemented by consuming classes.

It will be called with C<$context>, and thus makes it possible
to access C<< $context->errors >> for instance, include them in an
email or whatnot

=head2 INHERITED METHODS

=head3 meta

Inherited from L<Moose>

=head1 DESCRIPTION

A Role that should be consumed by actions that are implemented

=head1 ATTRIBUTES

=head2 id

Unique name for this action. It is used when refering actions from handlers

=head2 ignore_path

This allows you to set a regexp that we match against the request path. It
comes in handy if your server is targeted by some php exploit nastyness, and
you don't want to (for instance) email everyone every time someone tries to
bruteforce.

=head1 METHODS

=head2 ignore $path

Called before the action is performed to check if we should ignore this action this time or not. Returns true if the action should be ignored (skipped)

=head1 AUTHOR

Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
