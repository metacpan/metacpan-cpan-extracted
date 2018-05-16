use strict;
use warnings;

use utf8;
use Test::Differences;
use Test::Fatal;
use Test::More 0.88;
use Test::Warnings;

use Courriel::Builder;
use Courriel::Headers;
use Courriel::Helpers;
use Scalar::Util qw( blessed );

## no critic (InputOutput::RequireCheckedSyscalls)
binmode $_, ':encoding(UTF-8)'
    for map { Test::Builder->new->$_ }
    qw( output failure_output todo_output );
## use critic

my $crlf = $Courriel::Helpers::CRLF;

my $hola = "\x{00A1}Hola, se\x{00F1}or!";

{
    my $h = Courriel::Headers->new;
    is_deeply(
        _headers_as_arrayref($h),
        [],
        'can make an empty headers object'
    );

    $h->add( Subject => 'Foo bar' );

    is_deeply(
        _headers_as_arrayref($h),
        [ Subject => 'Foo bar' ],
        'added Subject header'
    );

    is_deeply(
        [ map { $_->value } $h->get('subject') ],
        ['Foo bar'],
        'got subject header (name is case-insensitive)'
    );

    is_deeply(
        [ $h->get_values('subject') ],
        ['Foo bar'],
        'got subject header with get_values method'
    );

    is_deeply(
        [ $h->get_values('no-such-header') ],
        [],
        'get_values returns empty list for nonexistent header'
    );

    $h->add( 'Content-Type' => 'text/plain' );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Subject        => 'Foo bar',
            'Content-Type' => 'text/plain',
        ],
        'added Content-Type header'
    );

    $h->add( 'Subject' => 'Part 2' );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Subject        => 'Foo bar',
            Subject        => 'Part 2',
            'Content-Type' => 'text/plain',
        ],
        'added another subject header and it shows up after first subject'
    );

    is_deeply(
        [ map { $_->value } $h->get('subject') ],
        [ 'Foo bar', 'Part 2' ],
        'got all subject headers'
    );

    my $string = <<'EOF';
Subject: Foo bar
Subject: Part 2
Content-Type: text/plain
EOF

    $string =~ s/\n/$crlf/g;

    is(
        $h->as_string,
        $string,
        'got expected header string'
    );

    $h->remove('Subject');

    is_deeply(
        _headers_as_arrayref($h),
        [
            'Content-Type' => 'text/plain',
        ],
        'removed Subject headers'
    );

    $string = <<'EOF';
Content-Type: text/plain
EOF

    $string =~ s/\n/$crlf/g;

    is(
        $h->as_string,
        $string,
        'got expected header string'
    );
}

{
    my $headers = <<'EOF';
Foo: 1
Bar: 2
Baz: 3
EOF

    $headers =~ s/\n/$crlf/g;

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Foo => 1,
            Bar => 2,
            Baz => 3,
        ],
        'parsed simple headers'
    );
}

{
    my $h = Courriel::Headers->new;

    $h->add( Subject => ' test' );

    is(
        $h->as_string,
        "Subject:  test\r\n",
        'Headers prefixed by whitespace are not blank'
    );
}

{
    my ( $val, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; test1=simple; test2="quoted string"});

    is( $val, 'foo/bar', 'got correct value for header with attributes' );
    is_deeply(
        _attributes_as_hashref($attrs), {
            test1 => 'simple',
            test2 => 'quoted string',
        },
        'parsed attributes with simple values correctly'
    );
}

{
    my ( $val, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; test1='single'; test2="double"});

    is( $val, 'foo/bar', 'got correct value for header with attributes' );
    is_deeply(
        _attributes_as_hashref($attrs), {
            test1 => 'single',
            test2 => 'double',
        },
        'parsed attributes with simple values correctly'
    );
}

{
    my ( $val, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; test1="has \\"escaped \\vals"; test2="contains ' single \\quote"}
        );

    is( $val, 'foo/bar', 'got correct value for header with attributes' );
    is_deeply(
        _attributes_as_hashref($attrs), {
            test1 => q{has "escaped vals},
            test2 => q{contains ' single quote},
        },
        'parsed attributes with weird values correctly'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; val*0=foo; val*1=bar});

    is_deeply(
        _attributes_as_hashref($attrs), {
            val => 'foobar',
        },
        'parsed attribute continuation correctly'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; val*0="foo bar"; val*1=" baz buz"});

    is_deeply(
        _attributes_as_hashref($attrs), {
            val => 'foo bar baz buz',
        },
        'parsed quoted attribute continuation correctly'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; val*0=foo; val*1=" bar"});

    is_deeply(
        _attributes_as_hashref($attrs), {
            val => 'foo bar',
        },
        'parsed partially quoted attribute continuation correctly'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; val*=UTF-8'en-gb'Some%20text%20with%20encoding});

    my $attr = $attrs->{val};

    is_deeply(
        [
            $attr->value,
            $attr->charset,
            $attr->language,
        ],
        [
            'Some text with encoding',
            'UTF-8',
            'en-gb',
        ],
        'parsed encoded attribute correctly'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{foo/bar; val*=UTF-8''%e4%b8%80%e4%b8%80});

    my $attr = $attrs->{val};

    is_deeply(
        [
            $attr->value,
            $attr->charset,
            $attr->language,
        ],
        [
            "\x{4E00}\x{4E00}",
            'UTF-8',
            undef,
        ],
        'parsed encoded chinese attribute correctly, with no language'
    );
}

{
    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes(
        q{text/plain; name*=utf-8''Iv%C3%A1n%20F.txt});

    my $attr = $attrs->{name};

    is_deeply(
        [
            $attr->value,
            $attr->charset,
            $attr->language,
        ],
        [
            "Iv\x{00E1}n F.txt",
            'UTF-8',
            undef,
        ],
        'parsed encoded European attribute correctly, with no language'
    );
}

{
    my $extended = <<'EOF';
foo/bar;
  val*0*=UTF-8'en-gb'Some%20text%20with%20encoding;
  val*1=" but now it's quoted and then ";
  val*2=simple;
  val*3*=%20then%20hex%20simple;
EOF

    my ( undef, $attrs )
        = Courriel::Helpers::parse_header_with_attributes($extended);

    my $attr = $attrs->{val};

    is_deeply(
        [
            $attr->value,
            $attr->charset,
            $attr->language,
        ],
        [
            q{Some text with encoding but now it's quoted and then simple then hex simple},
            'UTF-8',
            'en-gb',
        ],
        'parsed encoded attribute with continuations correctly'
    );
}

{
    my ( $value, $attrs );

    is(
        exception {
            ( $value, $attrs )
                = Courriel::Helpers::parse_header_with_attributes(
                q{foo/bar;});
        },
        undef,
        'no exception for trailing semi-colon on header that can have attributes'
    );

    is_deeply(
        [ $value, $attrs ],
        [ 'foo/bar', {} ],
        'handled trailing semi-colon correctly (parsed as having no attributes'
    );
}

{
    my ( $value, $attrs );

    is(
        exception {
            ( $value, $attrs )
                = Courriel::Helpers::parse_header_with_attributes(
                q{foo/bar; bad});
        },
        undef,
        'no exception for bad attribute syntax'
    );

    is_deeply(
        [ $value, $attrs ],
        [ 'foo/bar', {} ],
        'handled bad attribute syntax correctly'
    );
}

{
    my $headers = <<'EOF';
Foo: 1
Bar: 2
Baz: 3
Bar: 4
EOF

    $headers =~ s/\n/$crlf/g;

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Foo => 1,
            Bar => 2,
            Baz => 3,
            Bar => 4,
        ],
        'parsed headers with repeated value'
    );

    my $string = <<'EOF';
Foo: 1
Baz: 3
EOF

    $string =~ s/\n/$crlf/g;

    is(
        $h->as_string( skip => ['Bar'] ),
        $string,
        'got expected header string (skipping Bar headers)'
    );
}

{
    my $headers = <<'EOF';
Foo: hello
  world
Bar: 2
Baz: 3
EOF

    $headers =~ s/\n/$crlf/g;

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Foo => 'hello world',
            Bar => 2,
            Baz => 3,
        ],
        'parsed headers with continuation line'
    );
}

{
    my $headers = <<'EOF';
Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
Bar: 2
Baz: 3
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Subject => $hola,
            Bar     => 2,
            Baz     => 3,
        ],
        'parsed headers with MIME encoded value'
    );

    my $string = <<'EOF';
Subject: =?UTF-8?B?wqFIb2xhLCA=?= =?UTF-8?B?c2XDsW9yIQ==?=
Bar: 2
Baz: 3
EOF

    $string =~ s/\n/$crlf/g;

    is(
        $h->as_string,
        $string,
        'got expected header string (encoded utf8 values)'
    );

    my $h2 = Courriel::Headers->parse( text => $h->as_string );
    is(
        $h2->get_values('Subject'),
        $h->get_values('Subject'),
        'round trip encoding of header with utf8 value'
    );
}

{
    my $headers = <<'EOF';
Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?= =?utf-8?Q?=c2=a1Hola=2c_se=c3=b1or!?=
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [
            Subject => $hola . $hola,
        ],
        'parsed headers with two MIME encoded words correctly (ignore space in between them)'
    );
}

{
    my $headers = <<'EOF';
Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?= not encoded
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [ Subject => $hola . ' not encoded' ],
        'parsed headers with MIME encoded word followed by unencoded text'
    );
}

{
    my $headers = <<'EOF';
Subject: =?iso-8859-1?Q?=A1Hola,_se=F1or!?=   not encoded
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [ Subject => $hola . '   not encoded' ],
        'parsed headers with MIME encoded word followed by three spaces then unencoded text'
    );
}

{
    my $headers = <<'EOF';
Subject: not encoded =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [ Subject => 'not encoded ' . $hola ],
        'parsed headers with unencoded text followed by MIME encoded word'
    );
}

{
    my $headers = <<'EOF';
Subject: not encoded   =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    is_deeply(
        _headers_as_arrayref($h),
        [ Subject => 'not encoded   ' . $hola ],
        'parsed headers with unencoded text followed by three spaces then MIME encoded word'
    );
}

{
    my $chinese = "\x{4E00}" x 100;

    my $h = Courriel::Headers->new( headers => [ Subject => $chinese ] );

    my $string = <<'EOF';
Subject:
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
  =?UTF-8?B?5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA5LiA?=
EOF

    $string =~ s/\n/$crlf/g;

    is(
        $h->as_string,
        $string,
        'Chinese subject is encoded properly'
    );

    is_deeply(
        _headers_as_arrayref(
            Courriel::Headers->parse( text => $h->as_string )
        ),
        [ Subject => $chinese ],
        'Chinese subject header round trips properly'
    );
}

{
    my $headers = <<'EOF';
Subject: has   three spaces
EOF

    my $h = Courriel::Headers->parse( text => \$headers );

    like(
        $h->as_string,
        qr/\QSubject: has   three spaces/,
        'original spacing in header value is preserved when stringified'
    );
}

{
    my $header = Courriel::Header->new(
        name  => 'To',
        value => q{Ďāᶌȩ ȒȯƖŝķẏ <autarch@urth.org>},
    );

    like(
        $header->as_string,
        qr/
              \Q?UTF-8?B?\E
              \S+
              \s+
              \Q<autarch\E\@\Qurth.org>\E
          /x,
        'email address is not encoded but unicode content before it is when address has no UTF-8'
    );
}

{
    my $header = Courriel::Header->new(
        name  => 'To',
        value => q{Ďāᶌȩ ȒȯƖŝķẏ <āutarch@urth.org>},
    );

    like(
        $header->as_string,
        qr/
              \Q?UTF-8?B?\E
              \S+
              \s+
              \Q<āutarch\E\@\Qurth.org>\E
          /x,
        'email address is not encoded but unicode content before it is even when address has UTF-8'
    );
}

{
    my $header = Courriel::Header->new(
        name => 'To',
        value =>
            q{Ďāᶌȩ ȒȯƖŝķẏ <āutarch@urth.org>, "Joe Smith" <joe@example.com>},
    );

    like(
        $header->as_string,
        qr/
              \Q?UTF-8?B?\E
              \S+
              \s+
              \Q<āutarch\E\@\Qurth.org>\E
              \Q, "Joe Smith" <joe\E\@\Qexample.com>\E
          /x,
        'multiple addresses in To header are handled correctly when encoding'
    );
}

{
    my $value  = q{from Ďāᶌȩ ȒȯƖŝķẏ};
    my $header = Courriel::Header->new(
        name  => 'Received',
        value => $value,
    );

    like(
        $header->as_string,
        qr/\Q$value/,
        'Received header is not encoded'
    );
}

{
    my $header = Courriel::Header->new(
        name => 'Subject',
        value =>
            '0000000000000000000000000000000000000000000000000000000000000000000 0',
    );

    my $expect = <<'EOF';
Subject: 0000000000000000000000000000000000000000000000000000000000000000000
  0
EOF

    $expect =~ s/\n/\r\n/g;
    is(
        $header->as_string,
        $expect,
        'header value that is all zeroes is folded correctly'
    );
}

{
    my $real = <<'EOF';
Return-Path: <rtcpan@cpan.rt.develooper.com>
X-Spam-Checker-Version: SpamAssassin 3.3.1 (2010-03-16) on urth.org
X-Spam-Level: 
X-Spam-Status: No, score=-6.9 required=5.0 tests=BAYES_00,RCVD_IN_DNSWL_HI,
    T_RP_MATCHES_RCVD autolearn=ham version=3.3.1
X-Original-To: autarch@urth.org
Delivered-To: autarch@urth.org
Received: from localhost (localhost.localdomain [127.0.0.1])
    by urth.org (Postfix) with ESMTP id BDC8B171751
    for <autarch@urth.org>; Sat, 28 May 2011 12:54:18 -0500 (CDT)
X-Virus-Scanned: Debian amavisd-new at urth.org
Received: from urth.org ([127.0.0.1])
    by localhost (urth.org [127.0.0.1]) (amavisd-new, port 10024)
    with ESMTP id YITg-uxEcP1N for <autarch@urth.org>;
    Sat, 28 May 2011 12:54:10 -0500 (CDT)
Received: from x1.develooper.com (x1.develooper.com [207.171.7.70])
    by urth.org (Postfix) with SMTP id D312D1707FC
    for <autarch@urth.org>; Sat, 28 May 2011 12:54:09 -0500 (CDT)
Received: (qmail 26426 invoked by uid 225); 28 May 2011 17:54:08 -0000
Delivered-To: DROLSKY@cpan.org
Received: (qmail 26422 invoked by uid 103); 28 May 2011 17:54:08 -0000
Received: from x16.dev (10.0.100.26)
    by x1.dev with QMQP; 28 May 2011 17:54:08 -0000
Received: from cpan.rt.develooper.com (HELO cpan.rt.develooper.com) (207.171.7.181)
    by 16.mx.develooper.com (qpsmtpd/0.80/v0.80-19-gf52d165) with ESMTP; Sat, 28 May 2011 10:54:05 -0700
Received: by cpan.rt.develooper.com (Postfix, from userid 536)
    id 7E07B704A; Sat, 28 May 2011 10:54:03 -0700 (PDT)
Precedence: normal
Subject: [rt.cpan.org #68527] [PATCH] add a 'end_of_life' optional deprecation parameter 
From: "Yanick Champoux via RT" <bug-Package-DeprecationManager@rt.cpan.org>
Reply-To: bug-Package-DeprecationManager@rt.cpan.org
In-Reply-To: <1306605315-23916-1-git-send-email-yanick@cpan.org>
References: <RT-Ticket-68527@rt.cpan.org> <1306605315-23916-1-git-send-email-yanick@cpan.org>
Message-ID: <rt-3.8.HEAD-18810-1306605243-528.68527-4-0@rt.cpan.org>
X-RT-Loop-Prevention: rt.cpan.org
RT-Ticket: rt.cpan.org #68527
Managed-by: RT 3.8.HEAD (http://www.bestpractical.com/rt/)
RT-Originator: yanick@cpan.org
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
X-RT-Original-Encoding: utf-8
Date: Sat, 28 May 2011 13:54:03 -0400
To: undisclosed-recipients:;
EOF

    $real =~ s/\n/$crlf/g;

    my $h = Courriel::Headers->parse( text => \$real );

    is_deeply(
        [ map { $_->value } $h->get('Precedence') ],
        ['normal'],
        'Precendence header was parsed properly'
    );

    is_deeply(
        [ map { $_->value } $h->get('Message-ID') ],
        ['<rt-3.8.HEAD-18810-1306605243-528.68527-4-0@rt.cpan.org>'],
        'Message-ID header was parsed properly'
    );

    is_deeply(
        [ map { $_->value } $h->get('X-Spam-Level') ],
        [q{}],
        'X-Spam-Level (empty header) was parsed properly',
    );

    is_deeply(
        [ map { $_->value } $h->get('X-Spam-Status') ],
        [
            'No, score=-6.9 required=5.0 tests=BAYES_00,RCVD_IN_DNSWL_HI, T_RP_MATCHES_RCVD autolearn=ham version=3.3.1'
        ],
        'X-Spam-Status header was parsed properly'
    );

    my $expect = <<'EOF';
Return-Path: <rtcpan@cpan.rt.develooper.com>
X-Spam-Checker-Version: SpamAssassin 3.3.1 (2010-03-16) on urth.org
X-Spam-Level: 
X-Spam-Status: No, score=-6.9 required=5.0 tests=BAYES_00,RCVD_IN_DNSWL_HI,
  T_RP_MATCHES_RCVD autolearn=ham version=3.3.1
X-Original-To: autarch@urth.org
Delivered-To: autarch@urth.org
Received: from localhost (localhost.localdomain [127.0.0.1]) by urth.org
  (Postfix) with ESMTP id BDC8B171751 for <autarch@urth.org>; Sat, 28 May 2011
  12:54:18 -0500 (CDT)
X-Virus-Scanned: Debian amavisd-new at urth.org
Received: from urth.org ([127.0.0.1]) by localhost (urth.org [127.0.0.1])
  (amavisd-new, port 10024) with ESMTP id YITg-uxEcP1N for <autarch@urth.org>;
  Sat, 28 May 2011 12:54:10 -0500 (CDT)
Received: from x1.develooper.com (x1.develooper.com [207.171.7.70]) by
  urth.org (Postfix) with SMTP id D312D1707FC for <autarch@urth.org>; Sat, 28
  May 2011 12:54:09 -0500 (CDT)
Received: (qmail 26426 invoked by uid 225); 28 May 2011 17:54:08 -0000
Delivered-To: DROLSKY@cpan.org
Received: (qmail 26422 invoked by uid 103); 28 May 2011 17:54:08 -0000
Received: from x16.dev (10.0.100.26) by x1.dev with QMQP; 28 May 2011
  17:54:08 -0000
Received: from cpan.rt.develooper.com (HELO cpan.rt.develooper.com)
  (207.171.7.181) by 16.mx.develooper.com (qpsmtpd/0.80/v0.80-19-gf52d165)
  with ESMTP; Sat, 28 May 2011 10:54:05 -0700
Received: by cpan.rt.develooper.com (Postfix, from userid 536) id 7E07B704A;
  Sat, 28 May 2011 10:54:03 -0700 (PDT)
Precedence: normal
Subject: [rt.cpan.org #68527] [PATCH] add a 'end_of_life' optional
  deprecation parameter 
From: "Yanick Champoux via RT" <bug-Package-DeprecationManager@rt.cpan.org>
Reply-To: bug-Package-DeprecationManager@rt.cpan.org
In-Reply-To: <1306605315-23916-1-git-send-email-yanick@cpan.org>
References: <RT-Ticket-68527@rt.cpan.org>
  <1306605315-23916-1-git-send-email-yanick@cpan.org>
Message-ID: <rt-3.8.HEAD-18810-1306605243-528.68527-4-0@rt.cpan.org>
X-RT-Loop-Prevention: rt.cpan.org
RT-Ticket: rt.cpan.org #68527
Managed-by: RT 3.8.HEAD (http://www.bestpractical.com/rt/)
RT-Originator: yanick@cpan.org
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
X-RT-Original-Encoding: utf-8
Date: Sat, 28 May 2011 13:54:03 -0400
To: undisclosed-recipients:;
EOF

    $expect =~ s/\n/$crlf/g;

    eq_or_diff(
        $h->as_string,
        $expect,
        'output for real headers matches original headers, but with more correct folding'
    );
}

{
    my $bad = <<'EOF';
Ok: 1
: bad
EOF

    like(
        exception {
            Courriel::Headers->parse(
                text => \$bad,
            );
        },
        qr/Found an unparseable .+ at line 2/,
        'exception on bad headers'
    );
}

{
    my $bad = <<'EOF';
Ok: 1
Ok: 2
Not ok
Ok: 4
EOF

    like(
        Courriel::Headers->parse(
            text => \$bad,
        )->as_string,
        qr/Ok: 2Not ok/,
        'handle arbitrary newline without an exception'
    );
}

{
    # Second line has spaces
    my $bad = <<'EOF';
Ok: 1
  
Ok: 2
EOF

    like(
        Courriel::Headers->parse(
            text => \$bad,
        )->as_string,
        qr/Ok: 1/,
        'handle empty continuation line without an exception'
    );
}

done_testing();

sub _headers_as_arrayref {
    my $h = shift;

    return [ map { blessed($_) ? $_->value : $_ } $h->headers ];
}

sub _attributes_as_hashref {
    my $attrs = shift;

    return { map { $_ => $attrs->{$_}->value } keys %{$attrs} };
}
