#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";


# use this block if you don't need middleware, and only have a single target Dancer app to run here
use MyApp2;

MyApp2->to_app;

use Plack::Builder;

builder {
    enable 'Deflater';
    MyApp2->to_app;
}



=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use MyApp2;
use Plack::Builder;

builder {
    enable 'Deflater';
    MyApp2->to_app;
}

=end comment

=cut

=begin comment
# use this block if you want to include middleware such as Plack::Middleware::Deflater

use MyApp2;
use MyApp2_admin;

builder {
    mount '/'      => MyApp2->to_app;
    mount '/admin'      => MyApp2_admin->to_app;
}

=end comment

=cut

