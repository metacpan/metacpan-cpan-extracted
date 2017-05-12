package App::MultiModule::Test::DocGateway;
$App::MultiModule::Test::DocGateway::VERSION = '1.161330';
use strict;use warnings;
use Test::More;
use App::MultiModule::Test;

=head2 some pod
=cut
sub _begin {
    App::MultiModule::Test::clear_queue('DocGateway');
    App::MultiModule::Test::clear_queue('test_out');
}
sub _finish {
    App::MultiModule::Test::clear_queue('DocGateway');
    App::MultiModule::Test::clear_queue('test_out');
}

1;
