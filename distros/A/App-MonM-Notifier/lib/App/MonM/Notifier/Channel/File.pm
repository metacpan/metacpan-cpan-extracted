package App::MonM::Notifier::Channel::File; # $Id: File.pm 60 2019-07-14 09:57:26Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::File - monotifier file channel

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    <Channel MyFile>
        Type    File

        # Real To and From
        To      testuser
        From    root

        # File options
        #Encoding base64
        #Dir      /path/to/messages/dir
        #File     [TO]_[DATETIME]_[ID].[EXT]

        <Headers>
            X-Foo foo
            X-Bar bar
        </Headers>
    </Channel>

=head1 DESCRIPTION

This module provides a method that writes the content
of the message to an external file

=head2 DIRECTIVES

=over 4

=item B<Directory>, B<Dir>

Defines path to save the message files

Default: your temp directory

=item B<Filemask>, B<File>

Defines special mask of the message's filename

Default: "[TO]_[DATETIME]_[ID].[EXT]"

Available variables:

    - ID -- Internal ID of the message
    - TO -- The real "to" field
    - EXT -- file extension (default: msg)
    - TIME -- Current time (in unix time format)
    - DATETIME -- date and time in short-format (YYYMMDDHHMMSS)
    - DATE -- Date in short-format (YYYMMDD)

=item B<From>

Sender address or name

=item B<To>

Recipient address or name

=item B<Type>

Defines type of channel. MUST BE set to "File" value

=back

About other options (base) see L<App::MonM::Notifier::Channel/DIRECTIVES>

=head2 METHODS

=over 4

=item B<process>

For internal use only!

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Compress::Raw::Zlib>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM::Notifier>, L<App::MonM::Notifier::Channel>, L<Compress::Raw::Zlib>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.02';

use File::Spec;
use IO::File;

use CTK::ConfGenUtil;
use CTK::Util qw/ dformat date_time2dig date2dig /;

use constant {
    FILEEXT     => "msg",
    FILEMASK    => "[TO]_[DATETIME]_[ID].[EXT]",
};

sub process {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type eq 'file';
    my $message = $self->message;
    unless ($message) {
        $self->error("Incorrect Email::MIME object");
        return;
    }
    my $message_id = $self->genId(
            $self->data->{id} || 0,
            $self->data->{pubdate} || 0,
            $self->data->{to} || "anonymous",
        );

    my $filemask = value($self->config, "filemask") || value($self->config, "file") || FILEMASK;
    my $filename = dformat( $filemask, {
                ID      => $message_id,
                TO      => $self->data->{to},
                EXT     => FILEEXT,
                TIME    => time(),
                DATETIME=> date_time2dig(),
                DATE    => date2dig(),
            } );
    my $dir = value($self->config, "directory") || value($self->config, "dir") || File::Spec->tmpdir;
    my $file;
    if (File::Spec->file_name_is_absolute($filename)) {
        $file = $filename;
    } else {
        unless (-e $dir and -w $dir) {
            $self->error(sprintf("Can't use directory: %s", $dir));
            return;
        }
        $file = File::Spec->catfile($dir, $filename);
    }

    my $fh = IO::File->new($file, "w");
    if (defined $fh) {
        $fh->binmode();
        $fh->print($message->as_string);
        undef $fh;
    } else {
        $self->error("Can't use FileHandle handler for writing file $file: $!");
        return
    }

    return $self->status(1);
}

1;

__END__
