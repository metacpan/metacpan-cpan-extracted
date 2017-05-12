[![Build Status](https://travis-ci.org/ziguzagu/perl-css-parse-packed.svg?branch=master)](https://travis-ci.org/ziguzagu/perl-css-parse-packed)
# NAME

CSS::Parse::Packed - A CSS::Parse module packed duplicated selectors.

# SYNOPSIS

    use CSS;
    my $css = CSS->new({ parser => 'CSS::Parse::Packed' });

# DESCRIPTION

This module is a parser for CSS.pm. It parsing CSS by regular expression
based on CSS::Parse::Lite and packed duplicated selectors.

# EXAMPLE

Original is:

    body { background-color:#FFFFFF; font-size: 1em; }
    body { padding:6px; font-size: 1.5em; }

After parsing:

    body { padding: 6px; background-color: #FFFFFF; font-size: 1.5em }

# SEE ALSO

[CSS](https://metacpan.org/pod/CSS), [CSS::Parse::Lite](https://metacpan.org/pod/CSS::Parse::Lite)

# AUTHOR

Hiroshi Sakai  `<ziguzagu@cpan.org>`

# LICENCE AND COPYRIGHT

Copyright (c) 2007, Hiroshi Sakai `<ziguzagu@cpan.org>`. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
