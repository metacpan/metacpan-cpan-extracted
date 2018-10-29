# NAME

Alien::TidyHTML5 - Download and install HTML Tidy

# VERSION

version v0.2.0

# DESCRIPTION

This distribution provides tidy (a.k.a. "libtidy" or "html-tidy")
v5.6.0 or newer, so that it can be used by other Perl
distributions. . It does this by first trying to detect an existing
install of tidy on your system. If found it will use that. If it
cannot be found, the source code will be downloaded from the official
git repository, and it will be installed in a private share location
for the use of other modules.

# METHODS

## `exe_file`

This returns the path of the `tidy` executable.

# SEE ALSO

[http://www.html-tidy.org/](http://www.html-tidy.org/)

[Alien::Build::Manual::AlienUser](https://metacpan.org/pod/Alien::Build::Manual::AlienUser)

# SOURCE

The development version is on github at [https://github.com/robrwo/Alien-TidyHTML5](https://github.com/robrwo/Alien-TidyHTML5)
and may be cloned from [git://github.com/robrwo/Alien-TidyHTML5.git](git://github.com/robrwo/Alien-TidyHTML5.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Alien-TidyHTML5/issues](https://github.com/robrwo/Alien-TidyHTML5/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Slaven Rezić <slaven@rezic.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
