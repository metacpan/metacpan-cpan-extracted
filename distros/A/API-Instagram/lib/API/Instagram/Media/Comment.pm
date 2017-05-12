package API::Instagram::Media::Comment;

# ABSTRACT: Instagram Media Comment Object

use Moo;
use Time::Moment;

has id           => ( is => 'ro', required => 1 );
has from         => ( is => 'ro', required => 1, coerce => sub { API::Instagram->instance->user( $_[0] ) } );
has text         => ( is => 'ro', required => 1 );
has media        => ( is => 'ro', required => 1 );
has created_time => ( is => 'ro', coerce => sub { Time::Moment->from_epoch( $_[0] ) } );

sub remove {
	my $self = shift;
	my $url  = sprintf "media/%s/comments/%s", $self->media->id, $self->id;
	$self->media->_api->_del( $url )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Instagram::Media::Comment - Instagram Media Comment Object

=head1 VERSION

version 0.013

=head1 SYNOPSIS

	print $comment->text . "\n-\n";
	print "By %s, at year %d\n", $comment->from->full_name, $comment->created_time->year;

=head1 DESCRIPTION

See L<http://instagr.am/developer/endpoints/comments/>.

=head1 ATTRIBUTES

=head2 id

Returns comment id.

=head2 from

Returns commenter L<API::Instagram::User> object.

=head2 text

Returns the text commented.

=head2 created_time

Returns the comment date in a L<Time::Moment> object.

=head2 media

Returns the media where the comment was posted.

=head1 METHODS

=head2 remove

	$comment->remove;

Removes the comment either on the authenticated user's media object or authored by the authenticated user.

=head1 AUTHOR

Gabriel Vieira <gabriel.vieira@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Gabriel Vieira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
