# NAME

CSS::SpriteMaker::Simple - generate CSS sprites from a bunch of images

# SYNOPSIS

    say CSS::SpriteMaker::Simple->new->spritify('pics', 'pic1.png')->css;

    # or

    CSS::SpriteMaker::Simple->new
        ->spritify('pics', 'pic1.png')->spurt('sprite.css');

    ...
        <span class="sprite s-FILENAME-OF-PIC"></span>

      <link rel="stylesheet" property="stylesheet" href="sprite.css">
    </body>
    </html>

# DESCRIPTION

Generate a
[CSS sprite](http://en.wikipedia.org/wiki/Sprite_%28computer_graphics%29#Sprites_by_CSS)
using given image files. The result is a a single chunk of CSS code, with
images base64 encoded into it.

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

This code was plucked from a project I was working on and simply quickly
packaged into a CPAN distro. As such, it currently lacks tests.
[Patches are definitely welcome](https://github.com/zoffixznet/CSS-SpriteMaker-Simple).

<div>
    </div></div>
</div>

# METHODS

## `new`

    my $s = CSS::SpriteMaker::Simple->new;

Creates and returns a new `CSS::SpriteMaker::Simple` object.
Takes no arguments.

## `spritify`

    $s->spritify( qw/list of dirs with pics or pics/ );
    $s->spritify( qw/list of dirs with pics or pics/, [qw/ignore these/] );

Returns its invocant. Takes a list of paths and searches them for pics to
use as sprites. The last element can be an arrayref, in which case, this
will be a list of filenames (no directory portion) that will be ignored.

Will croak if no paths are given or it has trouble
creating the temporary directory to assemble the sprite in.

## `css`

    say $s->css;

Returns CSS code of the sprite. Must be called after a call to ["spritify"](#spritify)

## `spurt`

    say $s->spurt('sprite.css');

Write CSS code of the sprite into a file. Must be called after a call to
["spritify"](#spritify)

# SEE ALSO

[Mojolicious::Plugin::AssetPack](https://metacpan.org/pod/Mojolicious::Plugin::AssetPack)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/CSS-SpriteMaker-Simple](https://github.com/zoffixznet/CSS-SpriteMaker-Simple)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/CSS-SpriteMaker-Simple/issues](https://github.com/zoffixznet/CSS-SpriteMaker-Simple/issues)

If you can't access GitHub, you can email your request
to `bug-CSS-SpriteMaker-Simple at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
