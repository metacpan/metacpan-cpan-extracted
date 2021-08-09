use strict;
use warnings;

use Test::Differences;
use Test::Fatal;
use Test::More 0.88;
use Test::Warnings;

use Courriel;
use Courriel::Builder;
use Courriel::Helpers;
use Email::Address::XS;
use Encode qw( encode is_utf8 );
use Scalar::Util qw( blessed );

## no critic (InputOutput::RequireCheckedSyscalls)
binmode $_, ':encoding(UTF-8)'
    for map { Test::Builder->new->$_ }
    qw( output failure_output todo_output );
## use critic

my $crlf = $Courriel::Helpers::CRLF;

{
    my $text = <<'EOF';
Subject:

This is the body
EOF

    my $email = Courriel->parse( text => \$text );
    ok( defined $email->subject, 'empty subject is defined' );
}

{
    my $text = <<'EOF';
Subject: Foo

This is the body
EOF

    my $email = Courriel->parse( text => \$text );

    is( $email->subject, 'Foo', 'got the right subject' );

    is( $email->part_count, 1, 'email has one part' );

    is_deeply(
        _headers_as_arrayref($email),
        [
            Subject                     => 'Foo',
            'Content-Transfer-Encoding' => '8bit',
        ],
        'headers were parsed correctly'
    );

    my ($part) = $email->parts;
    is(
        $part->content_type->mime_type,
        'text/plain',
        'email with no content type defaults to text/plain'
    );

    is(
        $part->content_type->charset,
        undef,
        'email with no charset does not get a default charset'
    );

    is(
        $part->encoding,
        '8bit',
        'email with no encoding defaults to 8bit'
    );

    is_deeply(
        $part->content,
        $text,
        'content for part was parsed correctly'
    );

    isa_ok( $email->datetime, 'DateTime' );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306


--20cf3071cfd06272ae04a46c9306
Content-Type: text/plain; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.

It has some *bold* text.

--20cf3071cfd06272ae04a46c9306
Content-Type: text/html; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

--20cf3071cfd06272ae04a46c9306--
EOF

    my $original = $text;

    my $email = Courriel->parse( text => \$text );

    is( $email->part_count, 2, 'email has two parts' );

    is_deeply(
        _headers_as_arrayref($email),
        [
            'MIME-Version' => '1.0',
            'Date'         => 'Sun, 29 May 2011 11:22:22 -0500',
            'Message-ID'   =>
                '<BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>',
            'Subject'      => 'Testing',
            'From'         => 'Dave Rolsky <autarch@gmail.com>',
            'To'           => 'Dave Rolsky <autarch@urth.org>',
            'Content-Type' =>
                'multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306',
        ],
        'headers were parsed correctly'
    );

    my @parts = $email->parts;

    is(
        $parts[0]->content_type->mime_type,
        'text/plain',
        'first part is text/plain'
    );

    my $plain = <<'EOF';
This is a test email.

It has some *bold* text.

EOF

    _compare_text(
        $parts[0]->content,
        $plain,
        'plain content is as expected',
    );

    is(
        $parts[1]->content_type->mime_type,
        'text/html',
        'second part is text/html'
    );

    my $html = <<'EOF';
This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

EOF

    _compare_text(
        $parts[1]->content,
        $html,
        'html content is as expected',
    );

    is(
        $email->plain_body_part,
        $parts[0],
        'found plain body part'
    );

    is(
        $email->html_body_part,
        $parts[1],
        'found html body part'
    );

    is(
        $email->datetime->strftime('%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 22,
            second    => 22,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'email datetime is parsed from Date header correctly'
    );

    is_deeply(
        [ sort map { $_->address } $email->recipients ],
        ['autarch@urth.org'],
        'recipients includes all expected addresses',
    );

    my $string = $original;
    $string =~ s/^.+?\n//;    # remove mbox marker line
    $string
        =~ s/(\n\nThis is a test email)/\nContent-Transfer-Encoding: 8bit$1/g;
    $string =~ s/\n/$crlf/g;

    # The header formatter adds quotes around phrases in email addresses.
    $string =~ s/: Dave Rolsky/: "Dave Rolsky"/g;

    _compare_text(
        $email->as_string,
        $string,
        'as_string output matches original email'
    );
}

{
    my $text = <<'EOF';
Received: from urth.org ([127.0.0.1])
    by localhost (urth.org [127.0.0.1]) (amavisd-new, port 10024)
    with ESMTP id LdGtFbrMk+AE for <autarch@urth.org>;
    Fri, 27 May 2011 11:24:48 -0500 (CDT)
Received: from exploreveg.org (exploreveg.org [173.11.48.51])
    (using TLSv1 with cipher ADH-AES256-SHA (256/256 bits))
    (No client certificate requested)
    by urth.org (Postfix) with ESMTPS id 08B6A171735
    for <autarch@urth.org>; Fri, 27 May 2011 11:24:44 -0500 (CDT)
MIME-Version: 1.0
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->datetime->strftime('%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 27,
            hour      => 11,
            minute    => 24,
            second    => 44,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'email datetime is parsed from Received header correctly'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Resent-Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->datetime->strftime('%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 22,
            second    => 23,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'email datetime is parsed from Resent-Date header correctly'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Resent-Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain
Content-Transfer-Encoding: base64

QmxhbmRpdGlpcyBhbWV0IHF1YWVyYXQgb21uaXMgdW5kZS4gTW9sbGl0aWEgb21uaXMgcXVhcyBp
bnZlbnRvcmUgZG9sb3J1bSBxdWkgZXQgYXNwZXJpb3Jlcy4gRmFjaWxpcyBhdCBhY2N1c2FtdXMg
bWludXMgdmVyaXRhdGlzIGltcGVkaXQgZG9sb3IuIFZlbGl0IG9tbmlzIG9mZmljaWEgdXQgdm9s
dXB0YXRlbSB0ZW1wb3JlIHZvbHVwdGF0dW0gc2l0IGFjY3VzYW50aXVtLiBQZXJmZXJlbmRpcyBl
eHBsaWNhYm8gbmloaWwgc3VudCBzZWQuDQoNClJlbSBkb2xvcmUgcmVwZWxsZW5kdXMgbW9kaSBu
aWhpbCBkb2xvcmVtIGhhcnVtIHZvbHVwdGFzIG5vbi4gRXNzZSBzaW50IGV4ZXJjaXRhdGlvbmVt
IHNpbWlsaXF1ZSBhbGlhcyBldC4gRWl1cyBhdXRlbSBhbGlxdWlkIGNvbnNlcXVhdHVyIG5hbSBo
YXJ1bSBmdWdpYXQu
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->plain_body_part->encoding,
        'base64',
        'encoding is set from parsed header',
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>, John Smith <foo@example.com>
CC: "Whatever goes here" <what@example.com>, Jill Smith <jill@example.com>
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->from->address,
        'autarch@gmail.com',
        'from returns the right address'
    );

    is_deeply(
        [ sort map { $_->address } $email->to ],
        [
            'autarch@urth.org',
            'foo@example.com',
        ],
        'to includes all expected addresses',
    );

    is_deeply(
        [ sort map { $_->address } $email->cc ],
        [
            'jill@example.com',
            'what@example.com'
        ],
        'cc includes all expected addresses',
    );

    is_deeply(
        [ sort map { $_->address } $email->recipients ],
        [
            'autarch@urth.org',
            'foo@example.com',
            'jill@example.com',
            'what@example.com'
        ],
        'recipients includes all expected addresses',
    );

    is_deeply(
        [ sort map { $_->address } $email->participants ],
        [
            'autarch@gmail.com',
            'autarch@urth.org',
            'foo@example.com',
            'jill@example.com',
            'what@example.com'
        ],
        'participants includes all expected addresses',
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
Content-Type: text/plain

Whatever
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->from,
        undef,
        'from returns undef'
    );

    is_deeply(
        [ map { $_->address } $email->to ],
        [],
        'to return an empty array ref',
    );

    is_deeply(
        [ map { $_->address } $email->cc ],
        [],
        'cc return an empty array ref',
    );

    is_deeply(
        [ map { $_->address } $email->participants ],
        [],
        'participants return an empty array ref',
    );

    is_deeply(
        [ map { $_->address } $email->recipients ],
        [],
        'recipients return an empty array ref',
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306


--20cf3071cfd06272ae04a46c9306
Content-Type: text/plain; charset=ISO-8859-1

This is a test email.

It has some *bold* text.

--20cf3071cfd06272ae04a46c9306
Content-Type: text/html; charset=ISO-8859-1
Content-Disposition: attachment;
  filename="html-attachment.html";
  creation-date="Sun, 29 May 2011 11:01:02 -0500";
  modification-date="Sun, 29 May 2011 11:01:03 -0500";
  read-date="Sun, 29 May 2011 11:01:04 -0500"

This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

--20cf3071cfd06272ae04a46c9306--
EOF

    my $email = Courriel->parse( text => \$text );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );

    ok( $attachment, 'found attachment' );

    is(
        $attachment->filename,
        'html-attachment.html',
        'got filename from content disposition'
    );

    is(
        $attachment->disposition->creation_datetime->strftime(
            '%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 1,
            second    => 2,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'got creation_datetime from content disposition'
    );

    is(
        $attachment->disposition->modification_datetime->strftime(
            '%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 1,
            second    => 3,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'got modification_datetime from content disposition'
    );

    is(
        $attachment->disposition->read_datetime->strftime('%{datetime} %Z'),
        DateTime->new(
            year      => 2011,
            month     => 5,
            day       => 29,
            hour      => 11,
            minute    => 1,
            second    => 4,
            time_zone => '-0500',
        )->set_time_zone('UTC')->strftime('%{datetime} %Z'),
        'got read_datetime from content disposition'
    );
}

{
    my $email = build_email(
        plain_body('foo'),
        attach( content => 'some content' ),
        attach( content => 'some more content' ),
    );

    is(
        $email->content_type->mime_type,
        'multipart/mixed',
        'email is multipart/mixed'
    );

    my @parts = $email->all_parts_matching( sub {1} );

    is(
        scalar @parts, 4,
        'email has 4 parts'
    );

    my $clone = $email->clone_without_attachments;

    is(
        $clone->content_type->mime_type,
        'text/plain',
        'after clone type is text/plain'
    );

    @parts = $clone->all_parts_matching( sub {1} );

    is(
        scalar @parts, 1,
        'email has 1 part after clone'
    );

    is(
        $parts[0]->encoding, 'base64',
        'part is base64 encoded'
    );

    is_deeply(
        [
            map { $_->value }
                $parts[0]->headers->get('Content-Transfer-Encoding')
        ],
        ['base64'],
        'Content-Transfer encoding is base64'
    );
}

{
    my $email = build_email(
        plain_body('foo'),
        html_body('bar'),
        attach( content => 'some content' ),
        attach( content => 'some more content' ),
    );

    is(
        $email->content_type->mime_type,
        'multipart/mixed',
        'email is multipart/mixed'
    );

    my @parts = $email->all_parts_matching( sub {1} );

    is(
        scalar @parts, 6,
        'email has 6 parts'
    );

    my $clone = $email->clone_without_attachments;

    is(
        $clone->content_type->mime_type,
        'multipart/alternative',
        'after clone type is multipart/alternative'
    );

    @parts = $clone->all_parts_matching( sub {1} );

    is(
        scalar @parts, 3,
        'email has 3 parts after clone'
    );

    my $plain = $clone->plain_body_part;
    is(
        $plain->encoding, 'base64',
        'plain part is base64 encoded'
    );

    is_deeply(
        [
            map { $_->value }
                $plain->headers->get('Content-Transfer-Encoding')
        ],
        ['base64'],
        'plain part Content-Transfer encoding is base64'
    );

    my $html = $clone->html_body_part;
    is(
        $html->encoding, 'base64',
        'html part is base64 encoded'
    );

    is_deeply(
        [
            map { $_->value } $html->headers->get('Content-Transfer-Encoding')
        ],
        ['base64'],
        'html part Content-Transfer encoding is base64'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306


--20cf3071cfd06272ae04a46c9306
Content-Type: TEXT/PLAIN; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.

It has some *bold* text.

--20cf3071cfd06272ae04a46c9306
Content-Type: tEXT/htML; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

--20cf3071cfd06272ae04a46c9306--
EOF

    my $email = Courriel->parse( text => \$text );

    ok(
        $email->plain_body_part,
        'ignored case of mime type when finding plain body part'
    );
    ok(
        $email->html_body_part,
        'ignored case of mime type when finding html body part'
    );

    is(
        $email->plain_body_part->content_type->mime_type,
        'text/plain',
        'ContentType->mime_type method returns all lower case value'
    );

    is(
        $email->plain_body_part->content_type->as_header_value,
        'TEXT/PLAIN; charset=ISO-8859-1',
        'header value preserves original casing of mime type'
    );
}

{
    my $text = <<'EOF';
From: Dave Rolsky <autarch@gmail.com>
MIME-Version: 1.0
Resent-Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

foo
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->headers->get('From')->value,
        'Dave Rolsky <autarch@gmail.com>',
        'From header at beginning of mail is not stripped by mbox separator removal',
    );
}
{
    my $text = <<'EOF';
From
  blah blah blah
MIME-Version: 1.0
Resent-Date: Sun, 29 May 2011 11:22:23 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: text/plain

foo
EOF

    is(
        exception {
            Courriel->parse( text => \$text );
        },
        undef,
        'mbox separator which contains a newline is parser correctly'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: multipart/alternative; boundary=20cf3071cfd06272ae04a46c9306

WTF, just a single part.
EOF

    my $email;
    is(
        exception {
            $email = Courriel->parse( text => \$text );
        },
        undef,
        'multipart mime type with single part body still parses'
    );

    is(
        $email->part_count,
        1,
        'email has one part'
    );
}

{
    my $text = <<"EOF";
Subject: Foo
Content-Type: text/plain; format=flowed; delsp=yes; charset=utf-8
Content-Transfer-Encoding: 8bit

Vel\x{00E1}zquez
EOF

    my $email = Courriel->parse( text => \$text, is_character => 1 );

    my $content = $email->plain_body_part->content;
    $content =~ s/[\r\n]//g;

    is(
        $content,
        "Vel\x{00E1}zquez",
        '8bit encoded body (marked as utf8) ends up decoded properly'
    );

    ok(
        is_utf8($content),
        'content ends up marked as is_utf8'
    );
}

{
    my $text = <<"EOF";
Subject: Foo
Content-Type: text/plain; format=flowed; delsp=yes; charset=utf-8
Content-Transfer-Encoding: 8bit

Vel\x{00E1}zquez
EOF

    $text = encode( 'utf-8', $text );

    my $email = Courriel->parse( text => \$text, is_character => 0 );

    my $content = $email->plain_body_part->content;
    $content =~ s/[\r\n]//g;

    is(
        $content,
        "Vel\x{00E1}zquez",
        '8bit encoded body (marked as binary) ends up decoded properly'
    );

    ok(
        is_utf8($content),
        'content ends up marked as is_utf8'
    );
}

{
    my $text = <<'EOF';
From autarch@gmail.com Sun May 29 11:22:29 2011
MIME-Version: 1.0
Date: Sun, 29 May 2011 11:22:22 -0500
Message-ID: <BANLkTimjF2BDbOKO_2jFJsp6t+0KvqxCwQ@mail.gmail.com>
Subject: Testing
From: Dave Rolsky <autarch@gmail.com>
To: Dave Rolsky <autarch@urth.org>
Content-Type: MULTIPART/ALTERNATIVE; BOUNDARY=20cf3071cfd06272ae04a46c9306


--20cf3071cfd06272ae04a46c9306
Content-Type: text/plain; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.

It has some *bold* text.

--20cf3071cfd06272ae04a46c9306
Content-Type: text/html; charset=ISO-8859-1
Content-Disposition: inline

This is a test email.<br><br>It has some <b>bold</b> text.<br><br>

--20cf3071cfd06272ae04a46c9306--
EOF

    my $email = Courriel->parse( text => \$text );

    is(
        $email->content_type->attribute_value('boundary'),
        '20cf3071cfd06272ae04a46c9306',
        'attribute name is case insensitive on lookup'
    );

    is(
        $email->content_type->attribute_value('BOUNDARY'),
        '20cf3071cfd06272ae04a46c9306',
        'attribute name is case insensitive on lookup'
    );

    is(
        $email->content_type->attribute('boundary')->name,
        'BOUNDARY',
        'HeaderAttribute object name preserves original casing'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        from('autarch@urth.org'),
        to(
            'autarch@urth.org', Email::Address::XS->parse('bob@example.com')
        ),
        cc(
            'jane@example.com', Email::Address::XS->parse('joe@example.com')
        ),
        header( 'X-Foo' => 42 ),
        header( 'X-Bar' => 84 ),
        plain_body('The body of the message')
    );

    my $string = q{};
    my $output = sub { $string .= $_ for @_ };

    $email->stream_to( output => $output );

    like(
        $string, qr/Subject: Test Subject/,
        'stream_to coderef - Subject is correct'
    );
    like(
        $string, qr/\r\n\r\nVGhlIGJvZHkgb2YgdGhlIG1lc3NhZ2U=/,
        'stream_to coderef - body is correct'
    );

    $string = q{};

    ## no critic (InputOutput::RequireCheckedOpen, InputOutput::RequireCheckedSyscalls, InputOutput::RequireBriefOpen)
    open my $fh, '>', \$string;

    $email->stream_to( output => $fh );

    like(
        $string, qr/Subject: Test Subject/,
        'stream_to filehandle - Subject is correct'
    );
    like(
        $string, qr/\r\n\r\nVGhlIGJvZHkgb2YgdGhlIG1lc3NhZ2U=/,
        'stream_to filehandle - body is correct'
    );

    $string = q{};

    $email->stream_to( output => Printable->new( \$string ) );

    like(
        $string, qr/Subject: Test Subject/,
        'stream_to object - Subject is correct'
    );
    like(
        $string, qr/\r\n\r\nVGhlIGJvZHkgb2YgdGhlIG1lc3NhZ2U=/,
        'stream_to object - body is correct'
    );
}

done_testing();

sub _headers_as_arrayref {
    my $email = shift;

    return [ map { blessed($_) ? $_->value : $_ } $email->headers->headers ];
}

sub _compare_text {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    for ( $got, $expect ) {
        s/$Courriel::Helpers::LINE_SEP_RE/$crlf/g;
        s/$crlf$crlf$crlf+/$crlf$crlf/g;
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    eq_or_diff( $got, $expect, $desc );
}

{
    package Printable;

    sub new {
        my $stringref = $_[1];

        return bless $stringref, $_[0];
    }

    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    sub print {
        my $self = shift;

        ${$self} .= $_ for @_;
    }
}
