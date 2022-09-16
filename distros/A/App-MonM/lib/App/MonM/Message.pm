package App::MonM::Message;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Message - The MonM Message manager

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Message;

    my $message = App::MonM::Message->new(
            recipient => "myaccount",
            to      => 'to@example.com',
            from    => 'from@example.com',
            subject => "Test message",
            body    => "Body of test message",
        );

=head1 DESCRIPTION

This is an extension for the monm messages

=head2 new

    my $message = App::MonM::Message->new(
            recipient => "myaccount",
            to      => 'to@example.com',
            cc      => 'cc@example.com',
            bcc     => 'bcc@example.com',
            from    => 'from@example.com',
            subject => "Test message",
            body    => "Body of test message",
            headers => { # optional
                    "X-My-Header" => "test",
                },
            contenttype => "text/plain", # optional
            charset     => "utf-8", # optional
            encoding    => "8bit", # optional
            attachment  => [{ # See Email::MIME
                filename => "screenshot.png",
                type     => "image/png",
                encoding => "base64",
                disposition => "attachment",
                path     => "/tmp/screenshot.png",
            }],
        );

Create new message

    my $message = App::MonM::Message->new;
    $message->load("test.msg") or die $message->error;

Load message from file

=head2 body

Returns body of message

=head2 email

    my $email_object = $message->email;

Returns L<Email::MIME> object

    $message->email($email_object);

Sets L<Email::MIME> object

=head2 error

    my $error = $message->error;

Returns error string

    $message->error( "error text" );

Sets error string

=head2 from

Returns the "From" header

=head2 genId

    my $message_id = $message->genId('to@example.com',"Test message");

Generate new ID of message

=head2 load

    my $message = App::MonM::Message->new;
    $message->load("test.msg") or die $message->error;

Load message from file

=head2 msgid

    my $MessageId = $message->msgid;

Returns MessageId (X-Message-ID)

=head2 recipient

    my $recipient = $message->recipient;

Returns recipient

=head2 save

    $message->save("test.msg") or die $message->error;

Save message to file

=head2 subject

Returns the Subject of message

=head2 to

Returns the "To" header

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Email::MIME>

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

use Email::MIME;
use IO::File;

use CTK::Digest::FNV32a;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use App::MonM::Util qw/header_field_normalize slurp node2anode/;
use App::MonM::Const qw/HOSTNAME/;

use constant {
    CONTENT_TYPE    => "text/plain",
    CHARSET         => "utf-8",
    ENCODING        => "8bit", # "quoted-printable", "8bit", "base64"
    USERNAME        => "anonymous",
};

*TO_DEFAULT = sub {
    return sprintf('%s@%s', USERNAME, HOSTNAME());
};

my @CHARS = ('a'..'f', 0..9);
my %UNIQCNT;

sub new {
    my $class = shift;
    my %args = @_;

    my $self = bless {
            email => undef, # Email::SMTP object
            msgid => undef, # X-Message-ID
            recipient => "",
            error => "",
            fnv32a => CTK::Digest::FNV32a->new(),
        }, $class;

    # No any data - returns empty object (without email)
    return $self unless %args;

    # Headers
    my $headers = $args{headers} || {};
    my $to      = $args{to} || TO_DEFAULT();
    my $recipient = $args{recipient} || $to || USERNAME;
    my $subject = $args{subject};
    my %hset = (
            To      => $to =~ /\@/ ? $to : TO_DEFAULT(),
            Subject => $subject,
        );
    foreach my $h (qw/from cc bcc/) {
        my $uh = ucfirst($h);
        $hset{$uh} = $args{$h} if $args{$h} && $args{$h} =~ /\@/;
    }

    if ($headers && is_hash($headers) && keys(%$headers)) {
        while (my ($k,$v) = each %$headers) {
            next unless defined $v;
            $hset{header_field_normalize($k)} = $v;
        }
    }

    # Attributes
    my $contenttype = $args{contenttype} // CONTENT_TYPE;
    my $charset = $args{charset} // CHARSET;
    my $encoding = $args{encoding} // ENCODING;

    # Body content
    my $body = $args{body} // '';

    # Multiparted message
    my @parts;
    my $main_part = Email::MIME->create(
        attributes => {
            content_type => $contenttype,
            charset      => $charset,
            encoding     => $encoding,
            disposition  => "inline", #disposition  => "attachment",
        },
        body_str => $body,
    );
    push @parts, $main_part;

    # Attachments
    my $attachments = node2anode($args{attachment});
    foreach my $inatt (@$attachments) {
        my $filename = lvalue($inatt, "filename") || lvalue($inatt, "file");
        next unless $filename;
        my $path = lvalue($inatt, "path");
        next unless $path && -e $path;
        my $body = slurp($path, 1) or next;
        push @parts, Email::MIME->create(
            attributes => {
                filename     => $filename,
                name         => $filename,
                content_type => lvalue($inatt, "content_type") || lvalue($inatt, "type") // "application/octet-stream",
                encoding     => lvalue($inatt, "encoding") // "base64",
                disposition  => lvalue($inatt, "disposition") // "attachment",
            },
            body => $body,
        );
    }

    # Create message (single or multipart)
    my $email = Email::MIME->create(
        header_str => [%hset],
        parts      => [ @parts ],
    );

    # Add attributes and body for single message
    #$email->content_type_set($contenttype);
    #$email->charset_set($charset);
    #$email->encoding_set($encoding);
    #$email->body_str_set($body);

    # Add X-Message-ID
    $self->{msgid} = $self->genId($to, $recipient, $subject);
    $email->header_str_set("X-Message-ID" => $self->{msgid});

    # Add X-Recipient
    $self->{recipient} = $recipient;
    $email->header_str_set("X-Recipient" => $recipient);

    # Done
    $self->email($email);

    return $self;
}

sub email {
    my $self = shift;
    my $v = shift;
    $self->{email} = $v if defined $v;
    return $self->{email};
}
sub error {
    my $self = shift;
    my $v = shift;
    $self->{error} = $v if defined $v;
    return $self->{error};
}
sub msgid {
    my $self = shift;
    return $self->{msgid};
}
sub genId {
    my $self = shift;
    my @arr = @_;
    unshift @arr, $$;
    my $text = join("|", @arr);
    my $t = time;
    my $short = $t & 0x7FFFFF;
    my $fnv = $self->{fnv32a}->digest($text) & 0xFFFFFFFF;
    my $salt = join '', map {; $CHARS[rand @CHARS] } (0..6);
    my $u = exists $UNIQCNT{$t} ? ++$UNIQCNT{$t} : (%UNIQCNT = ($t => 0))[1];
    # hex(SHORT_TIME) . hex(TIME_UNIQ_CNT) . SALT . hex(FNV32a)
    return sprintf("%x%x%s%x",$short, $u, $salt, $fnv);
}
sub save {
    my $self = shift;
    my $file = shift;
    $self->error("");
    unless ($file) {
        $self->error("No file specified");
        return;
    }
    my $email = $self->email;
    unless ($email) {
        $self->error("No email object found");
        return;
    }

    my $fh = IO::File->new($file, "w");
    unless (defined $fh) {
        $self->error("Can't write file $file: $!");
        return;
    }

    $fh->binmode(); # ':raw:utf8'
    $fh->print($email->as_string);
    undef $fh;
    return 1;
}
sub load {
    my $self = shift;
    my $file = shift;
    $self->error("");
    unless ($file) {
        $self->error("No file specified");
        return;
    }
    unless (-e $file) {
        $self->error("No file found: $file");
        return;
    }
    my $size = -s $file;
    unless ($size) {
        $self->error("The file is empty: $file");
        return;
    }

    # Load file
    my $fh = IO::File->new($file, "r");
    unless (defined $fh) {
        $self->error("Can't load file $file: $!");
        return;
    }

    $fh->binmode(':raw:utf8');
    my $buf;
    read $fh, $buf, $size; # File::Slurp in a nutshell
    undef $fh;

    # Set email object
    my $email = Email::MIME->new($buf);
    $self->email($email);
    my $to = $email->header("To");

    # Add X-Recipient
    my $recipient = $email->header("X-Recipient") || $to || USERNAME;
    $self->{recipient} = $recipient;

    # Add X-Message-ID
    my $msgid = $email->header("X-Message-ID");
    unless ($msgid) {
        my $subject = $email->header("Subject");
        $msgid = $self->genId($to, $subject);
        $email->header_str_set("X-Message-ID" => $msgid);
    }
    $self->{msgid} = $msgid;

    return $self;
}
sub recipient {
    my $self = shift;
    return $self->{recipient};
}
sub to {
    my $self = shift;
    my $val = $self->email->header("To");
    return $val;
}
sub from {
    my $self = shift;
    my $val = $self->email->header("From");
    return $val;
}
sub subject {
    my $self = shift;
    my $val = $self->email->header("Subject");
    return $val;
}
sub body {
    my $self = shift;
    my $val = $self->email->body;
    return $val;
}

1;

__END__
