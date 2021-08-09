package Courriel::Builder;

use strict;
use warnings;

our $VERSION = '0.49';

use Carp qw( croak );
use Courriel;
use Courriel::Header::ContentType;
use Courriel::Header::Disposition;
use Courriel::Headers;
use Courriel::Helpers qw( parse_header_with_attributes );
use Courriel::Part::Multipart;
use Courriel::Part::Single;
use Courriel::Types qw( EmailAddressStr HashRef NonEmptyStr Str StringRef );
use DateTime;
use DateTime::Format::Mail;
use Devel::PartialDump;
use File::Basename qw( basename );
use File::LibMagic;
use File::Slurper qw( read_binary );
use List::AllUtils qw( first );
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( blessed reftype );

our @CARP_NOT = __PACKAGE__;

my @exports;

BEGIN {
    @exports = qw(
        build_email
        subject
        from
        to
        cc
        header
        plain_body
        html_body
        attach
    );
}

use Sub::Exporter -setup => {
    exports => \@exports,
    groups  => { default => \@exports },
};

{
    my $validator = validation_for(
        params => [ { type => HashRef } ],
        slurpy => HashRef,
    );

    sub build_email {
        my @p = $validator->(@_);

        my @headers;
        my $plain_body;
        my $html_body;
        my @attachments;

        for my $p (@p) {
            ## no critic (ControlStructures::ProhibitCascadingIfElse)
            if ( $p->{header} ) {
                push @headers, @{ $p->{header} };
            }
            elsif ( $p->{plain_body} ) {
                $plain_body = $p->{plain_body};
            }
            elsif ( $p->{html_body} ) {
                $html_body = $p->{html_body};
            }
            elsif ( $p->{attachment} ) {
                push @attachments, $p->{attachment};
            }
            else {
                _bad_value($p);
            }
        }

        my $body_part;
        if ( $plain_body && $html_body ) {
            my $ct = Courriel::Header::ContentType->new(
                mime_type => 'multipart/alternative',
            );

            $body_part = Courriel::Part::Multipart->new(
                headers      => Courriel::Headers->new,
                content_type => $ct,
                parts        => [ $plain_body, $html_body ],
            );
        }
        else {
            $body_part = first {defined} $plain_body, $html_body;

            croak 'Cannot call build_email without a plain or html body'
                unless $body_part;
        }

        if (@attachments) {
            my $ct = Courriel::Header::ContentType->new(
                mime_type => 'multipart/mixed' );

            $body_part = Courriel::Part::Multipart->new(
                headers      => Courriel::Headers->new,
                content_type => $ct,
                parts        => [
                    $body_part,
                    @attachments,
                ],
            );
        }

        _add_required_headers( \@headers );

        # XXX - a little incestuous but I don't really want to make this method
        # public, and delaying building the body part would make all the code more
        # complicated than it needs to be.
        $body_part->_set_headers(
            Courriel::Headers->new( headers => [@headers] ) );

        return Courriel->new( part => $body_part );
    }
}

sub _bad_value {
    croak 'A weird value was passed to build_email: '
        . Devel::PartialDump->new->dump( $_[0] );
}

sub _add_required_headers {
    my $headers = shift;

    my %keys = map {lc} @{$headers};

    unless ( $keys{date} ) {
        push @{$headers},
            ( Date => DateTime::Format::Mail->format_datetime( DateTime->now )
            );
    }

    unless ( $keys{'message-id'} ) {
        push @{$headers},
            ( 'Message-Id' => Email::MessageID->new->in_brackets );
    }

    unless ( $keys{'mime-version'} ) {
        push @{$headers}, ( 'MIME-Version' => '1.0' );
    }

    return;
}

{
    my $validator = validation_for(
        params => [ { type => Str } ],
    );

    sub subject {
        my ($subject) = $validator->(@_);

        return { header => [ Subject => $subject ] };
    }
}

{
    my $validator = validation_for(
        params => [ { type => EmailAddressStr } ],
    );

    sub from {
        my ($from) = $validator->(@_);

        if ( blessed $from ) {
            $from = $from->format;
        }

        return { header => [ From => $from ] };
    }
}

{
    my $validator = validation_for(
        params => [ { type => EmailAddressStr } ],
        slurpy => EmailAddressStr,
    );

    sub to {
        my (@to) = $validator->(@_);

        @to = map { blessed($_) ? $_->format : $_ } @to;

        return { header => [ To => join ', ', @to ] };
    }
}

{
    my $validator = validation_for(
        params => [ { type => EmailAddressStr } ],
        slurpy => EmailAddressStr,
    );

    sub cc {
        my (@cc) = $validator->(@_);

        @cc = map { blessed($_) ? $_->format : $_ } @cc;

        return { header => [ Cc => join ', ', @cc ] };
    }
}

{
    my $validator = validation_for(
        params => [
            { type => NonEmptyStr },
            { type => Str },
        ],
    );

    sub header {
        my ( $name, $value ) = $validator->(@_);

        return { header => [ $name => $value ] };
    }
}

sub plain_body {
    my %p
        = @_ == 1
        ? ( content => shift )
        : @_;

    return {
        plain_body => _body_part(
            %p,
            mime_type => 'text/plain',
        )
    };
}

sub html_body {
    my @attachments;

    for my $i ( reverse 0 .. $#_ ) {
        if (   ref $_[$i]
            && reftype( $_[$i] ) eq 'HASH'
            && $_[$i]->{attachment} ) {

            push @attachments, splice @_, $i, 1;
        }
    }

    my %p
        = @_ == 1
        ? ( content => shift )
        : @_;

    my $body = _body_part(
        %p,
        mime_type => 'text/html',
    );

    if (@attachments) {
        $body = Courriel::Part::Multipart->new(
            headers      => Courriel::Headers->new,
            content_type => Courriel::Header::ContentType->new(
                mime_type => 'multipart/related'
            ),
            parts => [
                $body,
                map { $_->{attachment} } @attachments,
            ],
        );
    }

    return { html_body => $body };
}

{
    my $validator = validation_for(
        params => [
            mime_type => { type => NonEmptyStr },
            charset   => {
                type    => NonEmptyStr,
                default => 'UTF-8',
            },
            encoding => {
                type    => NonEmptyStr,
                default => 'base64',
            },
            content => {
                type => StringRef,
            },
        ],
        named_to_list => 1,
    );

    sub _body_part {
        my ( $mime_type, $charset, $encoding, $content ) = $validator->(@_);

        my $ct = Courriel::Header::ContentType->new(
            mime_type  => $mime_type,
            attributes => { charset => $charset },
        );

        my $body = Courriel::Part::Single->new(
            headers      => Courriel::Headers->new,
            content_type => $ct,
            encoding     => $encoding,
            content      => $content,
        );

        return $body;
    }
}

sub attach {
    my %p
        = @_ == 1
        ? ( file => shift )
        : @_;

    return {
        attachment => $p{file} ? _part_for_file(%p) : _part_for_content(%p) };
}

my $flm = File::LibMagic->new;

{
    my $validator = validation_for(
        params => [
            file       => { type => NonEmptyStr },
            mime_type  => { type => NonEmptyStr, optional => 1 },
            filename   => { type => NonEmptyStr, optional => 1 },
            content_id => { type => NonEmptyStr, optional => 1 },
        ],
        named_to_list => 1,
    );

    sub _part_for_file {
        my ( $file, $mime_type, $filename, $content_id ) = $validator->(@_);

        my $ct
            = _content_type( $mime_type // $flm->checktype_filename($file) );

        my $content = read_binary($file);

        return Courriel::Part::Single->new(
            headers      => _attachment_headers($content_id),
            content_type => $ct,
            disposition  => _attachment_disposition( $filename // $file ),
            encoding     => 'base64',
            content      => \$content,
        );
    }
}

{
    my $validator = validation_for(
        params => [
            content    => { type => StringRef },
            mime_type  => { type => NonEmptyStr, optional => 1 },
            filename   => { type => NonEmptyStr, optional => 1 },
            content_id => { type => NonEmptyStr, optional => 1 },
        ],
        named_to_list => 1,
    );

    sub _part_for_content {
        my ( $content, $mime_type, $filename, $content_id )
            = $validator->(@_);

        my $ct = _content_type( $mime_type
                // $flm->checktype_contents( ${$content} ) );

        my $disp = Courriel::Header::Disposition->new(
            disposition => 'attachment',
            attributes  => {
                defined $filename ? ( filename => basename($filename) ) : ()
            }
        );

        return Courriel::Part::Single->new(
            headers      => _attachment_headers($content_id),
            content_type => $ct,
            disposition  => _attachment_disposition($filename),
            encoding     => 'base64',
            content      => $content,
        );
    }
}

sub _content_type {
    my $type = shift;

    return Courriel::Header::ContentType->new(
        mime_type => 'application/unknown' )
        unless defined $type;

    my ( $mime_type, $attr ) = parse_header_with_attributes($type);

    return Courriel::Header::ContentType->new(
        mime_type => 'application/unknown' )
        unless defined $mime_type && length $mime_type;

    return Courriel::Header::ContentType->new(
        mime_type  => $mime_type,
        attributes => $attr,
    );
}

sub _attachment_headers {
    my $content_id = shift;

    my @headers;

    if ( defined $content_id ) {
        $content_id = "<$content_id>"
            unless $content_id =~ /^<[^>]+>$/;

        push @headers, ( 'Content-ID' => $content_id );
    }

    return Courriel::Headers->new( headers => \@headers );
}

sub _attachment_disposition {
    my $file = shift;

    return Courriel::Header::Disposition->new(
        disposition => 'attachment',
        attributes => { defined $file ? ( filename => basename($file) ) : () }
    );
}

1;

# ABSTRACT: Build emails with sugar

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::Builder - Build emails with sugar

=head1 VERSION

version 0.49

=head1 SYNOPSIS

    use Courriel::Builder;

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        header( 'X-Generator' => 'MyApp' ),
        plain_body($plain_text),
        html_body(
            $html,
            attach('path/to/image.jpg'),
            attach('path/to/other-image.jpg'),
        ),
        attach('path/to/spreadsheet.xls'),
        attach( content => $file_content ),
    );

=head1 DESCRIPTION

This module provides some sugar syntax for emails of all shapes sizes, from
simple emails with a plain text body to emails with both plain and html bodies,
html with attached images, etc.

=head1 API

This module exports all of the following functions by default. It uses
L<Sub::Exporter> under the hood, which means you can easily import the
functions with different names. See L<Sub::Exporter> for details.

=head2 build_email( ... )

This function returns a new L<Courriel> object. It takes the results of all the
other functions you call as input.

It expects you to pass in a body of some sort, whether text, html, or both, and
will throw an error if you don't.

It will add Date and Message-ID headers to your email if you don't provide
them, ensuring that the email is RFC-compliant.

=head2 subject($subject)

This sets the subject of the email. It expects a single string. You can pass an
empty string, but not C<undef>.

=head2 from($from)

This sets the From header of the email. It expects a single string or an object
with a C<format()> method like C<Email::Address::XS>.

=head2 to($from)

This sets the To header of the email. It expects a list of strings and/or
objects with a C<format()> method like C<Email::Address::XS>.

=head2 cc($from)

This sets the Cc header of the email. It expects a list of strings and/or
objects with a C<format()> method like C<Email::Address::XS>.

=head2 header( $name => $value )

This sets a header's value. You can call it as many times as you want, and you
can call it more than once with the same header name to set multiple values for
that header.

=head2 plain_body( ... )

This defines a plain text body for the email. You can call it with a single
argument, a scalar or reference to a scalar. This creates a text/plain part
based on the content you provide in that argument. By default, the charset for
the body is UTF-8 and the encoding is base64.

You can also call this function with a hash of options. It accepts the
following options:

=over 4

=item * content

The content of the body. This can be a string or scalar reference.

=item * charset

The charset for the body. This defaults to UTF-8.

=item * encoding

The encoding for the body. This defaults to base64. Other valid values are
quoted-printable, 7bit, and 8bit.

It is strongly recommended that you let Courriel handle the transfer encoding
for you.

=back

=head2 html_body( ... )

This accepts the same arguments as the C<plain_body()> function.

You can I<also> pass in the results of one or more calls to the C<attach()>
function. If you pass in attachments, it creates a multipart/related email
part, which lets you refer to images by the Content-ID using the "cid:" URL
scheme.

=head2 attach( ... )

This function creates an attachment for the email. In the simplest form, you
can pass it a single argument, which should be a path to a file on disk. This
file will be attached to the email.

You can also pass a hash of options. The valid keys are:

=over 4

=item * file

The file to attach to the email. You can also pass the content explicitly.

=item * content

The content of the attachment. This can be a string or scalar reference.

=item * filename

You can set the filename that will be used in the attachment's
Content-Disposition header. If you pass a C<file> parameter, that will be used
when this isn't provided. If you pass as C<content> parameter, then there will
be no filename set for the attachment unless you pass a C<filename> parameter
as well.

=item * mime_type

You can explicitly set the mime type for the attachment. If you don't, this
function will use L<File::LibMagic> to try to figure out the mime type for the
attachment.

=item * content_id

This will set the Content-ID header for the attachment. If you're creating a
HTML body with "cid:" scheme URLs, you'll need to set this for each attachment
that the HTML body refers to.

The id will be wrapped in angle brackets ("<id-goes-here>") when set as a
header.

=back

=head1 COOKBOOK

Some examples of how to build different types of emails.

=head2 Simple Email With Plain Text Body

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        plain_body($plain_text),
    );

This creates an email with a single text/plain part.

=head2 Simple Email With HTML Body

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        html_body($html_text),
    );

This creates an email with a single text/html part.

=head2 Email With Both Plain and HTML Bodies

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        plain_body($plain_text),
        html_body($html_text),
    );

This creates an email with this structure:

    multipart/alternative
      |
      |-- text/plain (disposition = inline)
      |-- text/html  (disposition = inline)

=head2 Email With Both Plain and HTML Bodies and Inline Images

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        plain_body($plain_text),
        html_body(
            $html_text,
            attach(
                file       => 'path/to/image1.jpg',
                content_id => 'image1',
            ),
            attach(
                file       => 'path/to/image2.jpg',
                content_id => 'image2',
            ),
        ),
    );

This creates an email with this structure:

    multipart/alternative
      |
      |-- text/plain (disposition = inline)
      |-- multipart/related
            |
            |-- text/html  (disposition = inline)
            |-- image/jpeg (disposition = attachment, Content-ID = image1)
            |-- image/jpeg (disposition = attachment, Content-ID = image2)

=head2 Email With Both Plain and HTML Bodies and Attachments

    my $email = build_email(
        subject('An email for you'),
        from('joe@example.com'),
        to( 'jane@example.com', 'alice@example.com' ),
        plain_body($plain_text),
        html_body(
            $html_text,
        ),
        attach('path/to/spreadsheet.xls'),
        attach( content => \$png_image_content ),
    );

This creates an email with this structure:

    multipart/mixed
      |
      |-- multipart/alternative
      |     |
      |     |-- text/plain (disposition = inline)
      |     |-- text/html  (disposition = inline)
      |
      |-- application/vnd.ms-excel (disposition = attachment)
      |-- image/png                (disposition = attachment)

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Courriel/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Courriel can be found at L<https://github.com/houseabsolute/Courriel>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
