package Catalyst::Controller::Imager;
$Catalyst::Controller::Imager::VERSION = '0.06';
use Moose;
use Moose::Util::TypeConstraints;
# w/o BEGIN, :attrs will not work
BEGIN { extends 'Catalyst::Controller'; }

# use File::stat;
use Imager;
use MIME::Types;

subtype 'IntMax100'
    => as 'Int'
    => where { $_ > 0 && $_ <= 100 }
    => message { "the number $_ is not in range 1..100" };

has root_dir       => (is => 'rw',
                       default => sub { 'static/images' } );
has cache_dir      => (is => 'rw',
                       default => sub { undef } );
has default_format => (is => 'rw',
                       default => sub { 'jpg' } );
has max_size       => (is => 'rw',
                       default => sub { 1000 } );
has thumbnail_size => (is => 'rw',
                       default => sub { 80 } );
has jpeg_quality   => (is => 'rw',
                       isa => 'IntMax100',
                       default => 95 );

=head1 NAME

Catalyst::Controller::Imager - generate scaled or mangled images

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    # use the helper to create your Controller
    script/myapp_create.pl controller Image Imager
    
    # DONE. READY FOR USE.
    
    
    
    # Just use it in your template:
    # will deliver a 200 pixel wide version of some_image.png as jpg
    <img src="/image/w-200/some_image.png.jpg" />
    
    # will deliver a 210 by 300 pixel sized image without conversion
    # (empty areas will be white)
    <img src="/image/w-210-h-300/other_image.jpg" />

    # will deliver a 80 by 80 pixel sized image
    # (empty areas will be white)
    <img src="/image/thumbnail/other_image.jpg" />
    
    # define a modifier of your own
    <img src="/image/blur-9/some_image.png.jpg" />
    
    # your modifier plus a predefined one
    <img src="/image/thumbnail-blur-9/some_image.png.jpg" />

    # same thing as above
    <img src="/image/blur-9-thumbnail/some_image.png.jpg" />
    
    
    
    # in your Controller you then need:
    sub want_blur :Action :Args(1) {
        ### do something to get a blurred image
    }

=head1 DESCRIPTION

A Catalyst Controller that generates image files in any size you request and
optionally converts the image format. Images are taken from a cache directory
if possible and desired or generated on the fly. The Cache-directory has a
structure that is very similar to the URI scheme, so a redirect rule in your
webserver's setup would do this job also.

The URI of an image consists of always the same parts:

=over

=item the action namespace

If your Controller is named C<MyApp::Controller::Image>, this first part will
be C<image>.

=item modifier(s)

Here a series of modifiers and arguments separated with single dashes ('-')
are used.

    h-100        # will request an image's height
    w-200        # will request an image's width
    h-80-w-20    # both, height and width will apply
    thumbnail    # a configurable square (defaults to 80)

=item image path

This is the relative path to the image that should get rendered

=item extension (optional)

If an additional option like C<.gif> is added immediately after the image
path, this format is requested for delivery.

=back

A Controller that is derived from C<Catalyst::Controller::Imager> may define
its own modifier functions. See EXTENDING below.

Possible initially defined options are:

=over

=item w-n

specifies the width of the image to generate. The height is adjusted to
maintain the same ratio as the original image. The maximum size is controlled
by a configuration parameter C<max_size> that defaults to 1000.

Can be used in conjunction with h-n. However, if both options are given, the
image will scale to fill the given area either by width or by height, get
centered inside the area and additional spaces will get filled with white.

=item h-n

specifies the height of the image to generate. The width is adjusted to
maintain the same ratio as the original image. The maximum size is controlled
by a configuration parameter C<max_size> that defaults to 1000.

Can be used in conjunction with w-n. However, if both options are given, the
image will scale to fill the given area either by width or by height, get
centered inside the area and additional spaces will get filled with white.

=item thumbnail

requests the generation of a thumbnail image. Defaults to a maximum size of
C<thumbnail_size>. The size can get changed by a simple configuration
parameter.

=back

=head2 Configuration

A simple configuration of your Controller could look like this:

    __PACKAGE__->config(
        # the directory to look for files (inside root)
        # defaults to 'static/images'
        root_dir => 'static/images',
        
        # specify a cache dir if caching is wanted
        # defaults to no caching (more expensive)
        cache_dir => undef,
        
        # specify a format that will get delivered if
        # not guessable from the file extension
        # defaults to 'jpg'
        default_format => 'jpg'
        
        # specify a maximum value for width and height of images
        # defaults to 1000 pixels
        max_size => 1000,
                
        # specify the size of thumbnails (always square)
        # defaults to 80 pixels
        thumbnail_size => 80,

        # set jpeg quality
        # defaults to 95
        jpeg_quality => 95,
    );

=head2 Caching

If caching is enabled (by setting the C<cache_dir> configuration parameter),
every image rendered will get saved into the cache directory if it exists and
the directory is writable.

The path of a cached image inside the cache directory is identical to the URI
part after the action namespace. Thus, a properly configured webserver might
take over the responsibility to deliver static images from cache removing the
burden from your Catalyst Controller.

=head1 INTERNALS

This base class defines a Chained dispatch chain consisting of the following
Action methods. Each method is responsible for eating up a defined part of the
URI. The URI always consists of 3 parts: The namespace, a format and size
modifier and a relative path to the image in question optionally with another
file extension added for format conversion.

=head2 Action Chain

To allow easy modification the URI dispatching is left to Catalyst. The
following C<:Chained> actions each work on a stage of the image construction.
The final image will get delivered by the C<end> action.

=over 8

=item base

consumes the namespace of the controller inheriting this one.

=item scale

consumes a single URI part. If the part is a concatenation of several things
joined with a dash '-', then these things are regarded as either arguments to
an action or further actions with their arguments.

If a modifier is named 'blur' and needs a single parameter, you may define a
method like:

    sub blur :Action :Args(1) {
        # do something to blur
    }

During this stage, the only thing that happens is recording every modification
into a series of stash-variables.

=item image

The final stage consumes the image path and tries to find the image in question.

After the image is found, a forward to 'generate_image' is issued which does
the conversion we want.

=back

=head2 Stash Variables

All action methods communicate with each other by setting or retrieving stash
variables.

=over 16

=item image_path

relative path to original image

=item image

Imager Object as soon as image is loaded

=item image_data

binary image data after conversion or from cache

=item cache_path

relative path to cached image

=item format

format for conversion

=item scale

{ w => n, h => n, mode => min/max/fit/fill }

=item before_scale

list of Actions executed before scaling ### FIXME: action or subref???

=item after_scale

list of Actions executed after scaling ### FIXME: action or subref???

=back

=head1 EXTENDING

The magic behind all the conversions is the existence of specially named
action methods (their name starts with 'want_' or 'scale_').

=over 8

=item want_

Actions starting with 'want_' get triggered if the URI part after the package
namespace contains a word that matches the remainder of the action's name. The
C<:Arg()> attribute specifies how many additional parts this action will need
for its operation.

=item scale_

One part of the scaling hash inside stash is a scaling mode. Depending on
the name of the scaling mode, an action named 'scale_mode' is used to
process the scaling.

=back

If you plan to offer URIs like:

    /image/small/image.jpg
    /image/size-200-300/image.jpg
    /image/watermark/image.jpg
    
    # or a combination of them:
    /image/size-200-300-watermark/image.jpg
    
    # but not invalid things:
    /image/size-200/image.jpg

you may build these action methods:

    sub want_small :Action :Args(0) {
        my ($self, $c) = @_;
        
        $c->stash(scale => {w => 200, h => 200, mode => 'fill'});
    }

    sub want_size :Action :Args(2) {
        my ($self, $c, $w, $h) = @_;
        
        $c->stash(scale => {w => $w, h => $h, mode => 'fill'});
    }
    
    sub want_watermark :Action :Args(0) {
        my ($self, $c) = @_;
        
        ### FIXME: action or subref???
        push @{$c->stash->{after_scale}}, \&watermark_generator;
    }

=head1 METHODS

=cut

=head2 BUILD
=cut

sub BUILD {
    my $self = shift;
    my $c = $self->_app;

    $c->log->warn(ref($self) . " - directory '" . $self->root_dir . "' not present.")
        if (!-d $c->path_to('root', $self->root_dir));
}

=head2 base :Chained :PathPrefix :CaptureArgs(0)

start of the action chain -- eats package namespace, eg. /image

=cut

sub base :Chained :PathPrefix :CaptureArgs(0) {
    my ($self, $c) = @_;
    
    # init stash
    $c->stash(image_path   => []);               # path-parts to the image
    $c->stash(image        => undef);            # Imager object
    $c->stash(image_data   => undef);            # binary data for delivery
    $c->stash(cache_path   => []);               # part-parts to cached image
    $c->stash(scale        => {
                                w => undef,
                                h => undef,
                                mode => 'min',
                              });
    $c->stash(format       => undef);            # file format
    $c->stash(before_scale => []);               # actions to run before scale
    $c->stash(after_scale  => []);               # actions to run after scale
}

=head2 scale :Chained('base') :PathPart('') :CaptureArgs(1)

second chain step -- eat up modifier parameter(s)

Modifier parameters and their args must be separated by single dashes ('-').
For every modifier there must exist an action named C<want_modifiername>
declared with the number of args it wants to consume

    # modifier 'h', one argument
    # eg h-200
    sub want_h :Action :Arg(1)
    
    # modifier 'size, two arguments
    # eg size-300-200
    sub want_size :Action :Arg(2)

=cut

sub scale :Chained('base') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $capture) = @_;
    
    #$c->log->debug('captures: ' . join(',', @{$c->req->captures}));
    #$c->log->debug("capture=$capture");
    
    push @{$c->stash->{cache_path}}, $capture;
    
    my @args = split(/-/, $capture);
    while (scalar(@args)) {
        my $action_name = 'want_' . shift @args;
        my $action = $self->action_for($action_name);
        die "unknown action: $action_name" if (!$action);
        
        my $nr_args = ($action->attributes->{Args} || [])->[0] || 0;
        
        $c->forward($action, [ splice(@args, 0, $nr_args) ]);
    }
}

=head2 image :Chained('scale') :PathPart('') :Args

final chain step --consumes image path relative to root_dir plus optional
format extension for conversion

=cut

sub image :Chained('scale') :PathPart('') :Args {
    my ($self, $c, @path) = @_;

    die 'no file name given' if (!scalar(@path));
    
    push @{$c->stash->{cache_path}}, @path;
    my $last_uri_part = pop @path;
    my $file_name = $last_uri_part;
    
    # guess file format
    if ($last_uri_part =~ m{(\.\w+) \z}xms) {
        $c->stash->{format} ||= Imager::def_guess_type($1);
    }
    
    # find real image file by stripping extensions
    while (!-f $c->path_to('root', $self->root_dir, @path, $file_name)) {
        die 'requested image file "' . join('/', @path, $file_name) . '" not found'
            if $file_name !~ s{\. \w+ \z}{}xms;
    }
    
    push @{$c->stash->{image_path}}, @path, $file_name;
    
    # request conversion or cache-retrieval
    $c->forward('convert_image');
}

=head2 convert_image :Action

The converting function. Consumes all conversion-relevant parameters from
stash and does the conversion (or delivers a file from stash).

=cut
sub convert_image :Action {
    my ($self, $c) = @_;
    
    my $cache_dir  = $self->cache_dir 
                     ? $c->path_to($self->cache_dir) 
                     : undef;
    my $cache_path = $self->cache_dir
                     ? $c->path_to($self->cache_dir, @{$c->stash->{cache_path}})
                     : undef;
    my $file_path  = $c->path_to('root', $self->root_dir, @{$c->stash->{image_path}});
    
    if ($cache_path && -f $cache_path && -M $cache_path < -M $file_path) {
        #
        # caching wanted and cached image available
        #
        $c->stash->{image_data} = $cache_path->slurp();
    } else {
        #
        # we must calculate
        #
        $c->stash->{image} = Imager->new();
        $c->stash->{image}->read(file => $file_path) or die "cannot load image '$file_path'";
        
        #
        # apply things requested before scaling
        #
        $c->forward($_)
            for @{$c->stash->{before_scale}};
        
        #
        # scale (if wanted)
        #
        my $scale = $c->stash->{scale};
        if ($scale && ref($scale) eq 'HASH' && scalar(keys(%{$scale}))) {
            my $scale_mode   = $c->stash->{scale}->{mode} || 'min';
            my $scale_action = $self->action_for("scale_$scale_mode");
            die "scale action 'scale_$scale_mode' not found." if (!$scale_action);
            $c->forward($scale_action);
        }

        #
        # apply things requested after scaling
        #
        $c->forward($_)
            for @{$c->stash->{after_scale}};
        
        #
        # create destination image format
        #
        my $data;
        $c->stash->{image}->write(type => $c->stash->{format} || 'jpeg', 
                                  jpegquality => $self->jpeg_quality,
                                  data => \$data);
        $c->stash->{image_data} = $data;

        #
        # put into cache if wanted
        #
        if ($cache_path && -d $cache_dir && -w $cache_dir && $data) {
            if (!-d $cache_path->dir) {
                $cache_path->dir->mkpath();
            }

            if (open(my $cache_file, '>', $cache_path)) {
                print $cache_file $data;
                close($cache_file);
            }
        }
    }
}

=head2 end :Action

deliver the data or fire a 404-status in case something went wrong.

Yes, I know, a 404 means 'not found', but for the end-user there is no
difference between a not found image and an error that occured. And basically
if somebody puts rubbush into the URL and calling an unknown action internally
is a Internal server error, but for the end-user the requested image and its
modification could not get retrieved.

=cut

sub end :Action {
    my ($self, $c) = @_;

    if (scalar(@{$c->error}) || !$c->stash->{image_data}) {
        #$c->log->debug('error_encountered: ' . join(',', @{$c->error}));
        $c->response->body('image error...' . join(',', @{$c->error}));
        $c->log->debug(join(',', @{$c->error}));
        $c->response->status(404);
        $c->clear_errors;
    } else {
        my $types = MIME::Types->new();
        my $mime = $types->mimeTypeOf($c->stash->{format});
        $c->response->headers->content_type("$mime" || 'image/unknown');
        $c->response->body($c->stash->{image_data});
    }
}

################################################# SCALERs

=head2 scale_min :Action

scales an image by the minimum scaling factor needed to either match the
desired width or height.

=cut

sub scale_min :Action {
    my ($self, $c) = @_;

    my $scale = $c->stash->{scale} || {};
    $c->stash->{image} = _scale($c->stash->{image}, $scale->{w}, $scale->{h}, 'min');
}

=head2 scale_max :Action

scales an image by the maximum scaling factor needed to either match the
desired width or height.

=cut

sub scale_max :Action {
    my ($self, $c) = @_;

    my $scale = $c->stash->{scale} || {};
    $c->stash->{image} = _scale($c->stash->{image}, $scale->{w}, $scale->{h}, 'max');
}

=head2 scale_fit :Action

first scales an image by the maximum scaling factor needed to either match the
desired width or height. Then, crops the image to make it fit the desired size.

=cut

sub scale_fit :Action {
    my ($self, $c) = @_;

    my $scale = $c->stash->{scale} || {};
    my $w = $scale->{w};
    my $h = $scale->{h};
    my $image = _scale($c->stash->{image}, $w, $h, 'max');
    
    if ($w && $h && $image->getwidth >= $w && $image->getheight >= $h) {
        # both are requested and too big
        my $l = int(($image->getwidth - $w) / 2);
        my $t = int(($image->getheight - $h) / 2);
        $c->stash->{image} = $image->crop(left => $l, right => $l + $w,
                                          top => $t, bottom => $t + $h);
    } else {
        $c->stash->{image} = $image;
    }
}

=head2 scale_fill :Action

scales an image by the minimum scaling factor needed to either match the
desired width or height. Then, expand the image with white color to make it
fit the desired size.

=cut

sub scale_fill :Action {
    my ($self, $c) = @_;

    my $scale = $c->stash->{scale} || {};
    my $w = $scale->{w};
    my $h = $scale->{h};
    my $image = _scale($c->stash->{image}, $scale->{w}, $scale->{h}, 'min');
    if ($w && $h && $image->getwidth <= $w && $image->getheight <= $h) {
        # both are requested and too small
        my $new_image = Imager->new(xsize => $w, ysize => $h, channels => $image->getchannels);
        my $bgcolor = Imager::Color->new(255,255,255);
        $new_image->box(color => $bgcolor,
                        xmin => 0, ymin => 0,
                        xmax => $w, ymax => $h,
                        filled => 1);
        my $l = int(($w - $image->getwidth) / 2);
        my $t = int(($h - $image->getheight) / 2);
        $c->stash->{image} = $new_image->compose(src => $image,
                                                 tx => $l, ty => $t);
    } else {
        $c->stash->{image} = $image;
    }
}

# scaling helper : returns new image of desired size
sub _scale {
    my ($image, $w, $h, $type) = @_;

    my %options = (
        ($w ? (xpixels => $w) : ()),
        ($h ? (ypixels => $h) : ()),
    );
    $options{type} = $type || 'min' if ($w && $h);

    return scalar(keys(%options)) ? $image->scale(%options) : $image;
}

################################################# MODIFIERs

=head2 want_thumbnail :Action :Args(0)

Logic for the 'thumbnail' modifier without further args. Sets the requested
width and height to the C<thumbnail_size> configuration parameter (default is 80).

=cut

sub want_thumbnail :Action :Args(0) {
    my ($self, $c) = @_;
    
    $c->stash(scale => {w => $self->thumbnail_size, h => $self->thumbnail_size, mode => 'fill'});
}

=head2 want_w :Action :Args(1)

Logic for the 'w' modifier with one arg. Sets the requested width of the image.

=cut

sub want_w :Action :Args(1) {
    my ($self, $c, $arg) = @_;
    
    die "width ($arg) must be numeric" if ($arg !~ m{\A \d+ \z}xms);
    die "width ($arg) out of range" if ($arg < 1 || $arg > $self->max_size);
    
    $c->stash(scale => {w => $arg, mode => 'fill'});
}

=head2 want_h :Action :Args(1)

Logic for the 'h' modifier with one arg. Sets the requested height of the image.

=cut

sub want_h :Action :Args(1) {
    my ($self, $c, $arg) = @_;
    
    die "height ($arg) must be numeric" if ($arg !~ m{\A \d+ \z}xms);
    die "height ($arg) out of range" if ($arg < 1 || $arg > $self->max_size);
    
    $c->stash(scale => {h => $arg, mode => 'fill'});
}

=head1 BUGS

probably many... Don't get confused if tests fail and carefully read the
messages. The test-suite only will pass if Imager is configured with gif, jpeg
and png support. In doubt install the required binary libraries and reinstall
Imager.

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
