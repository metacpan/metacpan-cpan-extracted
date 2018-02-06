# NAME

CSS::Packer - Another CSS minifier

<div>

    <a href='https://travis-ci.org/leejo/css-packer-perl?branch=master'><img src='https://travis-ci.org/leejo/css-packer-perl.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/leejo/css-packer-perl'><img src='https://coveralls.io/repos/leejo/css-packer-perl/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

Version 2.05

# DESCRIPTION

A fast pure Perl CSS minifier.

# SYNOPSIS

    use CSS::Packer;

    my $packer = CSS::Packer->init();

    $packer->minify( $scalarref, $opts );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $packer->minify( $scalarref, $opts );

For backward compatibility it is still possible to call 'minify' as a function:

    CSS::Packer::minify( $scalarref, $opts );

First argument must be a scalarref of CSS-Code.
Second argument must be a hashref of options. Possible options are:

- compress

    Defines compression level. Possible values are 'minify' and 'pretty'.
    Default value is 'pretty'.

    'pretty' converts

        a {
        color:          black
        ;}   div

        { width:100px;
        }

    to

        a{
        color:black;
        }
        div{
        width:100px;
        }

    'minify' converts the same rules to

        a{color:black;}div{width:100px;}

- copyright

    You can add a copyright notice at the top of the script.

- remove\_copyright

    If there is a copyright notice in a comment it will only be removed if this
    option is set to a true value. Otherwise the first comment that contains the
    word "copyright" will be added at the top of the packed script. A copyright
    comment will be overwritten by a copyright notice defined with the copyright
    option.

- no\_compress\_comment

    If not set to a true value it is allowed to set a CSS comment that
    prevents the input being packed or defines a compression level.

        /* CSS::Packer _no_compress_ */
        /* CSS::Packer pretty */

# AUTHOR

Merten Falk, `<nevesenin at cpan.org>`. Now maintained by Lee
Johnson (LEEJO)

# BUGS

Please report any bugs or feature requests through
the web interface at [http://github.com/leejo/css-packer-perl/issues](http://github.com/leejo/css-packer-perl/issues).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

perldoc CSS::Packer

# COPYRIGHT & LICENSE

Copyright 2008 - 2011 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

# SEE ALSO

[CSS::Minifier](https://metacpan.org/pod/CSS::Minifier),
[CSS::Minifier::XS](https://metacpan.org/pod/CSS::Minifier::XS)
