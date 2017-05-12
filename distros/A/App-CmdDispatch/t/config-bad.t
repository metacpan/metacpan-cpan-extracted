#!/usr/bin/env perl

use Test::More tests => 1;
use Test::Exception;

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp;
use App::CmdDispatch;

throws_ok
{
    App::CmdDispatch->new(
        {
            noop => {
                code => sub { }
            }
        },
        { config => 'xyzzy' }
    );
}
qr/Supplied config is not a file./, 'Exception if supplied bad file name';
