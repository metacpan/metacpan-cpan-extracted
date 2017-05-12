package Bb::Collaborate::V3::Presentation;
use warnings; use strict;

use Mouse;

extends 'Bb::Collaborate::V3::_Content';

=head1 NAME

Bb::Collaborate::V3::Presentation - Presentation entity class

=head1 DESCRIPTION

This command uploads presentation files, such as Collaborate whiteboard files or I<Plan!> files for use by your Collaborate sessions.

Once uploaded, you will need to "attach" the file to one or more Collaborate
sessions using the L<Bb::Collaborate::V3::Session> C<set_presentation()> method.

=cut

__PACKAGE__->entity_name('Presentation');

=head1 PROPERTIES

=head2 presentationId (Int)

Identifier of the presentation file in the ELM repository.

=cut

has 'presentationId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('presentationId');
__PACKAGE__->params(
    content => 'Str',
    filename => 'Str',
    sessionId => 'Int',
    );

=head2 description (Str)

A description of the presentation content.

=cut

has 'description' => (is => 'rw', isa => 'Str');

=head2 size (Int)

The size of the presentation file (bytes), once uploaded to the ELM repository.

=cut

has 'size' => (is => 'rw', isa => 'Int');

=head2 creatorId (Str)

The identifier of the owner of the presentation file.

=cut

has 'creatorId' => (is => 'rw', isa => 'Str');

=head2 filename (Str)

The name of the presentation file including the file extension.

Collaborate supports the following presentation file types:

=over 4

=item * Collaborate Whiteboard files: C<.wbd>, C<.wbp>

=item * Collaborate Plan! files: C<.elp>, C<.elpx>.

=back

Note: The filename must be less than 64 characters (including any file extensions)

=cut

=head1 METHODS

=cut

=head2 upload

Uploads content and creates a new presentation resource.

You can either upload a file:

    # 1. upload a local file
    my $presentation = Bb::Collaborate::V3::Presentation->upload('c:\\Documents\intro.wbd');
    $some_session->set_presentation( $presentation );

or source binary data for the presentation.

    # 2. source our own binary content
    open (my $fh, '<', $presentation_path)
        or die "unable to open $presentation_path: $!";
    $fh->binmode;

    my $content = do {local $/ = undef; <$fh>};
    die "no presentation data: $presentation_path"
        unless ($content);

    my $presentation = Bb::Collaborate::V3::Presentation->upload(
             {
                    filename => 'myplan.elpx',
                    creatorId =>  'bob',
                    content => $content,
	     },
         );

    $some_session->set_presentation( $presentation );

=cut

=head2 list

    my $session_presentations = Bb::Collaborate::V3::Presentation->list(
                                   filter => {sessionId => $my_session}
                                );

Lists sessions. You will need to provide a filter that contains at least one
of: C<creatorId>, C<presentationId>, C<description> or C<sessionId>.

=cut

=head2 delete

    $presentation->delete;

Deletes presentation content from the server  and removes it from any associated sessions.

=cut


1;
