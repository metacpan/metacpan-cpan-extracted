package App::MonM::Notifier::Channel::File; # $Id: File.pm 35 2017-11-27 14:16:09Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::File - monotifier file channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Channel;

    # Create channel object
    my $channel = new App::MonM::Notifier::Channel;

    # Send message via file channel
    $channel->file(
        {
            id      => 1,
            to      => "anonymous",
            from    => "sender",
            subject => "Test message",
            message => "Content of the message",
            headers => {
                       "X-Foo"  => "Extended eXtra value",
                },
        },
        {
            encoding => 'base64', # Default: 8bit
            content_type => undef, # Default: text/plain
            charset => undef, # Default: utf-8

            dir => '.', # Default: your temp directory
            filemask => "monotifier.msg", # Default: "[TO]_[ID]_[CRC16].[EXT]"
        }) or warn( $channel->error );

    # See error
    print $channel->error unless $channel->status;


=head1 DESCRIPTION

This module provides "file" method that writes the content
of the message to an external file

    my $status = $channel->file( $data, $options );

The $data structure (hashref) describes body of message, the $options
structure (hashref) describes parameters of the connection via external modules

=head2 DATA

It is a structure (hash), that can contain the following fields:

=over 8

=item B<id>

Contains internal ID of the message. This ID is converted to an X-Id header

=item B<to>

Recipient address or name

=item B<from>

Sender address or name

=item B<subject>

Subject of the message

=item B<message>

Body of the message

=item B<headers>

Optional field. Contains eXtra headers (extension headers). For example:

    headers => {
            "bcc" => "bcc\@example.com",
            "X-Mailer" => "My mailer",
        }

=back

=head2 OPTIONS

It is a structure (hash), that can contain the following fields:

=over 8

=item B<dir>

Defines path to save the message file

Default: your temp directory

=item B<filemask>

Defines special mask of the message's filename.
The mask consists of directives like [NAME].

Supported directives:

 - ID -- Internal ID of the message (see id field)
 - TO -- Normalized "to" field
 - CRC, CRC8, CRC16, CRC32 -- Check-codes of the message
 - EXT -- file extension (default: msg)
 - TIME -- Current time (in unix time format)

Default: "[TO]_[ID]_[CRC16].[EXT]"

=back

About other options (base) see L<App::MonM::Notifier::Channel/OPTIONS>

=head2 METHODS

=over 8

=item B<init>

For internal use only!

Called from base class. Returns initialize structure

=item B<handler>

For internal use only!

Called from base class. Returns status of the operation

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<Compress::Raw::Zlib>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<FileHandle>, L<App::MonM::Notifier::Channel>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Compress::Raw::Zlib qw//;
use File::Spec qw//;
use FileHandle;

use vars qw/$VERSION/;
$VERSION = '1.01';

use constant {
    FILEEXT     => "msg",
    FILEMASK    => "[TO]_[ID]_[CRC16].[EXT]",
};

sub init {
    return (
        type => "File",
        validation => {
                data => {
                        id  => {
                                optional    => 1,
                                regexp      => qr/^[0-9a-z]+$/i,
                                minlength   => 0,
                                maxlength   => 128,
                                type        => "str",
                                error       => "Field \"id\" incorrect",
                            },
                        to  => {
                                optional    => 0,
                                #regexp      => qr//,
                                minlength   => 1,
                                maxlength   => 255,
                                type        => "str",
                                error       => "Field \"to\" incorrect",
                            },
                    },
                options => {
                        dir  => {
                                optional    => 1,
                                #regexp      => qr//,
                                minlength   => 1,
                                maxlength   => 1024,
                                type        => "str",
                                error       => "Option \"dir\" incorrect",
                            },
                        filemask  => {
                                optional    => 1,
                                #regexp      => qr//,
                                minlength   => 1,
                                maxlength   => 255,
                                type        => "str",
                                error       => "Option \"filemask\" incorrect",
                            },
                    },
            },
    )
}
sub handler {
    my $self = shift;
    my $data = shift;
    my $options = shift;

    #print Dumper([$self, $data, $options]);

    my $filemask = $options->{filemask} // FILEMASK;
    my $dir      = $options->{dir} // File::Spec->tmpdir;
    unless (-e $dir and -w $dir) {
        return $self->error(sprintf("Can't use directory: %s", $dir));
    }
    my $tm = time;
    my $id = uv2zero(value($data=>"id")) || $tm;
    my $to = value($data => "to");
    return $self->error("Field \"to\" incorrect") unless(defined($to) && length($to));
    my $from = value($data => "from") || '';
    my $subject = uv2null(value($data => "subject"));
    my $message = uv2null(value($data => "message"));


    my $crc;
    {
        use bytes;
        $crc = Compress::Raw::Zlib::crc32(join("|", ($to, $from, $subject, $message)));
    }
    my $crc8 = $crc & 0xFF;
    my $crc16 = $crc & 0xFFFF;

    my $fto = $to;
    $fto =~ s/[^0-9a-z_\-\.]//ig;
    my $filename = dformat( $filemask, {
                ID      => $id,
                TO      => $fto,
                CRC     => $crc,
                CRC8    => $crc8,
                CRC16   => $crc16,
                CRC32   => $crc,
                EXT     => FILEEXT,
                TIME    => $tm,
            } );
    my $file = catfile($dir, $filename);

    #print $filemask, "\n", $dir, "\n", $file, "\n";

    my $fh = FileHandle->new($file, "w");
    if (defined $fh) {
        $fh->binmode();
        my $prx;
        $options->{io} = \$prx;
        $self->default($data, $options);
        $fh->print($prx) if defined $prx;
        undef $fh; # automatically closes the file
    } else {
        return $self->error("Can't use FileHandle handler for writing file $file: $!");
    }
    1;
}

1;
