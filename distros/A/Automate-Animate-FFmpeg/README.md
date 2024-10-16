# NAME

Automate::Animate::FFmpeg - Create animation from a sequence of images using FFmpeg

# VERSION

Version 0.12

# SYNOPSIS

This module creates an animation from a sequence of input
images using [FFmpeg](https://ffmpeg.org).
An excellent, open source program.

FFmpeg binaries must already be installed in your system.

    use Automate::Animate::FFmpeg;
    my $aaFFobj = Automate::Animate::FFmpeg->new({
      # specify input images in any of these 4 ways or a combination:
      # 1) by specifying each input image (in the order to appear)
      #    in an ARRAYref
      'input-images' => [
        '/xyz/abc/im1.png',
        '/xyz/abc/im2.png',
        ...
      ],
      # 2) by specifying an input pattern (glob or regex)
      #    and optional search path
      'input-pattern' => ['*.png', './'],
      # 3) by specifying an ARRAY of input patterns
      #    (see above)
      'input-patterns' => [
          ['*.tiff'],
          # specify a regex to filter-in all files under search dir
          # NOTE: observe the escaping rules for each quotation method you use
          [qw!regex(/photos2023-.+?\\.png/i)!, 'abc/xyz'],
      ],
      # 4) by specifying a file which contains filenames
      #    of the input images.
      'input-images-from-file' => 'file-containing-a-list-of-pathnames-to-images.txt',

      # optionally specify the duration of each frame=image
      'frame-duration' => 5.3, # seconds

      'output-filename' => 'out.mp4',
    });
    # no animation yet!

    # options can be set after construction as well:

    # optionally add some extra params to FFmpeg as an arrayref
    $aaFF->ffmpeg_extra_params(['-x', 'abc', '-y', 1, 2, 3]);

    # you can also add images here, order is important
    $aaFF->input_images(['img1.png', 'img2.png']) or die;

    # or add images via a search pattern and optional search dir
    $aaFF->input_pattern(['*.png', './']);

    # or add images via multiple search patterns
    $aaFF->input_patterns([
        ['*.png', './'],
        ['*.jpg', '/images'],
        ['*.tiff'], # this defaults to current dir
    ]) or die;

    # and make the animation:
    die "make_animation() has failed"
      unless $aaFF->make_animation()
    ;

# INSTALLATION

During "making the makefile" (`perl Makefile.PL`),
there will be a check to locate the binary `ffmpeg`
in your system. At first it checks if the environment
variable `AUTOMATE_ANIMATE_FFMPEG_PATH` is set, for example,
in \*nix, you can set this variable and do the installation like this:

    AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg perl Makefile.PL

Or, if you do not have direct control to the installation process
(e.g. via cpan/cpanm/package-manager) do it like this:

    export AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg
    cpan -i Automate::Animate::FFmpeg

Or, like this:

    # this opens a shell after fetching the module tarball and unpacking it
    cpanm --look Automate::Animate::FFmpeg
    export AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg
    perl Makefile.PL
    ...

If the environment variable `AUTOMATE_ANIMATE_FFMPEG_PATH` was not set,
the installer will search in the "usual" locations for the ffmpeg
binaries. This is done by [File::Which](https://metacpan.org/pod/File%3A%3AWhich)'s `which()`.

If nothing was found, then it is assumed that `ffmpeg` is not installed.
**But**, the installation will proceed with a warning. Tests
will be run, but they too will succeed (with a warning) on the
absence of an `ffmpeg` executable.
The location
to the `ffmpeg` binaries will be left undefined in the module's
installed scripts and the module will be totally unusable.
This choice was made in order not to fail the tests when
`ffmpeg` is missing from test machines.

Installation of `ffmpeg` binaries is straightforward from
their [website](https://ffmpeg.org//download.html) for Linux, OSX
and windows, if you are still using it. Many Linux distributions
offer `ffmpeg` via their package managers. That, or
download a static build from said website.

# METHODS

## `new`

    my $ret = Automate::Animate::FFmpeg->new({ ... });

All arguments are supplied via a hashref with the following keys:

- `input-images` : an array of pathnames to input images. Image types can be what ffmpeg understands: png, jpeg, tiff, and lots more.
- `input-pattern` : an arrayref of 1 or 2 items. The first item is the pattern
which complies to what [File::Find::Rule](https://metacpan.org/pod/File%3A%3AFind%3A%3ARule) understands (See \[https://metacpan.org/pod/File::Find::Rule#Matching-Rules\]).
For example `*.png`, regular expressions can be passed by enclosing them in `regex(/.../modifiers)`
and should include the `//`. Modifiers can be after the last `/`. For example `regex(/\.(mp3|ogg)$/i)`.

    The optional second parameter is the search path. If not specified, the current working dir will be used.

    Note that there is no implicit or explicit `eval()` in compiling the user-specified
    regex (i.e. when pattern is in the form `regex(/.../modifiers)`).
    Additionally there is a check in place for the user-specified modifiers to the regex:
    `die "never trust user input" unless $modifiers=~/^[msixpodualn]+$/;`.
    Thank you [Discipulus](https://www.perlmonks.org/?node_id=174111).

- `input-patterns` : same as above but it expects an array of `input-pattern`.
- `input-images-from-file` : specify the file which contains pathnames to image files, each on its own line.
- `ffmpeg-extra-params` : pass extra parameters to the `ffmpeg` executable as an arrayref of arguments, each argument must be a separate item as in : `['-i', 'file']`.
- `frame-duration` : set the duration of each frame (i.e. each input image) in the animation in (fractional) seconds.
- `qw/verbosity` : set the verbosity, 0 being mute.

Return value:

- `undef` on failure or the blessed object on success.

This is the constructor. It instantiates the object which does the animations. Its
input parameters can be set also via their own setter methods.
If input images are specified during construction then the list
of filenames is constructed and kept in memory. Just the filenames.

## `make_animation()`

    $aaFF->make_animation() or die "failed";

It initiates the making of the animation by shelling out to `ffmpeg`
with all the input images specified via one or more calls to any of:

- input\_images($m)
- input\_pattern($m)
- input\_patterns($m)
- input\_file\_with\_images($m)

On success, the resultant animation will be
written to the output file
(specified using [output\_filename($m)](https://metacpan.org/pod/output_filename%28%24m%29) before the call.

Return value:

- 0 on failure, 1 on success.

## `input_images($m)`

    my $ret = $aaFF->input_images($m);

It sets or gets the list (as an ARRAYref) of all input images currently in the list
of images to create the animation. The optional input parameter, `$m`,
is an ARRAYref of input images (their fullpath that is) to create
the animation.

Return value:

- the list, as an ARRAYref, of the image filenames currently
set to create the animation.

## `input_pattern($m)`

    $aaFF->input_pattern($m) or die "failed";

Initiates a search via [File::Find::Rule](https://metacpan.org/pod/File%3A%3AFind%3A%3ARule) for the
input image files to create the animation using
the pattern `$m->[0]` with starting search dir being `$m->[1]`,
which is optional -- default being `Cwd::cwd` (current working dir).
So, `$m` is an array ref of one or two items. The first is the search
pattern and the optional second is the search path, defaulting to the current
working dir.

The pattern (`$m->[0]`) can be a shell wildcard, e.g. `*.png`,
or a regex specified as `regex(/REGEX-HERE/modifiers)`, for example
`regex(/\.(mp3|ogg)$/i)` Both shell wildcards and regular expressions
must comply with what [File::Find::Rule](https://metacpan.org/pod/File%3A%3AFind%3A%3ARule) expects, see \[https://metacpan.org/pod/File::Find::Rule#Matching-Rules\].

The results of the search will be added to the list of input images
in the order of appearance.

Multiple calls to `input_pattern()` will load
input images in the order they are found.

`input_pattern()` can be combined with `input_patterns()`
and `input_images()`. The input images list will increase
in the order they are called.

**Caveat**: the regex is parsed, compiled and passed on to [File::Find::Rule](https://metacpan.org/pod/File%3A%3AFind%3A%3ARule).
Escaping of special characters (e.g. the backslash) may be required.

**Caveat**: the order of the matched input images is entirely up
to [File::Find::Rule](https://metacpan.org/pod/File%3A%3AFind%3A%3ARule). There may be unexpected results
when filenames contain unicode characters. Consider
these orderings for example:

- `blue.png, κίτρινο.png, red.png`,
- `blue.png, γάμμα.png, κίτρινο.png, red.png`,
- `blue.png, κίτρινο.png, γαμμα.png red.png`,

Return value:

- 0 on failure, 1 on success.

## `input_patterns($m)`

    $aaFF->input_patterns($m) or die "failed";

Argument `$m` is an array of arrays each composed of one or two items.
The first argument, which is mandatory, is the search pattern.
The optional second argument is the directory to start the search.
For each item of `@$m` it calls [input\_pattern($m)](https://metacpan.org/pod/input_pattern%28%24m%29).

`input_patterns()` can be combined with `input_pattern()`
and `input_images()`. The input images list will increase
in the order they are called.

Return value:

- 0 on failure, 1 on success.

## `output_filename($m)`

    my $ret = $aaFF->output_filename($m);

It sets or gets the output filename of the animation.

When setting an output filename, make sure you
specify its extension and it does make sense to FFmpeg (e.g. mp4).

Return value:

- the current output filename.

## `input_file_with_images($m)`

    $aaFF->input_file_with_images($m) or die "failed";

Reads file `$m` which must contain filenames, one filename
per line, and adds the up to the list of input images to create the
animation.

Return value:

- 0 on failure, 1 on success.

## `num_input_images()`

    my $N = $aaFF->num_input_images();

Return value:

- on success, it returns the number of input images currently
in the list to create the animation. On failure, or when there
are now images to create the animation, it returns 0.

## `clear_input_images()`

    $aaFF->clear_input_images();

It clears the list of input images to create an animation.
Zero, null, it's over for Bojo.

## `ffmpeg_executable()`

    my $ret = $aaFF->ffmpeg_executable();

You can not change the path to the executable mid-stream.

Return value:

- on success, it returns the path to `ffmpeg` executable
as it was set during module installation.
The return value will be `undef` if `ffmpeg` executable was not
detected during installation.

## `verbosity($m)`

    my $ret = $aaFF->verbosity($m);

It sets or gets the verbosity level. Zero being mute.

Return value:

- the current verbosity level.

## `frame_duration($m)`

    my $ret = $aaFF->frame_duration($m);

It sets or gets the frame duration in (fractional) seconds.
Frame duration is the time that each frame(=image) appears
in the produced animation.

Return value:

- the current frame duration in (fractional) seconds.

# SCRIPTS

A script for making animations from input images using `ffmpeg`
is provided: `automate-animate-ffmpeg.pl`.

It accepts the following options:

    --input-image I [--input-image I2 ...] : specify the full path of an
    image to be added to the animation. Multiple images are expected.

      OR

    --input-images-from-file F [--input-images-from-file F2 ...] :
    specify a file which contains a list of input images to be
    animated, each on its own line. Multiple images are expected.

      OR

    --input-pattern/-p P [D] : specify a pattern and optional search
    dir to select the files from disk. This pattern must be accepted
    by File::Find::Rule::name(). If search dir is not specified,
    the current working dir will be used.

    --output-filename/-o O : the filename of the output animation.

    [--frame-duration/-d SECONDS : specify the duration of each
    frame=input image in (fractional) seconds.]

    [--verbosity/-V N : specify verbosity. Zero being the mute.
    Default is 0.]

As an example,

    automate-animate-ffmpeg.pl \
       --input-pattern '*.png' 't/t-data/images' \
       --output-filename out.mp4 \
       --frame-duration 3.5

    # or

    automate-animate-ffmpeg.pl \
       --input-pattern 'regex(/.+?.png/i)' \
       --output-filename out.mp4 \
       --frame-duration 3.5

## UNICODE FILENAMES

Unicode filenames are supported ... I think. Please report
any problems.

# AUTHOR

Andreas Hadjiprocopis, `<bliako at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-automate-animate-ffmpeg at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Automate-Animate-FFmpeg](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Automate-Animate-FFmpeg).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Automate::Animate::FFmpeg

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Automate-Animate](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Automate-Animate)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Automate-Animate](http://annocpan.org/dist/Automate-Animate)

- Review this module at PerlMonks

    [https://www.perlmonks.org/?node\_id=21144](https://www.perlmonks.org/?node_id=21144)

- Search CPAN

    [https://metacpan.org/release/Automate-Animate](https://metacpan.org/release/Automate-Animate)

# ACKNOWLEDGEMENTS

- A big thank you to [FFmpeg](https://ffmpeg.org), an
excellent, open source software for all things moving.
- A big thank you to [PerlMonks](https://perlmonks.org)
for the useful [discussion](https://perlmonks.org/?node_id=11156484)
on parsing command line arguments as a string. And an even bigger
thank you to [PerlMonks](https://perlmonks.org) for just being there.
- On compiling a regex when pattern and modifiers are in
variables, [discussion](https://www.perlmonks.org/?node_id=1210675)
at [PerlMonks](https://perlmonks.org).
- A big thank you to Ace, the big dog. Bravo Ace!

# LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
