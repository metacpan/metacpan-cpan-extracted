#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The synopsis from plan_context_vars/00-overview.md, with a hand-written
# deferred queue where it had fetch_user()->then, and wrap done by hand
# through the test doors. Every assertion names both sides.

my @queue;
sub later {
    my ($cb) = @_;
    my $cap = Context::Vars::_t_capture();
    push @queue, sub { Context::Vars::_t_enter_copy($cap, $cb); Context::Vars::_t_release($cap) };
}
sub run_queue { (shift @queue)->() while @queue }

my @log;
{
    package MyApp::Log;
    use Context::Vars qw($request_id);
    sub log_line { push @log, '[' . ($request_id // 'none') . "] $_[0]" }
}
{
    package MyApp::Handler;
    use Context::Vars qw($request_id $span);

    sub handle_request {
        my ($id) = @_;
        $request_id = $id;
        $span       = "span-$id";
        MyApp::Log::log_line('start');
        main::later(sub {
            MyApp::Log::log_line("deferred, span $span");
        });
        return $request_id;
    }
}
use Context::Vars qw($request_id);

$request_id = 'outer';
is(MyApp::Handler::handle_request('A'), 'A', 'inside handle_request the id is A');
is($request_id, 'outer', 'after it returns the caller reads its own earlier value, not A');
is(MyApp::Handler::handle_request('B'), 'B', 'a second request reads B');
is($request_id, 'outer', 'and the caller still reads outer, not B');

run_queue();
is_deeply(\@log, [
    '[A] start',
    '[B] start',
    '[A] deferred, span span-A',
    '[B] deferred, span span-B',
], 'the nested log_line read A then B, and each deferred callback read its own request, not the one that ran last');
is($request_id, 'outer', 'the caller is untouched after the queue ran');
is(Context::Vars::_depth(), 0, 'no scope is left open');
is(Context::Vars::_live_holders(), 0, 'and no holder is out');

done_testing;
