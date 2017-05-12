use strict;
use warnings;

use Dancer ':syntax';
use Dancer::FileUtils 'read_glob_content';
use Dancer::Test;
use Test::More import => [ '!pass' ];

plan tests => 1;

isnt(eval {
    # Good luck finding your precious binary with an empty PATH
    local $ENV{PATH} = '';
    # ...or your beloved module with an empty @INC, sucker!
    local @INC = ();
    require Dancer::Plugin::Preprocess::Less;
}, 1, 'A fatal error is produced when lessc and CSS::LESSp can\'t be found');
