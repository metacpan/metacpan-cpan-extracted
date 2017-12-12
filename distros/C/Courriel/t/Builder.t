use strict;
use warnings;

use Test::Differences;
use Test::Fatal;
use Test::More 0.88;

use Courriel::Builder;
use Courriel::Helpers;
use List::AllUtils qw( all );
use Sys::Hostname qw( hostname );

{
    my $email = build_email(
        subject('Test Subject'),
        from('autarch@urth.org'),
        to( 'autarch@urth.org', Email::Address->parse('bob@example.com') ),
        cc( 'jane@example.com', Email::Address->parse('joe@example.com') ),
        header( 'X-Foo' => 42 ),
        header( 'X-Bar' => 84 ),
        plain_body('The body of the message')
    );

    isa_ok( $email, 'Courriel' );

    my %expect = (
        Subject        => 'Test Subject',
        From           => 'autarch@urth.org',
        To             => 'autarch@urth.org, bob@example.com',
        Cc             => 'jane@example.com, joe@example.com',
        'X-Foo'        => '42',
        'X-Bar'        => 84,
        'Content-Type' => 'text/plain; charset=UTF-8',
        'MIME-Version' => '1.0',
    );

    for my $key ( sort keys %expect ) {
        is_deeply(
            [ map { $_->value } $email->headers->get($key) ],
            [ $expect{$key} ],
            "got expected value for $key header"
        );
    }

    my @date = $email->headers->get('Date');
    is( scalar @date, 1, 'found one Date header' );
    like(
        $date[0]->value,
        qr/\w\w\w, +\d{1,2} \w\w\w \d\d\d\d \d\d:\d\d:\d\d [-+]\d\d\d\d/,
        'Date header looks like a proper date'
    );

    my @id = $email->headers->get('Message-Id');
    is( scalar @id, 1, 'found one Message-Id header' );
    like(
        $id[0]->value,
        qr/<[^>]+>/,
        'Message-Id is in brackets'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body(
            content => 'Foo',
            charset => 'ISO-8859-1'
        ),
    );

    my @ct = $email->headers->get('Content-Type');
    is( scalar @ct, 1, 'found one Content-Type header' );
    is(
        $ct[0]->value,
        'text/plain; charset=ISO-8859-1',
        'Content-Type has the right charset'
    );
}

{
    my $email = build_email(
        subject(q{}),
        plain_body(
            content => 'Foo',
        ),
    );

    is_deeply(
        [ map { $_->value } $email->headers->get('Subject') ],
        [q{}],
        'got an empty string for the Subject header',
    );
}

{
    my $dt = DateTime->new(
        year      => 1980,
        month     => 1,
        day       => 13,
        time_zone => '-0500'
    );

    my $email = build_email(
        subject('Test Subject'),
        header( Date => DateTime::Format::Mail->format_datetime($dt) ),
        plain_body( content => 'Foo' ),
    );

    my @date = $email->headers->get('Date');
    is( scalar @date, 1, 'found one Date header' );
    is(
        $date[0]->value,
        'Sun, 13 Jan 1980 00:00:00 -0500',
        'explicit Date header is not overwritten'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body(
            content  => "Foo \x{00F1}",
            encoding => 'quoted-printable'
        ),
    );

    is(
        $email->plain_body_part->encoded_content,
        'Foo =C3=B1=' . $Courriel::Helpers::CRLF,
        'body is encoded using quoted-printable'
    );
}

{
    my $content = 'content ref';

    my $email = build_email(
        subject('Test Subject'),
        plain_body( \$content ),
    );

    is(
        $email->plain_body_part->content,
        $content,
        'can pass body content as a scalar ref'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body('foo'),
        html_body('<p>foo</p>'),
    );

    is(
        $email->content_type->mime_type,
        'multipart/alternative',
        'passing a plain and html body with no attachments makes a multipart/alternative email'
    );
}

{
    my $pl_script = <<'EOF';
#!/usr/bin/perl

print "Hello world\n";
EOF

    my $email = build_email(
        subject('Test Subject'),
        plain_body('foo'),
        attach( content => $pl_script ),
    );

    is(
        $email->content_type->mime_type,
        'multipart/mixed',
        'passing an attachment makes a multipart/mixed email'
    );

    my @parts = $email->parts;
    is( scalar @parts, 2, 'email has two parts' );

    ok(
        ( all { !$_->is_multipart } @parts ),
        'email consists of two single parts'
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    ok(
        $attachment,
        'one of the parts returns true for is_attachment'
    );

    is(
        $attachment->content,
        $pl_script,
        'attachment content matches the original code'
    );

    like(
        $email->as_string,
        qr{Content-Type:\s+multipart/mixed;\s+boundary=.+},
        'Content-Type header for multipart email includes boundary'
    );

    my $parsed = Courriel->parse( text => $email->as_string );
    my $parsed_attachment
        = $parsed->first_part_matching( sub { $_[0]->is_attachment } );

    is(
        $parsed_attachment->content,
        $pl_script,
        'attachment content survives round trip from string to object'
    );
}

{
    my $pl_script = <<'EOF';
#!/usr/bin/perl

print "Hello world\n";
EOF

    my $email = build_email(
        subject('Test Subject'),
        plain_body('foo'),
        html_body('<p>foo</p>'),
        attach( content => $pl_script ),
    );

    is(
        $email->content_type->mime_type,
        'multipart/mixed',
        'passing a plain and html body with attachments makes a multipart/alternative email'
    );

    ok(
        $email->plain_body_part,
        'email has a plain body'
    );

    ok(
        $email->html_body_part,
        'email has an html body'
    );

    ok(
        $email->first_part_matching(
            sub { $_[0]->mime_type eq 'multipart/alternative' }
        ),
        'email has a multipart/alternative part'
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    ok(
        $attachment,
        'email has an attachment'
    );
}

{
    open my $fh, '<', 't/data/office.jpg' or die $!;
    ## no critic (Variables::RequireInitializationForLocalVars)
    my $image = do { local $/; <$fh> };
    ## use critic
    close $fh or die $!;

    my $email = build_email(
        subject('Test Subject'),
        html_body(
            '<p>foo</p>',
            attach(
                content  => $image,
                filename => 'office.jpg',
            ),
        ),
    );

    is(
        $email->content_type->mime_type,
        'multipart/related',
        'passing an html body with attached image makes a multipart/related email'
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    ok(
        $attachment,
        'email has an attachment'
    );

    is(
        $attachment->mime_type,
        'image/jpeg',
        'got the right mime type for image attachment'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body('Foo'),
        attach('t/data/office.jpg'),
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    ok(
        $attachment,
        'email has an attachment'
    );

    is(
        $attachment->mime_type,
        'image/jpeg',
        'got the right mime type for image attachment from file'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body('Foo'),
        attach(
            file       => 't/data/office.jpg',
            content_id => 'abc123',
        ),
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    is_deeply(
        [ map { $_->value } $attachment->headers->get('Content-ID') ],
        ['<abc123>'],
        'attachment has the correct Content-ID, and it is wrapped in brackets'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body('Foo'),
        attach(
            file      => 't/data/office.jpg',
            mime_type => 'w/tf',
        ),
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    is_deeply(
        $attachment->mime_type,
        'w/tf',
        'attachment has explicitly set mime type'
    );
}

{
    my $email = build_email(
        subject('Test Subject'),
        plain_body('Foo'),
        attach(
            file     => 't/data/office.jpg',
            filename => 'something-else.jpg',
        ),
    );

    my $attachment
        = $email->first_part_matching( sub { $_[0]->is_attachment } );
    is_deeply(
        $attachment->filename,
        'something-else.jpg',
        'attachment has explicitly set filename'
    );
}

{
    like(
        exception { build_email( ['wtf'] ); },
        qr/\QValidation failed for 'HashRef' with value [ "wtf" ]/,
        'got error when passing invalid value to build_email'
    );
}

{
    like(
        exception { build_email( { bad_key => 42 } ); },
        qr/A weird value was passed to build_email:/,
        'got error when passing invalid value to build_email'
    );
}

{
    like(
        exception { build_email( subject('foo') ); },
        qr/Cannot call build_email without a plain or html body/,
        'got error when passing invalid value to build_email'
    );
}

{
    like(
        exception { build_email(); },
        qr/Got 0 parameters but expected at least 1/,
        'got error when passing no arguments to build_email'
    );
}

done_testing();
