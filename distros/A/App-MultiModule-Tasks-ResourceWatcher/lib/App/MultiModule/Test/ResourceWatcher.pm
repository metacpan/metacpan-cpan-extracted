package App::MultiModule::Test::ResourceWatcher;
$App::MultiModule::Test::ResourceWatcher::VERSION = '1.161190';
use strict;use warnings;
use Test::More;
use App::MultiModule::Test;

=head2 some pod
=cut
sub _begin {
    App::MultiModule::Test::clear_queue('ResourceWatcher');
    App::MultiModule::Test::clear_queue('test_out');
}
sub _finish {
    App::MultiModule::Test::clear_queue('ResourceWatcher');
    App::MultiModule::Test::clear_queue('test_out');
}

1;
