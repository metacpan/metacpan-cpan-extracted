package Acme::Archive::Mbox;

use warnings;
use strict;

use Acme::Archive::Mbox::File;
use File::Slurp;
use Mail::Box::Manager;

=head1 NAME

Acme::Archive::Mbox - Mbox as an archive format.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Uses Mbox as an archive format, like tar or zip but silly.  Creates an mbox
with one message per file or directory.  File contents are stored as an
attachment, metadata goes in mail headers.

    use Acme::Archive::Mbox;

    my $archive = Acme::Archive::Mbox->new();
    $archive->add_file('filename');
    $archive->add_data('file/name', $contents);
    $archive->write('foo.mbox');

    ...

    $archive->read('foo.mbox');
    $archive->extract();

=head1 FUNCTIONS

=head2 new ()

Create an Acme::Archive::Mbox object.

=cut

sub new {
    my $class = shift;
    my $self = { files => [] };
    return bless $self,$class;
}

=head2 add_data ($name, $contents, %attr)

Add a file given a filename and contents.  (File need not exist on disk)

=cut

sub add_data {
    my $self = shift;
    my $name = shift;
    my $contents = shift;
    my %attr = @_;

    my $file = Acme::Archive::Mbox::File->new($name, $contents, %attr);
    push @{$self->{files}}, $file if $file;

    return $file;
}

=head2 add_file ($name, [$archive_name])

Add a file given a filename.  File will be read from disk, leading
slashes will be stripped.  Will accept an optional alternative filename
to be used in the archive.

=cut

sub add_file {
    my $self = shift;
    my $name = shift;
    my $altname = shift || $name;
    my %attr;

    my $contents = read_file($name, err_mode => 'carp', binmode => ':raw');
    return unless $contents;

    my (undef, undef, $mode, undef, $uid, $gid, undef, undef, undef, $mtime) = stat $name;
    $attr{mode} = $mode & 0777;
    $attr{uid} = $uid;
    $attr{gid} = $gid;
    $attr{mtime} = $mtime;

    my $file = Acme::Archive::Mbox::File->new($altname, $contents, %attr);
    push @{$self->{files}}, $file if $file;

    return $file;
}

=head2 get_files ()

Returns a list of AAM::File objects.

=cut

sub get_files {
    my $self = shift;
    return @{$self->{files}};
}

=head2 write (filename)

Write archive to a file

=cut

sub write {
    my $self = shift;
    my $mboxname = shift;
    
    my $mgr = Mail::Box::Manager->new;
    my $folder = $mgr->open($mboxname, type => 'mbox', create => 1, access => 'rw') or die "Could not create $mboxname";

    for my $file (@{$self->{files}}) {
        my $attach = Mail::Message::Body->new(  mime_type => 'application/octet-stream',
                                                data => $file->contents,
                                             );

        my $message = Mail::Message->build( From          => '"Acme::Archive::Mbox" <AAM@example.com>',
                                            To            => '"Anyone, really" <anyone@example.com>',
                                            Subject       => $file->name,
                                            'X-AAM-uid'   => $file->uid,
                                            'X-AAM-gid'   => $file->gid,
                                            'X-AAM-mode'  => $file->mode,
                                            'X-AAM-mtime' => $file->mtime,

                                            data => 'attached',
                                            attach => $attach, );
        $folder->addMessage($message);
    }
    $folder->write();
    $mgr->close($folder);
}

=head2 read (filename)

Read archive from a file.

=cut

sub read {
    my $self = shift;
    my $mboxname = shift;

    my $mgr = Mail::Box::Manager->new;
    my $folder = $mgr->open($mboxname, type => 'mbox') or die "Could not open $mboxname";
    my @messages = $folder->messages;
    for my $message (@messages) {
        my %attr;
        my $name = $message->get('Subject');
        for (qw/uid gid mode mtime/) {
            $attr{$_} = $message->get("X-AAM-$_");
        }
        my $contents = ($message->parts())[1]->decoded();

        $self->add_data($name, $contents, %attr);
    }
    $mgr->close($folder);
}

=head1 AUTHOR

Ian Kilgore, C<< <iank at cpan.org> >>

=head1 BUGS

=over 4

=item Undefined behavior in spades.  Anyone using this probably deserves it.

=item Fails to overwrite or truncate when creating archives

=item As Acme::Archive::Mbox does not store directories, directory
mode and ownership will not be preserved.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Archive::Mbox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Archive-Mbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Archive-Mbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Archive-Mbox>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Archive-Mbox/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Ian Kilgore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Acme::Archive::Mbox
