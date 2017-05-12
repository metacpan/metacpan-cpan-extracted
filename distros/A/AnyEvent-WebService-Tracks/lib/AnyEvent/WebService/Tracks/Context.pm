package AnyEvent::WebService::Tracks::Context;

use strict;
use warnings;
use parent 'AnyEvent::WebService::Tracks::Resource';

our $VERSION = '0.02';

__PACKAGE__->readonly(qw/created_at id updated_at/);
__PACKAGE__->accessor(qw/name position/);

sub resource_path {
    return 'contexts';
}

sub xml_root {
    return 'context';
}

sub is_hidden {
    my ( $self ) = @_;

    return $self->{'hide'} eq 'true';
}

sub hide {
    my ( $self ) = @_;

    $self->{'hide'}           = 'true';
    $self->{'_dirty'}{'hide'} = 1;
}

sub unhide {
    my ( $self ) = @_;

    $self->{'hide'}           = 'false';
    $self->{'_dirty'}{'hide'} = 1;
}

sub todos {
    my ( $self, $cb ) = @_;

    my $id = $self->id;
    $self->{'parent'}->fetch_multiple("contexts/$id/todos",
        'AnyEvent::WebService::Tracks::Todo', $cb);
};

1;

__END__

=head1 NAME

AnyEvent::WebService::Tracks::Context - Tracks context objects

=head1 VERSION

0.02

=head1 SYNOPSIS

  $tracks->create_context($name, sub {
    my ( $context ) = @_;

    say $context->name;
  });

=head1 DESCRIPTION

AnyEvent::WebService::Tracks::Context objects represent GTD contexts in a
Tracks installation.

=head1 READ-ONLY ATTRIBUTES

=head2 created_at

When the context was created.

=head2 id

The ID of the context in Tracks.

=head2 updated_at

When the context was last updated.

=head1 WRITABLE ATTRIBUTES

=head2 name

The name of the context (must be unique).

=head2 position

The position of this context in the list of displayed contexts.

=head1 METHODS

Most useful methods in this class come from its superclass,
L<AnyEvent::WebService::Tracks::Resource>.

=head2 $context->is_hidden

Returns a truthy value when this context is hidden, and falsy one when it
is not.

=head2 $context->hide

Hide this context on its next update.

=head2 $context->unhide

Unhides this context on its next update.

=head2 $context->todos($cb)

Retrieves the list of todos under this context and calls C<$cb> with an
array reference containing them.

=head1 AUTHOR

Rob Hoelz, C<< rob at hoelz.ro >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-AnyEvent-WebService-Tracks at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-WebService-Tracks>. I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Rob Hoelz.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::WebService::Tracks::Resource>, L<AnyEvent::WebService::Tracks>

=begin comment

Undocumented methods (for Pod::Coverage)

=over

=item resource_path
=item xml_root

=back

=end comment

=cut
