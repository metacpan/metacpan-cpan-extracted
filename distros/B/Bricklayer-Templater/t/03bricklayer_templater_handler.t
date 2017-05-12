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

my @methods = qw{attributes block type tagname tagid app parse_block run_handler };

BEGIN: {
    plan tests =>  1 # test that module compiles
                  +1 # test that can create a handler
                  +2 # test argument validation
                  +1 # test methods exist
                  +6 # test attribute methods
                  +1 # test parse_block() functionality
                  ;    

    use_ok('Bricklayer::Templater::Handler');
    ok($h = Bricklayer::Templater::Handler->load($token, $app), 'Loaded handler object'); 
    dies_ok(sub {Bricklayer::Templater::Handler->load(undef, $app)}, 'failed Loading handler object without Token'); 
    dies_ok(sub {Bricklayer::Templater::Handler->load($token, undef)}, 'failed Loading handler object without context object'); 
}

{
    can_ok($h, @methods);
    isa_ok($h->app(), 'Test::MockObject');
    ok($h->attributes()->{foo} eq 'bar', 'Attributes are accessed correctly');
    ok($h->block() eq $token->{block}, 'Block is accessed correctly');
    ok($h->tagid eq $app->identifier(), 'tagid ['.$app->identifier().'] is accessed correctly');
    ok($h->type eq $token->{type}, 'type ['.$token->{type}.'] is accessed correctly');
    ok($h->tagname eq $token->{tagname}, 'tagname ['.$token->{tagname}.'] is accessed correctly');
}

{
   dies_ok(sub {$h->parse_block();}, 'sequencer was called'); 
}
