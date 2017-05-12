package App::MultiModule::Test::Runner;
$App::MultiModule::Test::Runner::VERSION = '1.162230';
use strict;use warnings;
use Test::More;
use App::MultiModule::Test;

=head2 some pod
=cut
sub _begin {
    App::MultiModule::Test::clear_queue('Runner');
    App::MultiModule::Test::clear_queue('test_out');
}
sub _finish {
    App::MultiModule::Test::clear_queue('Runner');
    App::MultiModule::Test::clear_queue('test_out');
}

1;
