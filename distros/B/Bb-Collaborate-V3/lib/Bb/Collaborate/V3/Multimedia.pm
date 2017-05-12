package Bb::Collaborate::V3::Multimedia;
use warnings; use strict;

use Mouse;

extends 'Bb::Collaborate::V3::_Content';

=head1 NAME

Bb::Collaborate::V3::Multimedia - Multimedia entity class

=head1 DESCRIPTION

This command uploads supported multimedia files into your ELM repository for use by your Collaborate sessions.

Once uploaded, you will need to "attach" the file to one or more Collaborate
sessions using the L<Bb::Collaborate::V3::Session> C<set_multimedia()>
method.

=cut

__PACKAGE__->entity_name('Multimedia');

=head1 PROPERTIES

=head2 multimediaId (Int)

Identifier of the multimedia file in the ELM repository.

=cut

has 'multimediaId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('multimediaId');
__PACKAGE__->params(
    content => 'Str',
    filename => 'Str',
    sessionId => 'Int',
    );

=head2 description (Str)

A description of the multimedia content.

=cut

has 'description' => (is => 'rw', isa => 'Str');

=head2 size (Int)

The size of the multimedia file (bytes), once uploaded to the ELM repository.

=cut

has 'size' => (is => 'rw', isa => 'Int');

=head2 creatorId (Str)

The identifier of the owner of the multimedia file.

=cut

has 'creatorId' => (is => 'rw', isa => 'Str');

=head2 filename (Str)

The name of the multimedia file including the file extension.
Collobrate supports the following multimedia file types:

=over 4

=item * MPEG files: C<.mpeg>, C<.mpg>, C<.mpe>, C<.m4v>, C<.mp4>

=item * QuickTime files: C<.mov>, C<.qt>

=item * Windows Media files: C<.wmv>

=item * Flash files: C<.swf>

=item * Audio files: C<.mp3>

=back

The filename must be less than 64 characters (including any file extensions).

=cut

=head1 METHODS

=cut

=head2 upload

Uploads content and creates a new multimedia resource.

You can either upload a file:

    # 1. upload a local file
    my $multimedia1 = Bb::Collaborate::V3::Multimedia->upload('c:\\Documents\intro.wav');

or source binary content:

    # 2. source our own binary content
    open (my $fh, '<', $multimedia_path)
        or die "unable to open $multimedia_path: $!";
    $fh->binmode;

    my $content = do {local $/ = undef; <$fh>};
    die "no multimedia data: $multimedia_path"
        unless ($content);

    my $multimedia2 = Bb::Collaborate::V3::Multimedia->upload(
             {
                    filename => 'whoops.wav',
                    creatorId =>  'alice',
                    content => $content,
                    description => 'Caravan destroys service station',
	     },
         );

You can assign multiple multimedia items to a session:

    $some_session->set_multimedia( [$multimedia1, $multimedia2] );

=cut

=head2 list

    my $session_presentations = Bb::Collaborate::V3::Multimedia->list(
                                   filter => {sessionId => $my_session->id}
                                );

Lists multimedia. You will need to provide a filter that contains at least one
of: C<sessionId>, C<creatorId>, C<description> or C<multimediaId>.

=cut

=head2 delete

    $multimedia->delete;

Deletes multimedia content from the server and removes it from any associated sessions.

=cut

1;
