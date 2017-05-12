# ABSTRACT: Role interface for App::Scrobble::Service classes
package App::Scrobble::Role::WithService;

use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.03'; # VERSION

has 'tracks' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_track => 'push',
    }
);

has 'url' => (
    is => 'rw',
    isa => 'Str',
);

requires 'is_plugin_for';

requires 'get_tracks';

1;



=pod

=head1 NAME

App::Scrobble::Role::WithService - Role interface for App::Scrobble::Service classes

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Interface for L<App::Scrobble::Service::*> plugins.

=head1 ATTRIBUTES

=head2 C<url>

The URL (Str) of the podcast/cloudcast/webpage/whatever to scrobble.

=head2 C<tracks>

Arrayref of track data in the form:

    { title => 'foo', artist => 'bar' }

=head1 METHODS

=head2 C<is_plugin_for>

Will be passed the URL to scrobble and should return a boolean indicating
whether this plugin can scrobble this URL.

=head2 C<get_tracks>

Should populate the C<tracks> hashref with the data from the URL. Is expected
to return the C<tracks> hashref.

=head1 SEE ALSO

L<App::Scrobble>
L<App::Scrobble::Service::Mixcloud>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

