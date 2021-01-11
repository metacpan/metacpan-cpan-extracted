# NAME

CGI::URI2param - DEPRECATED - convert parts of an URL to param values

# VERSION

version 1.03

# SYNOPSIS

DEPRECATED! Please do not use this module any more!

    use CGI::URI2param qw(uri2param);

    uri2param($req,\%regexes);

# DESCRIPTION

DEPRECATED! Please do not use this module any more!

Here are the old docs:

CGI::URI2param takes a request object (as supplied by CGI.pm or
Apache::Request) and a hashref of keywords mapped to
regular expressions. It applies all of the regexes to the current URI
and adds everything that matched to the 'param' list of the request
object.

Why?

With CGI::URI2param you can instead of:

`http://somehost.org/db?id=1234&style=fancy`

present a nicerlooking URL like this:

`http://somehost.org/db/style_fancy/id1234.html`

To achieve this, simply do:

    CGI::URI2param::uri2param($r,{
                                   style => 'style_(\w+)',
                                   id    => 'id(\d+)\.html'
                                  });

Now you can access the values like this:

    my $id=$r->param('id');
    my $style=$r->param('style');

If you are using mod\_perl, please take a look at [Apache::URI2param](https://metacpan.org/pod/Apache%3A%3AURI2param).
It provides an Apache PerlInitHandler to make running CGI::URI2param
easier for you. Apache::URI2param is distributed along with
CGI::URI2param.

## uri2param($req,\\%regexs)

`$req` has to be some sort of request object that supports the method
`param`, e.g. the object returned by CGI->new() or by
Apache::Request->new().

`\%regexs` is hash containing the names of the parameters as the
keys, and corresponding regular expressions, that will be applied to
the URL, as the values.

    %regexs=(
             id    => 'id(\d+)\.html',
             style => 'st_(fancy|plain)',
             order => 'by_(\w+)',
            );

You should add some capturing parentheses to the regular
expression. If you don't do, all the buzz would be rather useless.

uri2param won't get exported into your namespace by default, so you
have to either import it explicitly

    use CGI::URI2param qw(uri2param);

or call it with it's full name, like so

    CGI::URI2param::uri2param($r,$regex);

## What's the difference to mod\_rewrite ?

Basically noting, but you can use CGI::URI2param if you cannot use
mod\_rewrite (e.g. your not running Apache or are on some ISP that
doesn't allow it). If you **can** use mod\_rewrite you maybe should
consider using it instead, because it is much more powerfull and
possibly faster. See mod\_rewrite in the Apache Docs
(http://www.apache.org)

# BUGS

None so far.

# TODO

Implement options (e.g. do specify what part of the URL should be
matched)

# REQUIRES

A module that supplies some sort of request object is needed, e.g.:
Apache::Request, CGI

# SEE ALSO

[Apache::URI2param](https://metacpan.org/pod/Apache%3A%3AURI2param)

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2001 - 2006 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
