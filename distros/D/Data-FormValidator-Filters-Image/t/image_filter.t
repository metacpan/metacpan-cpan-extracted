#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';
use FakeUpload qw(fake_upload);
use Data::FormValidator;
use Data::FormValidator::Filters::Image qw(image_filter);
use Image::Size qw(imgsize);
use File::Slurp qw(slurp);
use File::stat;
use Test::More tests => 30;

###############################################################################
### TEST DATA
###############################################################################
my $test_image    = 't/data/image.jpg';
my $test_empty    = 't/data/empty.jpg';
my $test_textfile = 't/data/file.txt';

###############################################################################
# TEST: exceeds max height
image_exceeds_max_height: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_width   => 75,
                max_height  => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (image exceeds max height)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w, 37, '... image width';
    is $img_h, 50, '... image height';
}

###############################################################################
# TEST: exceeds max width
image_exceeds_max_width: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_width   => 50,
                max_height  => 75,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (image exceeds max width)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w, 50, '... image width';
    is $img_h, 66, '... image height';
}

###############################################################################
# TEST: exceeds max width, no max height specified
image_exceeds_max_width_no_max_height: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_width   => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (image exceeds max width, no max height)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w, 50, '... image width';
    is $img_h, 66, '... image height';
}

###############################################################################
# TEST: exceeds max height, no max width specified
image_exceeds_max_height_no_max_width: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_height  => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (image exceeds max height, no max width)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w, 37, '... image width';
    is $img_h, 50, '... image height';
}

###############################################################################
# TEST: no options given
image_no_options_given: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (no max size given)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w,  75, '... image width';
    is $img_h, 100, '... image height';

    # not only should image size be the same, but also filesize (if it got
    # resized then it would likely change filesize)
    my $orig_size    = stat($test_image)->size();
    my $resized_size = length($image);
    is $resized_size, $orig_size, '... file size same (image unfiltered)';
}

###############################################################################
# TEST: image already within max limits
image_already_within_max_limits: {
    my $cgi     = fake_upload( image => [$test_image] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_width   => 100,
                max_height  => 100,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (already within max limits)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w,  75, '... image width';
    is $img_h, 100, '... image height';

    # not only should image size be the same, but also filesize (if it got
    # resized then it would likely change filesize)
    my $orig_size    = stat($test_image)->size();
    my $resized_size = length($image);
    is $resized_size, $orig_size, '... file size same (image unfiltered)';
}

###############################################################################
# TEST: empty image file
image_empty: {
    my $cgi     = fake_upload( image => [$test_empty] );
    my $profile = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (empty image)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    is length($image), 0, '... empty image';
}

###############################################################################
# TEST: Microsoft IE style path (should filter ok)
image_msie_style_path: {
    my $msie_path = 'C:/Program Files/dumb/filename/IE/passes.jpg';
    my $cgi       = fake_upload( image => [$test_image, $msie_path] );
    my $profile   = {
        required        => [qw( image )],
        field_filters   => {
            image   => image_filter(
                max_width   => 50,
                max_height  => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (MSIE style path)';

    my $valid    = $results->valid();       # get the valid data
    my $image_fh = $valid->{image};         # the Fh for the uploaded image
    my $image    = slurp($image_fh);        # slurp in the image data
    my ($img_w, $img_h) = imgsize(\$image); # height/width of image

    is $img_w, 37, '... image width';
    is $img_h, 50, '... image height';
}

###############################################################################
# TEST: text file (should be untouched)
text_file_is_untouched : {
    my $cgi     = fake_upload( text => [$test_textfile] );
    my $profile = {
        required        => [qw( text )],
        field_filters   => {
            text    => image_filter(
                max_width   => 50,
                max_height  => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (text file)';

    my $valid    = $results->valid();       # get the valid data
    my $text_fh  = $valid->{text};          # the Fh for the uploaded text
    my @text     = slurp($text_fh);         # slurp in the text data

    is scalar @text, 1, '... one line of text data';
    like $text[0], qr/^This is a dummy file$/, '... containing our test data';
}

###############################################################################
# TEST: regular form field
regular_form_field: {
    my $name    = 'John Doe';
    my $cgi     = fake_upload( name => $name );
    my $profile = {
        required        => [qw( name )],
        field_filters   => {
            name    => image_filter(
                max_width   => 50,
                max_height  => 50,
            ),
        },
    };

    my $results = Data::FormValidator->check( $cgi, $profile );
    isa_ok $results, 'Data::FormValidator::Results',
        'validated form data (regular form field)';

    my $valid = $results->valid();          # get the valid data
    is $valid->{name}, $name, '... form field untouched';
}
