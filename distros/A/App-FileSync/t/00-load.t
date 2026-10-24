use strict;
use warnings;
use Test::Most;

use_ok('App::FileSync');
use_ok('App::FileSync::Admin');
use_ok('App::FileSync::Client');
use_ok('App::FileSync::CLI');
use_ok('App::FileSync::Config');
use_ok('App::FileSync::Delta');
use_ok('App::FileSync::Ignore');
use_ok('App::FileSync::Lock');
use_ok('App::FileSync::Merge');
use_ok('App::FileSync::Protocol');
use_ok('App::FileSync::Scan');
use_ok('App::FileSync::Server');
use_ok('App::FileSync::Settings');
use_ok('App::FileSync::Snapshot');
use_ok('App::FileSync::Store');
use_ok('App::FileSync::Transport::Local');
use_ok('App::FileSync::Transport::SSH');
use_ok('App::FileSync::Trash');
use_ok('App::FileSync::Verify');

done_testing();
