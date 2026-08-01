# App::BlurFill::Web

A Dancer2 web interface for
[App::BlurFill](https://metacpan.org/dist/App-BlurFill). It lets a user upload
an image, choose output dimensions, preview the processed result and download
it.

The image-processing API and command-line program live in the separate
App-BlurFill distribution. Keeping the web application here means users of the
API and CLI do not need to install Dancer2, Plack or Starman.

## Running locally

Install the distribution's dependencies, then run:

    plackup -Ilib -s Starman -a bin/app.psgi -p 8080

Visit <http://localhost:8080/>.

## Docker container

The web container is layered on the matching `davorg/app-blurfill` image:

    docker build \
      --build-arg APP_BLURFILL_VERSION=0.1.0 \
      -f docker/Dockerfile \
      -t davorg/app-blurfill-web:0.1.0 .

    docker run --rm -p 8080:8080 davorg/app-blurfill-web:0.1.0

The hosted demo is available at <https://blurfill.davecross.co.uk/>.
