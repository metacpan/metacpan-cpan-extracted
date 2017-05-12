package Catalyst::Action::RenderView::ErrorHandler::Action::Log;
{
  $Catalyst::Action::RenderView::ErrorHandler::Action::Log::VERSION = '0.100166';
}
#ABSTRACT: A logging action for errors.

use strict;
use warnings;
use Moose;

with 'Catalyst::Action::RenderView::ErrorHandler::Action';
has 'level' => (is => 'ro', isa => 'Str', default => 'error');


sub perform {
    my $self = shift;
    my $c = shift;

    my $level = $self->level;
    foreach my $e (@{ $c->error }) {
        $c->log->$level($e);
    }
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Catalyst::Action::RenderView::ErrorHandler::Action::Log - A logging action for errors.

=head1 VERSION

version 0.100166

=head1 SYNOPSIS

    # In a configuration somewhere:
    error_handler:
        actions:
            - type: Log
              id: log-error
              level: error
        handlers:
            fallback:
                actions:
                    - log-error

=head1 DESCRIPTION

Really a rather useless example of an ErrorHandler action. It uses catalysts
logging facilities to log errors.

=head1 INTERFACE

=head2 INHERITED ACCESSORS

=head3 id

See L<Catalyst::Action::RenderView::ErrorHandler::Action/id>

=head2 ACCESSORS

=head3 level

The log-level this action uses.

=head2 IMPLEMENTED METHODS

=head3 perform

Implemented as a requirement of L<Catalyst::Action::RenderView::ErrorHandler::Action>.

Will be called with the C<$context>, and basicly calles C<< $context->log->$level >> for
every error.

=head2 INHERITED METHODS

=head3 meta

Inherited from Moose.

=head1 AUTHOR

Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
