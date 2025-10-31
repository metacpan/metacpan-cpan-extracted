# App::BlurFill

A simple Perl class for generating blurred background fills for images. Suitable for use in video formatting, social posts, and more.

## Usage from Perl

```perl
use App::BlurFill;

my $blur = App::BlurFill->new(file => 'input.jpg');
$blur->process;  # writes input_blur.jpg
```

## Pre-built applications

The distribution comes with a couple of complete applications that use
App::BlurFill. This will be easier for the end-user to use.

### Command line program - `blurfill`

The `blurfill` program is a standard command line program. You run it like
this:

    blurfill [-w width] [-h height] [-o output_filename] image_filename

If width or height are omitted, they default to 650 pixels and 350 pixels
respectively. If the output filename is omitted, then one will be generated
for you. For example, if you start with `picture.png`, then your output will
be written to `picture_blur.png`.

### Web application

There is also a web application bundled in the standard distribution. You can
run it locally using the standard Perl web application runner, `plackup`.

    plackup bin/app.psgi

Once that program is running you can visit the application in your browser by
going to http://localhost:5000/.

See the
[documentation](https://metacpan.org/dist/Plack/view/script/plackup)
for more information on running web applications using `plackup`.

### Docker container

The web application is also available from the Docker Hub. You can start it by
running:

    docker run -p 8080:3000 davorg/app-blurfill

Once that is running, you can visit it at http://localhost:8080/ - the port
number can be controlled by changing the number in the command.

### Demo version

We will have a demo version available on the internet very soon.

