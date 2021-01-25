#!/bin/false
# PODNAME: BZ::Client::Bug::Comment
# ABSTRACT: Client side representation of an Comment on a Bug in Bugzilla

use strict;
use warnings 'all';

package BZ::Client::Bug::Comment;
$BZ::Client::Bug::Comment::VERSION = '4.4004';
use parent qw( BZ::Client::API );

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub get {
    my($class, $client, $params) = @_;
    unless (ref $params) {
        $params = { id => $params };
    }
    $client->log('debug', __PACKAGE__ . "::get: Asking for $params");
    my $result = $class->api_call($client, 'Bug.comments', $params);

    if (my $comments = $result->{comments}) {
        if (!$comments || 'HASH' ne ref($comments)) {
            $class->error($client,
                'Invalid reply by server, expected hash of comments.');
        }
        for my $id (keys %$comments) {
            $comments->{$id} = __PACKAGE__->new( %{$comments->{$id}} );
        }
    }

    if (my $bugs = $result->{bugs}) {
        if (!$bugs || 'HASH' ne ref($bugs)) {
            $class->error($client,
                'Invalid reply by server, expected array of bugs.');
        }
        for my $id (keys %$bugs) {
            $bugs->{$id} = [
                map { __PACKAGE__->new( %$_  ) } @{$bugs->{$id}->{comments}} ];
        }
    }

    $client->log('debug', __PACKAGE__ . '::get: Got ' . %$result);

    return wantarray ? %$result : $result
}

sub add {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::add: Adding');
    my $result = $class->api_call($client, 'Bug.add_comment', $params);
    my $id = $result->{'id'};
    if (!$id) {
        $class->error($client, 'Invalid reply by server, expected comment ID.');
    }
    return $id
}

sub render {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . '::render: Rendering Comment');
    my $result = $class->api_call($client, 'Bug.render_comment', $params);
    my $html = $result->{'html'};
    if (!$html) {
        $class->error($client, 'Invalid reply by server, expected HTML.');
    }
    return $html
}

## rw methods

sub bug_id {
    my $self = shift;
    if (@_) {
        $self->{'bug_id'} = shift;
    }
    else {
        return $self->{'bug_id'}
    }
}

sub comment {
    my $self = shift;
    if (@_) {
        $self->{'text'} = shift;
        delete $self->{'comment'};
    }
    else {
        return $self->{'text'} || $self->{'comment'}
    }
}

sub text { goto &comment }

sub is_private {
    my $self = shift;
    if (@_) {
        $self->{'is_private'} = shift;
    }
    else {
        return $self->{'is_private'}
    }
}

sub work_time {
    my $self = shift;
    if (@_) {
        $self->{'work_time'} = shift;
    }
    else {
        return $self->{'work_time'}
    }
}

## ro methods

sub id { my $self = shift; return $self->{'id'} }

sub attachment_id { my $self = shift; return $self->{'attachment_id'} }

sub count { my $self = shift; return $self->{'count'} }

sub creator { my $self = shift; return $self->{'creator'} || $self->{'author'} }

sub author { goto &creator }

sub creation_time { my $self = shift; return $self->{'creation_time'} }

sub time { goto &creation_time }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Bug::Comment - Client side representation of an Comment on a Bug in Bugzilla

=head1 VERSION

version 4.4004

=head1 SYNOPSIS

This class provides methods for accessing and managing comments in Bugzilla. Instances
of this class are returned by L<BZ::Client::Bug::Comment::get>.

  my $client = BZ::Client->new( url       => $url,
                                user      => $user,
                                password  => $password );

  my $comments = BZ::Client::Bug::Comment->get( $client, $ids );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get

  my $comments = BZ::Client::Bug::Comment->get( $client, 1234 );
  my $comments = BZ::Client::Bug::Comment->get( $client, { ids => \@list, commend_ids => \@list } );

This allows you to get data about comments, given a list of bugs and/or comment ids.

Actual Bugzilla API method is "comments".

=head3 History

Added in Bugzilla 3.4

=head3 Parameters

A single scalar is considered a search for L</ids>, otherwise a hash reference must be provided.

Note: At least one of L</ids> or L</comment_ids> is required.

In addition to the parameters below, this method also accepts the standard L<BZ::Client::Bug/include_fields> and L<BZ::Client::Bug/exclude_fields> arguments.

=over 4

=item ids

I<ids> (array) - An array that can contain both bug ID's and bug aliases. All of the comments (that are visible to you) will be returned for the specified bugs.

=item comment_ids

I<comment_ids> (array) - An array of integer comment ID's. These comments will be returned individually, separate from any other comments in their respective bugs.

=item new_since

I<new_since> (L<DateTime>) - If specified, the method will only return comments newer than this time. This only affects comments returned from the L</ids> argument. You will always be returned all comments you request in the I<comment_ids> argument, even if they are older than this date.

=back

=head3 Returns

A hash reference containing two items is returned. e.g.

 {

     bugs => {
         123 => \@comments,
         456 => \@comments,
     },

     comments => {
         789 => $comment,
     },

 }

The Bugzilla WebService documentation doesnt state what order the comments will be in, however they seem to be returned [ oldest, newest ]. If this order is important to you, then you should sort them just to be sure.

More details on the above example:

=over 4

=item bugs

This is used for bugs specified in L</ids> parameter.

This is a hash, wherein the keys are the numeric IDs of the bugs, and the corresponding value is an array ref of comment objects.

Note that any individual bug will only be returned once, so if you specify an ID multiple times in ID's, it will still only be returned once.

=item comments

Each individual comment requested in L</comment_ids> is returned here.

This is a hash wherein the keys are the numeric comment ID, and the corresponding value is the comment object.

=back

A "comment" as described above is an object instance of this package i.e. L<BZ::Client::Bug::Comment>.

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The C<bug_id> you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the C<bug_id> you specified.

=item 110 - Comment Is Private

You specified the ID of a private comment in the I<comment_ids> argument, and you are not in the "insider group" that can see private comments.

=item 111 - Invalid Comment ID

You specified an ID in the L</comment_ids> argument that is invalid--either you specified something that wasn't a number, or there is no comment with that ID.

=back

=head2 add

This allows you to add a comment to a bug in Bugzilla.

Actual Bugzilla API method is "add_comment".

=head3 History

Added in Bugzilla 3.2.

Modified to return the new comment's ID in Bugzilla 3.4

Modified to throw an error if you try to add a private comment but can't, in Bugzilla 3.4.

=head3 Parameters

An instance of this package or a hash containing:

=over 4

=item id

I<id> (int or string) Required - The ID or alias of the bug to append a comment to.

=item comment

I<comment> (string) Required - The comment to append to the bug. If this is empty or all whitespace, an error will be thrown saying that you did not set the comment parameter.

=item is_private

I<is_private> (boolean) - If set to true, the comment is private, otherwise it is assumed to be public.

Before Bugzilla 3.6, the L</is_private argument> was called C<private>, and you can still call it C<private> for backwards-compatibility purposes if you wish.

=item work_time

I<work_time> (double) - Adds this many hours to the "Hours Worked" on the bug. If you are not in the time tracking group, this value will be ignored.

=back

=head3 Returns

The id of the newly-created comment.

=head3 Errors

=over

=item 54 - Hours Worked Too Large

You specified a L</work_time> larger than the maximum allowed value of C<99999.99>.

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The ID you specified doesn't exist in the database.

=item 109 - Bug Edit Denied

You did not have the necessary rights to edit the bug.

=item 113 - Can't Make Private Comments

You tried to add a private comment, but don't have the necessary rights.

=item 114 - Comment Too Long

You tried to add a comment longer than the maximum allowed length (65,535 characters).

=back

Before Bugzilla 3.6, error 54 and error 114 had a generic error code of 32000.

=head2 render

Returns the HTML rendering of the provided comment text.

Actual Bugzilla API method is "render_comment".

Note: this all takes place on your Bugzilla server.

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

=over 4

=item text

I<text> (string) Required - Text comment text to render

=item id

I<id> The ID of the bug to render the comment against.

=back

=head3 Returns

The HTML rendering

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The C<bug_id> you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the C<bug_id> you specified.

=back

=head2 new

  my $comment = BZ::Client::Bug::Comment->new(
                                          id         => $bug_id,
                                          comment    => $comment,
                                          is_private => 1 || 0,
                                          work_time  => 3.5
                                        );

Creates a new instance with the given details. Doesn't actually touch your Bugzilla Server - see L</add> for that.

=head1 INSTANCE METHODS

This section lists the modules instance methods.

=head2 bug_id

I<bug_id> (int) - The ID of the bug that this comment is on when reading

I<bug_id> (int or string) - The ID or alias of the bug to append a comment to when writing

=head2 comment

I<comment> (string) The actual text of the comment when reading

When writing, the comment to append to the bug. If this is empty or all whitespace, an error will be thrown saying that you did not set the L</comment> parameter.

Max length is 65,535 characters.

=head2 text

Synonym for L</comment>

=head2 is_private

I<is_private> (boolean) - If set to true, the comment is private, otherwise it is assumed to be public.

Read and Write.

=head2 work_time

I<work_time> (double) - Adds this many hours to the "Hours Worked" on the bug. If you are not in the time tracking group, this value will be ignored.

Max value is 99999.99

=head2 id

I<id> (int) The globally unique ID for the comment.

Read only.

=head2 attachment_id

I<attachment_id> (int) If the comment was made on an attachment, this will be the ID of that attachment. Otherwise it will be null.

Read only.

Added to the return value in Bugzilla 3.6

=head2 count

I<count> (int) - The number of the comment local to the bug. The Description is 0, comments start with 1.

Read only.

Added to the return value in Bugzilla 4.4.

=head2 creator

I<creator> (string) -  The login name of the comment's author.

Also returned as L</author>, for backwards-compatibility with older Bugzillas. (However, this backwards-compatibility will go away in Bugzilla 5.0)

In bugzilla 4.0, the L</author> return value was renamed to L</creator>.

=head2 author

See creator

=head2 time

I<time> (L<DateTime>) - The time (in Bugzilla's timezone) that the comment was added.

Read only.

=head2 creation_time

I<creation_time> (L<DateTime>) - This is exactly same as the L</time> key. Use this field instead of L</time> for consistency with other methods including L</get> and "attachments". For compatibility, I</time> is still usable. However, please note that I</time> may be deprecated and removed in a future release of Bugzilla.

Read only.

Added in Bugzilla 4.4.

=head1 SEE ALSO

L<BZ::Client>, L<BZ::Client::API>, L<Bugzilla API|https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html>

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
