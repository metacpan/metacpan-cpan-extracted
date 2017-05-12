# NAME

Courriel - High level email parsing and manipulation

# VERSION

version 0.44

# SYNOPSIS

    my $email = Courriel->parse( text => $raw_email );

    print $email->subject;

    print $_->address for $email->participants;

    print $email->datetime->year;

    if ( my $part = $email->plain_body_part ) {
        print $part->content;
    }

# DESCRIPTION

This class exists to provide a high level API for working with emails,
particular for processing incoming email. It is primarily a wrapper around the
other classes in the Courriel distro, especially [Courriel::Headers](https://metacpan.org/pod/Courriel::Headers),
[Courriel::Part::Single](https://metacpan.org/pod/Courriel::Part::Single), and [Courriel::Part::Multipart](https://metacpan.org/pod/Courriel::Part::Multipart). If you need lower
level information about an email, it should be available from one of these
classes.

# API

This class provides the following methods:

## Courriel->parse( text => $raw\_email, is\_character => 0|1 )

This parses the given text and returns a new Courriel object. The text can be
provided as a string or a reference to a string.

If you pass a reference, then the scalar underlying the reference _will_ be
modified, so don't pass in something you don't want modified.

By default, Courriel expects that content passed in text is binary data. This
means that it has not been decoded into utf-8 with `Encode::decode()` or by
using a `:encoding(UTF-8)` IO layer.

In practice, this doesn't matter for most emails, since they either contain
only ASCII data or they actually do contain binary (non-character)
data. However, if an email is using the 8bit Content-Transfer-Encoding, then
this does matter.

If the email has already been decoded, you must set `is_character` to a true
value.

It's safest to simply pass binary data to Courriel and let it handle decoding
internally.

## $email->parts()

Returns an array (not a reference) of the parts this email contains.

## $email->part\_count()

Returns the number of parts this email contains.

## $email->is\_multipart()

Returns true if the top-level part is a multipart part, false otherwise.

## $email->top\_level\_part()

Returns the actual top level part for the object. You're probably better off
just calling `$email->parts()` most of the time, since when the email is
multipart, the top level part is just a container.

## $email->subject()

Returns the email's Subject header value, or `undef` if it doesn't have one.

## $email->datetime()

Returns a [DateTime](https://metacpan.org/pod/DateTime) object for the email. The DateTime object is always in
the "UTC" time zone.

This uses the Date header by default one. Otherwise it looks at the date in
each Received header, and then it looks for a Resent-Date header. If none of
these exists, it just returns `DateTime->now()`.

## $email->from()

This returns a single [Email::Address](https://metacpan.org/pod/Email::Address) object based on the From header of the
email. If the email has no From header or if the From header is broken, it
returns `undef`.

## $email->participants()

This returns a list of [Email::Address](https://metacpan.org/pod/Email::Address) objects, one for each unique
participant in the email. This includes any address in the From, To, or CC
headers.

Just like with the From header, broken addresses will not be included.

## $email->recipients()

This returns a list of [Email::Address](https://metacpan.org/pod/Email::Address) objects, one for each unique
recipient in the email. This includes any address in the To or CC headers.

Just like with the From header, broken addresses will not be included.

## $email->to()

This returns a list of [Email::Address](https://metacpan.org/pod/Email::Address) objects, one for each unique
address in the To header.

Just like with the From header, broken addresses will not be included.

## $email->cc()

This returns a list of [Email::Address](https://metacpan.org/pod/Email::Address) objects, one for each unique
address in the CC header.

Just like with the From header, broken addresses will not be included.

## $email->plain\_body\_part()

This returns the first [Courriel::Part::Single](https://metacpan.org/pod/Courriel::Part::Single) object in the email with a
mime type of "text/plain" and an inline disposition, if one exists.

## $email->html\_body\_part()

This returns the first [Courriel::Part::Single](https://metacpan.org/pod/Courriel::Part::Single) object in the email with a
mime type of "text/html" and an inline disposition, if one exists.

## $email->clone\_without\_attachments()

Returns a new Courriel object that only contains inline parts from the
original email, effectively removing all attachments.

## $email->first\_part\_matching( sub { ... } )

Given a subroutine reference, this method calls that subroutine for each part
in the email, in a depth-first search.

The subroutine receives the part as its only argument. If it returns true,
this method returns that part.

## $email->all\_parts\_matching( sub { ... } )

Given a subroutine reference, this method calls that subroutine for each part
in the email, in a depth-first search.

The subroutine receives the part as its only argument. If it returns true,
this method includes that part.

This method returns all of the parts that match the subroutine.

## $email->content\_type()

Returns the [Courriel::Header::ContentType](https://metacpan.org/pod/Courriel::Header::ContentType) object associated with the email.

## $email->headers()

Returns the [Courriel::Headers](https://metacpan.org/pod/Courriel::Headers) object for this email.

## $email->stream\_to( output => $output )

This method will send the stringified email to the specified output. The
output can be a subroutine reference, a filehandle, or an object with a
`print()` method. The output may be sent as a single string, as a list of
strings, or via multiple calls to the output.

For large emails, streaming can be much more memory efficient than generating
a single string in memory.

## $email->as\_string()

Returns the email as a string, along with its headers. Lines will be
terminated with "\\r\\n".

# ROBUSTNESS PRINCIPLE

Courriel aims to respect the common Internet robustness principle (aka
Postel's law). Courriel is conservative in the output it generates, and
liberal in what it accepts.

When parsing, the goal is to never die and always return as much information
as possible. Any input that causes the `Courriel->parse()` to die means
there's a bug in the parser. Please report these bugs.

Conversely, Courriel aims to respect all relevant RFCs in its output, except
when it preserves the original data in a parsed email. If you're using
[Courriel::Builder](https://metacpan.org/pod/Courriel::Builder) to create emails from scratch, any output that isn't
RFC-compliant is a bug.

# FUTURE PLANS

This release is still rough, and I have some plans for additional features:

## More methods for walking all parts

Some more methods for walking/collecting multiple parts would be useful.

## More?

Stay tuned for details.

# WHY DID I WRITE THIS MODULE?

There a lot of email modules/distros on CPAN. Why didn't I use/fix one of them?

- [Mail::Box](https://metacpan.org/pod/Mail::Box)

    This one probably does everything this module does and more, but it's really,
    really big and complicated, forcing the end user to make a lot of choices just
    to get started. If you need it, it's great, but I generally find it to be too
    much module for me.

- [Email::Simple](https://metacpan.org/pod/Email::Simple) and [Email::MIME](https://metacpan.org/pod/Email::MIME)

    These are surprisingly **not** simple. They suffer from a problematic API (too
    high level in some spots, too low in others), and a poor separation of
    concerns. I've hacked on these enough to know that I can never make them do
    what I want.

- Everything Else

    There's a lot of other email modules on CPAN, but none of them really seem any
    better than the ones mentioned above.

# CREDITS

This module rips some chunks of code from a few other places, notably several
of the Email suite modules.

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html)

# BUGS

Please report any bugs or feature requests to `bug-courriel@rt.cpan.org`, or
through the web interface at [http://rt.cpan.org](http://rt.cpan.org).  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

Bugs may be submitted through [the RT bug tracker](http://rt.cpan.org/Public/Dist/Display.html?Name=Courriel)
(or [bug-courriel@rt.cpan.org](mailto:bug-courriel@rt.cpan.org)).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Gregory Oschwald <goschwald@maxmind.com>
- Ricardo Signes <rjbs@users.noreply.github.com>
- Zbigniew Łukasiak <zzbbyy@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
