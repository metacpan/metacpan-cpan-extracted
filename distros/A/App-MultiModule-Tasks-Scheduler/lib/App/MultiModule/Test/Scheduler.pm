package App::MultiModule::Test::Scheduler;
$App::MultiModule::Test::Scheduler::VERSION = '1.161950';
use strict;use warnings;
use Test::More;
use App::MultiModule::Test;

=head2 some pod
=cut
sub _begin {
    App::MultiModule::Test::clear_queue('Scheduler');
    App::MultiModule::Test::clear_queue('test_out');
}
sub _finish {
    App::MultiModule::Test::clear_queue('Scheduler');
    App::MultiModule::Test::clear_queue('test_out');
}

1;
