#!/bin/false
# PODNAME: BZ::Client::Bug::Attachment
# ABSTRACT: Client side representation of an Attachment to a Bug in Bugzilla
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

package BZ::Client::Bug::Attachment;
$BZ::Client::Bug::Attachment::VERSION = '4.4002';
use parent qw( BZ::Client::API );

use File::Basename qw/ basename /;

# See https://www.bugzilla.org/docs/tip/en/html/api/Bugzilla/WebService/Bug.html
# These are in order as per the above

## functions

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->data($self->{data}) # This will make it a ::base64 object
        if $self->{data};
    return $self
}

sub get {
    my($class, $client, $params) = @_;
    $client->log('debug', __PACKAGE__ . "::get: Asking for $params");
    my $result = $class->api_call($client, 'Bug.attachments', $params);

    if (my $attachments = $result->{attachments}) {
        $class->error($client,
            'Invalid reply by server, expected hash of attachments.')
                unless ($attachments and 'HASH' eq ref($attachments));
        for my $id (keys %$attachments) {
            $attachments->{$id}->{data} =
                BZ::Client::XMLRPC::base64->new64($attachments->{$id}->{data});
            $attachments->{$id} = __PACKAGE__
                                    ->new( %{$attachments->{$id}} );
        }
    }

    if (my $bugs = $result->{bugs}) {
        $class->error($client,
            'Invalid reply by server, expected array of bugs.')
                unless ($bugs and 'HASH' eq ref($bugs));
        for my $id (keys %$bugs) {
            $bugs->{$id} = [
                map { __PACKAGE__->new( %$_  ) }
                map { $_->{data} = BZ::Client::XMLRPC::base64->new64($_->{data}) if $_->{data}; $_ }
                @{$bugs->{$id}} ];
        }
    }

    $client->log('debug', __PACKAGE__ . '::get: Got ' . %$result);

    return wantarray ? %$result : $result
}

sub add {
    my($class, $client, $params) = @_;
    # $params = { ids => [], file_name => basename($file), content_type => '?', summary=> $filename, data => \$content
    $client->log('debug', __PACKAGE__ . '::add: Attaching a file');
    if ( ref $params eq 'HASH' ) {
        my $filename;
        if ( ! $params->{data}
            and $filename = $params->{file_name}
            and -f $filename ) {
            $params->{data} = do {
                local $/;
                open( my $fh, '<', $filename );
                binmode $fh;
                <$fh>
            };
            $params->{file_name} = basename($params->{file_name});
        }
        $params->{data} = BZ::Client::XMLRPC::base64->new($params->{data})
            if (exists $params->{data} and ref $params->{data} eq '');
    }
    my $result = $class->api_call($client, 'Bug.add_attachment', $params);
    my $ids = $result->{'ids'};
    $class->error($client, 'Invalid reply by server, expected attachment ID.')
        unless $ids;
    return wantarray ? @$ids : $ids
}

sub update {
    my(undef, $client, $params) = @_;
    return _returns_array($client, 'Bug.update_attachment', $params, 'attachments');
}


## rw methods

sub id {
    my $self = shift;
    if (@_) {
        $self->{'id'} = shift;
    }
    else {
        return $self->{'id'}
    }
}

sub data {
    my $self = shift;
    if (@_) {
        my $data = shift;
        $self->{'data'} = ref $data ?
                  $data : BZ::Client::XMLRPC::base64->new($data);
    }
    else {
        return $self->{'data'}
    }
}

sub file_name {
    my $self = shift;
    if (@_) {
        $self->{'file_name'} = shift;
    }
    else {
        return $self->{'file_name'}
    }
}

sub description { goto &summary }

sub summary {
    my $self = shift;
    if (@_) {
        $self->{'summary'} = shift;
    }
    else {
        return $self->{'summary'} || $self->{'description'}
    }
}

sub content_type {
    my $self = shift;
    if (@_) {
        $self->{'content_type'} = shift;
    }
    else {
        return $self->{'content_type'}
    }
}

sub comment {
    my $self = shift;
    if (@_) {
        $self->{'comment'} = shift;
    }
    else {
        return $self->{'comment'}
    }
}

sub is_patch {
    my $self = shift;
    if (@_) {
        $self->{'is_patch'} = shift;
    }
    else {
        return $self->{'is_patch'}
    }
}

sub is_private {
    my $self = shift;
    if (@_) {
        $self->{'is_private'} = shift;
    }
    else {
        return $self->{'is_private'}
    }
}

sub is_url {
    my $self = shift;
    if (@_) {
        $self->{'is_url'} = shift;
    }
    else {
        return $self->{'is_url'}
    }
}

## ro methods

sub size { my $self = shift; return $self->{'size'} }

sub creation_time { my $self = shift; return $self->{'creation_time'} }

sub last_change_time { my $self = shift; return $self->{'last_change_time'} }

sub bug_id { my $self = shift; return $self->{'bug_id'} }

sub creator { my $self = shift; return $self->{'creator'} || $self->{'attacher'} }

sub attacher { goto &creator }

sub flags { my $self = shift; return $self->{'flags'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BZ::Client::Bug::Attachment - Client side representation of an Attachment to a Bug in Bugzilla

=head1 VERSION

version 4.4002

=head1 SYNOPSIS

This class provides methods for accessing and managing attachments in Bugzilla. Instances of this class are returned by L<BZ::Client::Bug::Attachment::get>.

 my $client = BZ::Client->new(
                        url       => $url,
                        user      => $user,
                        password  => $password
                    );

 my $comments = BZ::Client::Bug::Attachment->get( $client, $ids );

=head1 CLASS METHODS

This section lists the class methods, which are available in this module.

=head2 get

It allows you to get data about attachments, given a list of bugs and/or attachment ids.

Note: Private attachments will only be returned if you are in the insidergroup or if you are the submitter of the attachment.

Actual Bugzilla API method is "attachments".

=head3 History

Added in Bugzilla 3.6.

=head3 Parameters

Note: At least one of L</ids> or L</attachment_ids> is required.

In addition to the parameters below, this method also accepts the standard L<BZ::Client::Bug/include_fields> and L<BZ::Client::Bug/exclude_fields> arguments.

=over 4

=item ids

I<ids> (array) - An array that can contain both bug IDs and bug aliases. All of the attachments (that are visible to you) will be returned for the specified bugs.

=item attachment_ids

I<attachment_ids> (array) - An array of integer attachment ID's.

=back

=head3 Returns

A hash containing two items is returned:

=over 4

=item bugs

This is used for bugs specified in L</ids>. This is a hash, where the keys are the numeric ID's of the bugs and the value is an array of attachment obejcts.

Note that any individual bug will only be returned once, so if you specify an ID multiple times in L</ids>, it will still only be returned once.

=item attachments

Each individual attachment requested in L</attachment_ids> is returned here, in a hash where the numeric L</attachment_id> is the key, and the value is the attachment object.

=back

The return value looks like this:

 {
     bugs => {
         1345 => [
             { (attachment) },
             { (attachment) }
         ],
         9874 => [
             { (attachment) },
             { (attachment) }
         ],
     },

     attachments => {
         234 => { (attachment) },
         123 => { (attachment) },
     },
 }

An "attachment" as shown above is an object instance of this package.

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The C<bug_id> you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the C<bug_id> you specified.

=item 304 - Auth Failure, Attachment is Private

You specified the ID of a private attachment in the L</attachment_ids> argument, and you are not in the "insidergroup" that can see private attachments.

=back

=head2 add

This allows you to add an attachment to a bug in Bugzilla.

Actual Bugzilla API method is "add_attachment".

=head3 History

Added in Bugzilla 4.0.

The return value has changed in Bugzilla 4.4.

=head3 Parameters

An instance of this package or a hash containing:

=over 4

=item ids

I<ids> (array) Required - An array of ints and/or strings - the ID's or aliases of bugs that you want to add this attachment to. The same attachment and comment will be added to all these bugs.

=item data

I<data> (string or base64) Mostly Required - The content of the attachment.

The content will be base64 encoded. Of you can do it yourself by providing this option as a L<BZ::Client::XMPRPC::base64> object.

What is I<"Mostly Required"> you ask? If you provide L</file_name> only, this module will attempt to slurp it to provide this I<data> parameter. See L</file_name> options for more details.

=item file_name

I<file_name> (string) Required - The "file name" that will be displayed in the UI for this attachment.

If no I</data> parameter is provided, this module will attempt to open, slurp the contents of a file with path I<file_name>, base64 encod that data,  placed it into the I</data> parameter, then I<file_name> is truncted to just the files basename.

Failures to open the file (for anyreason) will be silently ignored and the I<file_name> parameter will not be touched.

=item summary

I<summary> (string) Required - A short string describing the attachment.

=item content_type

I<content_type> (string) Required - The MIME type of the attachment, like I<text/plain> or I<image/png>.

=item comment

I<comment> (string) - A comment to add along with this attachment.

=item is_patch

I<is_patch> (boolean) - True if Bugzilla should treat this attachment as a patch. If you specify this, you do not need to specify a L</content_type>. The L</content_type> of the attachment will be forced to C<text/plain>.

Defaults to False if not specified.

=item is_private

I<is_private> (boolean) - True if the attachment should be private (restricted to the "insidergroup"), False if the attachment should be public.

Defaults to False if not specified.

=item flags

An array of hashes with flags to add to the attachment. to create a flag, at least the C<status> and the C<type_id> or C<name> must be provided. An optional requestee can be passed if the flag type is requestable to a specific user.

=over 4

=item name

I<name> (string) - The name of the flag type.

=item type_id

I<type_id> (int) - THe internal flag type ID.

=item status

I<status> (string) - The flags new status  (i.e. "?", "+", "-" or "X" to clear a flag).

=item requestee

I<requestee> (string) - The login of the requestee if the flag type is requestable to a specific user.

=back

=back

=head3 Returns

An array of the attachment ID's created.

=head3 Errors

=over

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The C<bug_id> you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the C<bug_id> you specified.

=item 129 - Flag Status Invalid

The flag status is invalid.

=item 130 - Flag Modification Denied

You tried to request, grant, or deny a flag but only a user with the required permissions may make the change.

=item 131 - Flag not Requestable from Specific Person

You can't ask a specific person for the flag.

=item 133 - Flag Type not Unique

The flag type specified matches several flag types. You must specify the type id value to update or add a flag.

=item 134 - Inactive Flag Type

The flag type is inactive and cannot be used to create new flags.

=item 600 - Attachment Too Large

You tried to attach a file that was larger than Bugzilla will accept.

=item 601 - Invalid MIME Type

You specified a L</content_type> argument that was blank, not a valid MIME type, or not a MIME type that Bugzilla accepts for attachments.

=item 603 - File Name Not Specified

You did not specify a valid for the L</file_name> argument.

=item 604 - Summary Required

You did not specify a value for the L</summary> argument.

=item 606 - Empty Data

You set the C<data> field to an empty string.

=back

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

=head2 update

This allows you to update attachment metadata in Bugzilla.

Actual Bugzilla API method is "update_attachments".

=head3 History

Added in Bugzilla 5.0.

=head3 Parameters

=over 4

=item ids

I<ids> (array) - An array that can contain both bug IDs and bug aliases. All of the attachments (that are visible to you) will be returned for the specified bugs.

=item file_name

I<file_name> (string) Required - The "file name" that will be displayed in the UI for this attachment.

=item summary

I<summary> (string) Required - A short string describing the attachment.

=item comment

I<comment> (string) - A comment to add along with this attachment.

=item content_type

I<content_type> (string) -  The MIME type of the attachment, like C<text/plain> or C<image/png>.

=item is_patch

I<is_patch> (boolean) - True if Bugzilla should treat this attachment as a patch. If you specify this, you do not need to specify a L</content_type>. The L</content_type> of the attachment will be forced to C<text/plain>.

=item is_private

I<is_private> (boolean) - True if the attachment should be private (restricted to the "insidergroup"), False if the attachment should be public.

=item is_obsolete

I<is_obsolete> (boolean) - True if the attachment is obsolete, False otherwise.

=item flags

An array of hashes with flags to add to the attachment. to create a flag, at least the status and the type_id or name must be provided. An optional requestee can be passed if the flag type is requestable to a specific user.

=over 4

=item name

I<name> (string) - The name of the flag type.

=item type_id

I<type_id> (int) - THe internal flag type id.

=item status

I<status> (string) - The flags new status  (i.e. "?", "+", "-" or "X" to clear a flag).

=item requestee

I<requestee> (string) - The login of the requestee if the flag type is requestable to a specific user.

=item id

I<id> (int) - Use C<id> to specify the flag to be updated. You will need to specify the C<id> if more than one flag is set of the same name.

=item new

I<new> (boolean) - Set to true if you specifically want a new flag to be created.

=back

=back

=head3 Returns

An array of hashes with the following fields:

=over 4

=item id

I<id> (int) The id of the attachment that was updated.

=item last_change_time

I<last_change_time> (L<DateTime>) - The exact time that this update was done at, for this attachment. If no update was done (that is, no fields had their values changed and no comment was added) then this will instead be the last time the attachment was updated.

=item changes

I<changes> (hash) - The changes that were actually done on this bug. The keys are the names of the fields that were changed, and the values are a hash with two keys:

=over 4

=item added

I<added> (string) - The values that were added to this field. possibly a comma-and-space-separated list if multiple values were added.

=item removed

I<removed> (string) - The values that were removed from this field.

=back

=back

Here is an example of what a return value might look like:

 [
   {
     id    => 123,
     last_change_time => '2010-01-01T12:34:56',
     changes => {
       summary => {
         removed => 'Sample ptach',
         added   => 'Sample patch'
       },
       is_obsolete => {
         removed => '0',
         added   => '1',
       },
     },
   },
 ]

=head3 Errors

=over 4

=item 100 - Invalid Bug Alias

If you specified an alias and there is no bug with that alias.

=item 101 - Invalid Bug ID

The bug_id you specified doesn't exist in the database.

=item 102 - Access Denied

You do not have access to the C<bug_id> you specified.

=item 129 - Flag Status Invalid

The flag status is invalid.

=item 130 - Flag Modification Denied

You tried to request, grant, or deny a flag but only a user with the required permissions may make the change.

=item 131 - Flag not Requestable from Specific Person

You can't ask a specific person for the flag.

=item 133 - Flag Type not Unique

The flag type specified matches several flag types. You must specify the type ID value to update or add a flag.

=item 134 - Inactive Flag Type

The flag type is inactive and cannot be used to create new flags.

=item 601 - Invalid MIME Type

You specified a L</content_type> argument that was blank, not a valid MIME type, or not a MIME type that Bugzilla accepts for attachments.

=item 603 - File Name Not Specified

You did not specify a valid for the L</file_name> argument.

=item 604 - Summary Required

You did not specify a value for the L</summary> argument.

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

I<bug_id> (int) - The ID of the bug that this attachment is on when reading

I<bug_id> (int or string) - The ID or alias of the bug to append a attachment to when writing. B<Required>.

=head2 data

I<data> (base64 or string) The content of the attachment.

When writing, either provide a string (which will be C<base46> encoded for you) or a L<BZ::Client::XMLRPC::base64> object if you'd like to DIY.

When reading, a L<BZ::Client::XMLRPC::base64> object will be returned. To save you the trip, this object has a C<raw()> and a C<base64()> method. Here is an example.

 my $data = $attachment->data();
 my $file_content_base64_encoded = $data->base64();
 my $original_file_content = $data->raw();

B<Required>, Read and Write.

=head2 file_name

I<file_name> (string) The "file name" that will be displayed in the UI for this attachment.

B<Required>, Read and Write.

=head2 summary

I<summary> (string) A short string describing the attachment.

B<Required>, Read and Write.

=head2 content_type

I<content_type> (string) The MIME type of the attachment, like C<text/plain> or C<image/png>.

B<Required>, Read and Write.

=head2 comment

I<comment> (string or hash) A comment to add along with this attachment. If C<comment> is a hash, it has the following keys:

Only useful when adding attachments.

=over 4

=item body

I<body> (string) The body of the comment.

=item is_markdown

I<is_markdown> (boolean) If set to true, the comment has Markdown structures; otherwise, it is an ordinary text.

=back

=head2 is_patch

I<is_patch> (boolean) True if the attachment should be private (restricted to the "insidergroup"), False if the attachment should be public.

=head2 is_private

I<is_private> (boolean) True if the attachment is private (only visible to a certain group called the "insidergroup"), False otherwise.

=head2 is_obsolete

I<is_obsolete> (boolean) - True if the attachment is obsolete, False otherwise.

=head2 flags

I<flags> (array) An array of hashes with flags to add to the attachment. to create a flag, at least the status and the type_id or name must be provided. An optional requestee can be passed if the flag type is requestable to a specific user.

Read and Write.

=over 4

=item id

I<id> (name) The ID of the flag.

=item name

I<name> (string) The name flag type.

Read and Write.

=item type_id

I<type_id> (int) The internal flag type ID.

Read and Write.

=item creation_date

I<creation_date> (L<DateTime>) The timestamp when this flag was originally created.

Read only.

=item modification_date

I<modification_date> (L<DateTime>) The timestamp when the flag was last modified.

Read only.

=item status

I<status> (string) The flags new status (i.e. "?", "+", "-" or "X" to clear a flag).

Read and Write.

=item setter

I<setter> (string) The login name of the user who created or last modified the flag.

Read only.

=item requestee

I<requestee> (string) The login of the requestee if the flag type is requestable to a specific user.

=back

=head2 size

I<size> (int) The length (in bytes) of the attachment.

Read only.

=head2 creation_time

I<creation_time> (L<DateTime>) The time the attachment was created.

Read only.

=head2 last_change_time

I<last_change_time> (L<DateTime>) The last time the attachment was modified.

=head2 attachment_id

I<attachment_id> (int) The numeric id of the attachment.

=head2 creator

I<creator> (string) The login name of the user that created the attachment.

=head1 AUTHORS

=over 4

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=item *

Jochen Wiedmann <jochen.wiedmann@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
