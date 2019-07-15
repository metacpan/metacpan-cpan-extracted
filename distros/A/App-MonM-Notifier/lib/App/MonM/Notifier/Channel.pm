package App::MonM::Notifier::Channel; # $Id: Channel.pm 59 2019-07-14 09:14:38Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel - monotifier channel base class

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::Notifier::Channel;

    my $channel = new App::MonM::Notifier::Channel;

    my $data = {
        id      => 1,
        to      => "recipient",
        subject => "Test message",
        message => "Content of the message",
    };

    my $ch_conf = {
        'fri' => '18:01-19',
        'from' => 'root@example.com',
        'host' => 'mail.example.com',
        'mon' => '7:35-17:45',
        'period' => '7:30-16:30',
        'port' => '25',
        'set' => [
          'User TeStUser',
          'Password MyPassword'
        ],
        'sun' => '-',
        'thu' => '16-18:01',
        'to' => 'test@example.com',
        'tue' => '15-19',
        'type' => 'Email',
        'wed' => '-'
    };

    my $status = $channel->process($data, $ch_conf);
    die($channel->error) unless $channel->status;

=head1 DESCRIPTION

This module provides channel base methods

=head2 new

    my $channel = new App::MonM::Notifier::Channel;

Returns the channel object

=head2 cleanup

    my $self = $channel->cleanup;

Cleaning up of working variables

=head2 config

    my $conf_hash = $channel->config;

Returns the channel configuration ($ch_conf)

=head2 data

    my $data = $channel->data;
    my $data = $channel->data( { ... } );

Sets/gets data structure

=head2 error

    my $error = $channel->error;
    my $error = $channel->error( "New error" );

Sets/gets error message

=head2 genId

    my $message_id = $self->genId(
            $self->data->{id} || 0,
            $self->data->{pubdate} || 0,
            $self->data->{to} || "anonymous",
        );

Return ID of message

=head2 message

    my $email = $channel->message;
    my $email = $channel->message( new Email::MIME );

Gets/sets the Email::MIME object

=head2 process

    my $status = $channel->process( $data, $ch_conf )
        or die($channel->error);

This method runs process of sending message to channel and returns
operation status.

See L</DATA> and L</DIRECTIVES> for details

=head2 status

    my $status = $channel->status;
    my $status = $channel->status( 1 ); # Sets the status value and returns it

Get/set BOOL status of the operation

=head2 type

    my $type = $channel->type;
    my $type = $channel->type( "File" );

Gets/sets the type value

=head1 DATA

It is a structure (hash), that can contain the following fields:

    'data' => {
        'channel'   => "MyEmail",
        'comment'   => "Comment",
        'errcode'   => 0,
        'errmsg'    => 'Ok',
        'expires'   => 1565599719,
        'id'        => 31,
        'message'   => "Message body",
        'pubdate'   => 1563007719,
        'status'    => 'NEW',
        'subject'   => "My message",
        'to'        => 'testuser'
    }

=over 4

=item B<channel>

Channel name

=item B<comment>

Comment string

=item B<errcode>

Error code

=item B<errmsg>

Error message

=item B<expires>

Expires time value

=item B<id>

Contains internal ID of the message. This ID is converted to an X-Id header

=item B<message>

Body of the message

=item B<pubdate>

The time of message publication

=item B<status>

Status of record (text formst). See L<App::MonM::Notifier::Const>

=item B<subject>

Subject of the message

=item B<to>

Recipient address or name

=back

=head2 DIRECTIVES

It is a structure (hash), that can contain the following fields:

=over 4

=item B<Charset>

Sets the charset

Default: utf-8

See also L<Email::MIME>

=item B<ContentType>

Sets the content type

Default: text/plain

See also L<Email::MIME>

=item B<Encoding>

Sets encoding (8bit, base64, quoted-printable)

Default: 8bit

See also L<Email::MIME>

=item B<Headers>

Container for MIME headers definitions

=item B<Type>

Defines type of channel

Allowed types: File, Command, Email

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<App::MonM>, L<Email::MIME>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<Email::MIME>

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
$VERSION = '1.01';

use Class::C3::Adopt::NEXT;
use Email::MIME;
use Compress::Raw::Zlib qw//; # CRC32

use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use base qw/
        App::MonM::Notifier::Channel::File
        App::MonM::Notifier::Channel::Email
        App::MonM::Notifier::Channel::Command
    /;

use constant {
    TIMEOUT     => 300, # 5 min timeout
    CONTENT_TYPE=> "text/plain",
    CHARSET     => "utf-8",
    ENCODING    => "8bit", # "base64"
    USERNAME    => "anonymous",
};

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {%args}, $class;
    return $self->cleanup;
}
sub cleanup {
    my $self = shift;
    $self->{config}  = {}; # Channel config
    $self->{status}  = 0; # 1 - Ok; 0 - Error
    $self->{error}   = ''; # Error message
    $self->{type}    = ''; # email/file/command
    $self->{message} = undef; # Message
    $self->{data}    = {};

    return $self;
}
sub config {
    my $self = shift;
    return $self->{config};
}
sub status {
    my $self = shift;
    my $v = shift;
    $self->{status} = $v if defined $v;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $v = shift;
    $self->{error} = $v if defined $v;
    return $self->{error};
}
sub type {
    my $self = shift;
    my $v = shift;
    $self->{type} = $v if defined $v;
    return $self->{type};
}
sub message {
    my $self = shift;
    my $v = shift;
    $self->{message} = $v if defined $v;
    return $self->{message};
}
sub data {
    my $self = shift;
    my $v = shift;
    $self->{data} = $v if defined $v;
    return $self->{data};
}
sub process {
    my $self = shift;
    my $data = shift;
    my $conf = shift;
    $self->cleanup;
    $self->{config} = $conf if ref($conf) eq 'HASH';
    $self->data($data) if ref($data) eq 'HASH';
    $self->type(lc(uv2null(value($conf, 'type'))));

    # Create message
    my $headers = hash($conf => "headers");
    my $from = value($conf, "from") // '';
    my %hset = (
            To      => value($conf, "to") || value($data, "to") || USERNAME,
            $from ? (From => $from) : (),
            Subject => value($data, "subject") || '',
        );
    if ($headers && is_hash($headers) && keys(%$headers)) {
        while (my ($k,$v) = each %$headers) {
            next unless defined $v;
            if (grep {lc($k) eq lc($_)} (qw/To From Subject/)) {
                $hset{ucfirst($k)} = $v;
            } else {
                $hset{$k} = $v;
            }
        }
    }

    # Create message object
    my $email = Email::MIME->create(
        header_str => [%hset],
    );
    $email->content_type_set( value($conf => "contenttype") // CONTENT_TYPE );
    $email->charset_set( value($conf => "charset") // CHARSET );
    $email->encoding_set( value($conf => "encoding") // ENCODING );

    # Add message content
    my $message = uv2null(value($data => "message"));
    $email->body_str_set($message);
    $self->message($email);

    # Go!
    $self->maybe::next::method();
    return $self->status;
}
sub genId {
    my $self = shift;
    my @arr = @_;
    unshift @arr, $$;
    my $text = join("|", @arr);
    my $short = time & 0x7FFFFF;
    my $crc8 = Compress::Raw::Zlib::crc32($text) & 0xFF;
    return hex(sprintf("%x%x",$short, $crc8));
}

1;

__END__
