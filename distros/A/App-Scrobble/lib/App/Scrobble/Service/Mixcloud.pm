# ABSTRACT: Mixcloud plugin
package App::Scrobble::Service::Mixcloud;

use Moose;
use namespace::autoclean;
with 'App::Scrobble::Role::WithService';

use WWW::Mixcloud;

our $VERSION = '0.03'; # VERSION

sub is_plugin_for {
    my $class = shift;
    my $url   = shift;

    return unless $url =~ /mixcloud\.com/;

    return 1;

}

sub get_tracks {
    my $self = shift;

    my $cloudcast = WWW::Mixcloud->new->get_cloudcast( $self->url );

    foreach my $section ( @{$cloudcast->sections} ) {
        $self->add_track({
            title => $section->track->name,
            artist => $section->track->artist->name,
        }) if $section->has_track;
    }

    return $self->tracks;
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

App::Scrobble::Service::Mixcloud - Mixcloud plugin

=head1 VERSION

version 0.03

=head1 DESCRIPTION

L<App::Scrobble> plugin for L<Mixcloud|http://www.mixcloud.com>. Will scrobble
all the tracks in any cloudcast passed to the command line client.

=head1 METHODS

=head2 C<is_plugin_for>

Returns a boolean if the URL passed in is a mixcloud URL.

=head2 C<get_tracks>

Uses L<WWW::Mixcloud> to construct a hashref of track data from the cloudcast.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

