# NAME

Catalyst::View::Wkhtmltopdf - Catalyst view to convert HTML (or TT) content to PDF using wkhtmltopdf

# SYNOPSIS

```perl
# lib/MyApp/View/Wkhtmltopdf.pm
package MyApp::View::Wkhtmltopdf;
use Moose;
extends qw/Catalyst::View::Wkhtmltopdf/;
__PACKAGE__->meta->make_immutable();
1;

# configure in lib/MyApp.pm
MyApp->config({
  ...
  'View::Wkhtmltopdf' => {
      command   => '/usr/local/bin/wkhtmltopdf',
      # Guessed via File::Spec by default
      tmpdir    => '/usr/tmp',
      # Name of the Template view, "TT" by default
      tt_view   => 'Template',
  },
});

sub ciao : Local {
    my($self, $c) = @_;

    # Pass some HTML...
    $c->stash->{wk} = {
        html    => $web_page,
    };

    # ..or a TT template
    $c->stash->{wk} = {
        template    => 'hello.tt',
        page_size   => 'a5',
    };

    # More parameters...
    $c->stash->{wk} = {
        html        => $web_page,
        disposition => 'attachment',
        filename    => 'mydocument.pdf',
    };

    $c->forward('View::Wkhtmltopdf');
}
```

# STATUS

The wkhtmltopdf project is no longer being maintained, and this module will be deprecated in a later release.

See ["SECURITY CONSIDERATIONS"](#security-considerations).

# DESCRIPTION

`Catalyst::View::Wkhtmltopdf` is a [Catalyst](https://metacpan.org/pod/Catalyst) view handler that
converts HTML data to PDF using `wkhtmltopdf`.
It can also handle direct conversion of [Template-Toolkit](https://metacpan.org/pod/Template) templates via [Catalyst::View::TT](https://metacpan.org/pod/Catalyst%3A%3AView%3A%3ATT).

# RECENT CHANGES

Changes for version v0.6.1 (2026-07-25)

- Security
    - Improved validation and sanitization of arguments, as the fix for CVE-2026-16766 was incomplete.
- Documentation
    - Recorganised sections, and include the STATUS section in the README.
    - Updated SECURITY CONSIDERATIONS.
    - Updated the documentation for Pod::Weaver.
    - Fixed typos.
- Tests
    - Tests are skipped when wkhtmltopdf is not in the path.

See the `Changes` file for more details.

# REQUIREMENTS

[wkhtmltopdf](https://wkhtmltopdf.org) must be installed.

This module lists the following modules as runtime dependencies:

- [B](https://metacpan.org/pod/B)
- [Catalyst::View](https://metacpan.org/pod/Catalyst%3A%3AView)
- [Catalyst::View::TT](https://metacpan.org/pod/Catalyst%3A%3AView%3A%3ATT)
- [File::Spec](https://metacpan.org/pod/File%3A%3ASpec)
- [File::Temp](https://metacpan.org/pod/File%3A%3ATemp)
- [File::Which](https://metacpan.org/pod/File%3A%3AWhich)
- [IO::File::WithPath](https://metacpan.org/pod/IO%3A%3AFile%3A%3AWithPath)
- [IPC::Run3](https://metacpan.org/pod/IPC%3A%3ARun3)
- [Moose](https://metacpan.org/pod/Moose)
- [URI::Escape](https://metacpan.org/pod/URI%3A%3AEscape)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [strict](https://metacpan.org/pod/strict)
- [version](https://metacpan.org/pod/version) version 0.77 or later
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Catalyst::View::Wkhtmltopdf
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SECURITY CONSIDERATIONS

**Do not use wkhtmltopdf with untrusted HTML.**

The wkhtmltopdf project [is no longer being maintained](https://wkhtmltopdf.org/status.html),
and the underlying QtWebKit libraries that it uses have been unsupported since 2015.

The [git repository](https://github.com/wkhtmltopdf/wkhtmltopdf) was archived as read-only in 2023.

You should consider migrating to alternative solutions.

It is assumed that the ["command"](#command) attribute is configured by a trusted source (developer or operator).

The options are sent to wkhtmltopdf via stdin, using the `--read-args-from-stdin` option.
However, any options configured through the web application should be considered untrusted and validated.

# SUPPORT

Only the latest version of this module will be supported.

Future releases may only support Perl versions released in the last ten (10) years.

Please report any bugs or feature requests on the bugtracker website
[https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-View-Wkhtmltopdf](https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-View-Wkhtmltopdf)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# AUTHOR

Michele Beltrame <mb@italpro.net>

This module is currently maintained by Robert Rothenberg <perl@rhizomnic.com>.

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2018, 2026 by Michele Beltrame <mb@italpro.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[Catalyst](https://metacpan.org/pod/Catalyst)

[Catalyst::View::TT](https://metacpan.org/pod/Catalyst%3A%3AView%3A%3ATT)

[https://wkhtmltopdf.org](https://wkhtmltopdf.org)
