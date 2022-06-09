# NAME

CGI::Carp::WarningsToBrowser - A version of [CGI::Carp](https://metacpan.org/pod/CGI%3A%3ACarp)'s warningsToBrowser()
that displays the warnings loudly and boldly

# RATIONALE

The author feels that it's important to expose warnings as early as possible in
the software development lifecycle, preferably by the same developer who created
them, as part of the "[shift left](https://devopedia.org/shift-left)" effort.
"Shift left" basically means that the earlier in the SDLC that a problem can be
found, the cheaper it is to fix it.

# SYNOPSIS

Put this at the top of your CGI script (the earlier the better, otherwise some
warnings might not get captured):

    use CGI::Carp::WarningsToBrowser;

Warnings will now be displayed at the very top of the web page, rather than
hidden in HTML comments like [CGI::Carp](https://metacpan.org/pod/CGI%3A%3ACarp)'s version.  This is intended mainly
for dev and test environments, not for prod, so it's a good idea to use [if](https://metacpan.org/pod/if):

    use if $is_dev, 'CGI::Carp::WarningsToBrowser';

# HANDLING ERRORS

This module does not handle fatal errors, because [CGI::Carp](https://metacpan.org/pod/CGI%3A%3ACarp) does an adequate
job at that task.

# COMPATIBILITY

Javascript must be enabled on the browser side, otherwise the warnings will
appear at the very bottom of the document. (the warnings are actually output in
an `END { }` block, and three lines of Javascript are used to move them to the
top of the HTML page)

# AUTHOR

Dee Newcum <deenewcum@cpan.org>

# CONTRIBUTING

Please use [Github's issue tracker](https://github.com/DeeNewcum/CGI-Carp-WarningsToBrowser/issues)
to file both bugs and feature requests. Contributions to the project in form of
Github's pull requests are welcome.

# LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
