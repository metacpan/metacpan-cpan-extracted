# NAME

Catalyst::View::ChromePDF - convert HTML (or TT) content to PDF using Chrome

# SYNOPSIS

In your application, create a view, e.g. `lib/MyApp/View/ChromePDF.pm`:

```perl
package MyApp::View::ChromePDF;

use Moose;
extends 'Catalyst::View::ChromePDF';

__PACKAGE__->meta->make_immutable();
```

In the application, e.g. `lib/MyApp.pm` specify the ["CONFIGURATION"](#configuration):

```perl
__PACKAGE__->config(

    # Configure Template-Toolkit

    'View::TT' => {
        INCLUDE_PATH       => [ __PACKAGE__->path_to('root'), ],
        ENCODING           => 'utf-8',
        TIMER              => 0,
        TEMPLATE_EXTENSION => '.tt',
        ABSOLUTE           => 1,
        render_die         => 1
    },

    # Configure View::ChromePDF

    'View::ChromePDF' => {
        stash_key => 'pdf',
        page_size => 'a4',
    },

);
```

In a controller method, specify ["PARAMETERS"](#parameters):

```perl
$c->stash->{pdf} = {
  template  => 'base.tt',
  page_size => 'a5',      # override default
};

$c->forward('View::ChromePDF');
```

# DESCRIPTION

This is a [Catalyst](https://metacpan.org/pod/Catalyst) view for rendering web pages of PDFs using Chrome or a Chrome-compatible browser with
[WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome).

It is intended as a successor to [Catalyst::View::Wkhtmltopdf](https://metacpan.org/pod/Catalyst%3A%3AView%3A%3AWkhtmltopdf).

# RECENT CHANGES

Changes for version v0.1.2 (2026-08-10)

- Bug Fixes
    - Use Try::Tiny for Perls without the try feature.

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Catalyst::View](https://metacpan.org/pod/Catalyst%3A%3AView)
- [File::Spec](https://metacpan.org/pod/File%3A%3ASpec)
- [IO::File::WithPath](https://metacpan.org/pod/IO%3A%3AFile%3A%3AWithPath)
- [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)
- [Moose](https://metacpan.org/pod/Moose)
- [MooseX::Aliases](https://metacpan.org/pod/MooseX%3A%3AAliases)
- [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)
- [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)
- [Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny)
- [Types::Common](https://metacpan.org/pod/Types%3A%3ACommon)
- [WWW::Mechanize::Chrome](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3AChrome)
- [experimental](https://metacpan.org/pod/experimental)
- [namespace::autoclean](https://metacpan.org/pod/namespace%3A%3Aautoclean)
- [perl](https://metacpan.org/pod/perl) version v5.24.0 or later

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Catalyst::View::ChromePDF
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

## HTML

It is assumed that the content of the rendered HTML that as saved as a PDF is controlled and trusted by the developer.

The default configuration of ["mech"](#mech) does not block `file:` URLs.
That is a feature, not a bug or oversight.

## Temporary Files

Temporary HTML and PDF files are saved in ["tmpdir"](#tmpdir).
They may be left in the directory on failure.

When returning a filehandle instead of the PDF content, the PDF files are not removed when ["send\_filehandle"](#send_filehandle) is true.

A separate process will need to purge files, to prevent them from filling the disk, as well as to remove sensitive information.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.24 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Catalyst-View-ChromePDF/issues](https://github.com/robrwo/perl-Catalyst-View-ChromePDF/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website.
Please see `SECURITY.md` for instructions how to report security vulnerabilities

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Catalyst-View-ChromePDF](https://github.com/robrwo/perl-Catalyst-View-ChromePDF)
and may be cloned from [https://github.com/robrwo/perl-Catalyst-View-ChromePDF.git](https://github.com/robrwo/perl-Catalyst-View-ChromePDF.git)

# AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

The initial development of this module was sponsored in part by Science Photo Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Robert Rothenberg <perl@rhizomnic.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
