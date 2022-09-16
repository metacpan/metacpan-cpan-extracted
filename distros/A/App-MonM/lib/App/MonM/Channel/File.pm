package App::MonM::Channel::File;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Channel::File - MonM file channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    <Channel MyFile>

        Type    File
        Enable  on

        # Real To Email address
        To      testuser@localhost

        # Schedule
        #At Sun-Sat[00:00-23:59]

        # MIME options
        #Encoding 8bit
        #    8bit, quoted-printable, 7bit, base64
        #ContentType text/plain
        #Charset utf-8

        # Output File Options
        #Dir      /path/to/my/messages
        #File     [DATETIME]-[ID].[EXT]

    </Channel>

=head1 DESCRIPTION

This module provides a method that writes the content
of the message to an external file

=over 4

=item B<sendmsg>

For internal use only!

=back

=head1 CONFIGURATION DIRECTIVES

The basic Channel configuration options (directives) detailed describes in L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=over 4

=item B<Dir>, B<Directory>

    Dir    /tmp

Defines path to save the message files

Default: your temp directory

=item B<File>, B<Filemask>

    File    [DATETIME]-[ID].[EXT]

Defines special mask of the message's filename

Default: "[DATETIME]-[ID].[EXT]"

Available variables:

    [ID] -- Internal ID of the message
    [TO] -- The real "to" field of message
    [RCPT], [RECIPIENT] -- Recipient (name, account, id, number and etc.)
    [EXT] -- file extension (default: msg)
    [TIME] -- Current time (in unix time format)
    [DATETIME] -- date and time in short-format (YYYMMDDHHMMSS)
    [DATE] -- Date in short-format (YYYMMDD)

=item B<From>

Sender address (Email)

=item B<To>

Recipient address (Email) or name

=item B<Type>

    Type    File

Required directive!

Defines type of channel. MUST BE set to "File" value

=back

About common directives see L<App::MonM::Channel/CONFIGURATION DIRECTIVES>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Compress::Raw::Zlib>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Compress::Raw::Zlib>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use File::Spec;

use CTK::ConfGenUtil;
use CTK::Util qw/ dformat date_time2dig date2dig /;
use App::MonM::Util qw/ set2attr /;

use constant {
    FILEEXT     => "msg",
    FILEMASK    => "[DATETIME]-[ID].[EXT]",
};

sub sendmsg {
    my $self = shift;
    return $self->maybe::next::method() unless $self->type eq 'file';
    my $message = $self->message;

    # Options
    my $options = set2attr($self->chconf) || {};
    #print App::MonM::Util::explain($options);

    # File
    my $filemask = value($self->chconf, "filemask") || value($self->chconf, "file") || FILEMASK;
    my $filename = dformat($filemask, {
            ID      => $self->message->msgid,
            TO      => $self->message->to,
            RCPT    => $self->message->recipient, RECIPIENT => $self->message->recipient,
            EXT     => FILEEXT,
            TIME    => time(), DATETIME=> date_time2dig(), DATE    => date2dig(),
        });
    my $dir = value($self->chconf, "directory") || value($self->chconf, "dir") || File::Spec->tmpdir;
    my $file;
    if (File::Spec->file_name_is_absolute($filename)) {
        $file = $filename;
    } else {
        unless (-e $dir and -w $dir) {
            $self->error(sprintf("Can't use directory: %s", $dir));
            return 0;
        }
        $file = File::Spec->catfile($dir, $filename);
    }

    # Save
    $message->save($file) or do {
        $self->error($message->error);
        return 0;
    };

    #printf "Send message %s to %s (%s) via %s\n", $self->message->msgid, $self->message->to, $self->message->recipient,  $self->type;

    return 1;
}

1;

__END__
