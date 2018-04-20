#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use App::Notifier::Service;

App::Notifier::Service->to_app;

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use App::Notifier::Service;
use Plack::Builder;

builder {
    enable 'Deflater';
    App::Notifier::Service->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to mount several applications on different path

use App::Notifier::Service;
use App::Notifier::Service_admin;

use Plack::Builder;

builder {
    mount '/'      => App::Notifier::Service->to_app;
    mount '/admin'      => App::Notifier::Service_admin->to_app;
}

=end comment

=cut

