use Test::More;
use Test::Exception;
use Test::MockObject;

use strict;

my $h;
my $token = {attributes => { foo => 'bar'},
             block      => 'block text',
             type       => 'someType',
             tagname     => 'someTag',
};

my $app = Test::MockObject->new({});
$app->fake_module('Some::App');
$app->mock('identifier' => sub { "BK" });
$app->mock('run_sequencer' => sub { die 'ran sequencer'; });

my @methods = qw{attributes block type tagname data tagid app parse_block run_handler };

BEGIN: {
    plan tests =>  1 # test that module compiles
                  ;    

    use_ok('Bricklayer::Templater::Handler');
}

