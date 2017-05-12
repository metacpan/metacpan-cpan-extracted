#!/usr/bin/perl
# Run ../app/app.psgi as CGI script

use Plack::Loader;
use File::Basename qw(dirname);
use File::Spec::Functions;
use lib catdir(dirname($0), '..', 'app', 'app.psgi');

my $app = Plack::Util::load_psgi($psgi);
Plack::Loader->auto->run($app);
