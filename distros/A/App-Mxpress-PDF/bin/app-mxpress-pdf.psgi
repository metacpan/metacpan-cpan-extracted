#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use App::Mxpress::PDF;

App::Mxpress::PDF->to_app;

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use App::Mxpress::PDF;
use Plack::Builder;

builder {
    enable 'Deflater';
    App::Mxpress::PDF->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to mount several applications on different path

use App::Mxpress::PDF;
use App::Mxpress::PDF_admin;

use Plack::Builder;

builder {
    mount '/'      => App::Mxpress::PDF->to_app;
    mount '/admin'      => App::Mxpress::PDF_admin->to_app;
}

=end comment

=cut

