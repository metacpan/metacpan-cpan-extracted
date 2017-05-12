package App::MultiModule::Test::Collector;
$App::MultiModule::Test::Collector::VERSION = '1.143110';
use strict;use warnings;
use Test::More;
use App::MultiModule::Test;

=head2 some pod
=cut
sub _begin {
    App::MultiModule::Test::clear_queue('Collector');
    App::MultiModule::Test::clear_queue('test_out');
}
sub _finish {
    App::MultiModule::Test::clear_queue('Collector');
    App::MultiModule::Test::clear_queue('test_out');
}

1;
