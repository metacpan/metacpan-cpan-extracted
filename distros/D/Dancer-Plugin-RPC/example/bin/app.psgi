#! perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use Dancer;
use Plack::Builder;

use Example;

builder {
    sub {
        my $env     = shift;
        my $request = Dancer::Request->new(env => $env);
        Dancer->dance($request);
    }
};
