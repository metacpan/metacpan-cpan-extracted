# App::BlurFill

A simple Perl class for generating blurred background fills for images. Suitable for use in video formatting, social posts, and more.

## Usage from Perl

```perl
use App::BlurFill;

my $blur = App::BlurFill->new(file => 'input.jpg');
$blur->process;  # writes input_blur.jpg
```

## Command line program - `blurfill`

The `blurfill` program is a standard command line program. You run it like
this:

    blurfill [-w width] [-h height] [-o output_filename] image_filename

If width or height are omitted, they default to 650 pixels and 350 pixels
respectively. If the output filename is omitted, then one will be generated
for you. For example, if you start with `picture.png`, then your output will
be written to `picture_blur.png`.

## Docker container

The `davorg/app-blurfill` image contains the Perl API and the `blurfill`
command, without a web framework. Mount a directory containing an image and
run the command explicitly:

    docker run --rm -v "$PWD:/work" davorg/app-blurfill:0.1.0 \
      blurfill /work/picture.png

The web application is distributed separately as
[App::BlurFill::Web](https://metacpan.org/dist/App-BlurFill-Web) and as the
`davorg/app-blurfill-web` container image.
