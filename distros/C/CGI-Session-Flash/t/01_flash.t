#!/usr/bin/perl
use Test::More tests => 50;

BEGIN { use_ok('CGI::Session::Flash'); }

# Mock Session Class
{
    package My::Session;
    use base 'CGI::Session';

    sub new
    {
        my $class = shift;
        return bless { @_ }, $class;
    }

    sub DESTROY { }

    sub param
    {
        my $self = shift;
        my $key  = shift;

        $self->{$key} = shift if (@_);

        return $self->{$key};
    }
}

my $session = My::Session->new;
my $flash   = CGI::Session::Flash->new($session);

# Creating a new empty flash
ok(defined $flash, "created new flash");
ok($flash->is_empty, "starts out empty");

# Accessors
is($flash->cleanup_done, 0, "cleanup_done accessor defaults to false");
is($flash->session, $session, "session accessor");
is($flash->session_key, '_flash', "session_key accessor");

# Setting single value
ok($flash->set(test => "value"), "set simple key");
ok($flash->has_key("test"), "  has key");
is($flash->get("test"), "value", "  get simple key");

# Setting multiple values
ok($flash->set(test2 => "value1", "value2"), "set two values");
ok($flash->has_key("test2"), "  has key");
my $test2 = $flash->get("test2");
is(ref $test2, "ARRAY", "  got array ref in scalar context");
is(@$test2, 2, "    has 2 elements");
is($test2->[0], "value1", "    value1");
is($test2->[1], "value2", "    value2");
my @test2 = $flash->get("test2");
is(@test2, 2, "  got array with 2 elements in list context");
is($test2[0], "value1", "   value1");
is($test2[1], "value2", "   value2");

# Check set keys
is_deeply([ $flash->keys ], [ 'test', 'test2' ], "correct keys");

# Check that resetting empties flash
ok(!$flash->is_empty, "flash is not empty");
$flash->{_cleanup_done} = 1;
ok($flash->reset, "reset");
is($flash->cleanup_done, 0, "cleanup_done accessor reset to false");
ok($flash->is_empty, "now it is empty");

# Flush
ok($flash->flush, "flushing empty");
ok(scalar keys %$session == 2, "2 session keys wrote");
is($flash->cleanup_done, 1, "cleanup done flag set");

# Test creation with data.
$session = My::Session->new(
    FLASHY => {
        test => 'value',
        foo  => 'bar',
    },
    FLASHY_keep => [ 'test' ],
);
$flash = CGI::Session::Flash->new($session, session_key => 'FLASHY');

ok($flash, "creation with data");
is($flash->cleanup_done, 0, "cleanup_done false");
is_deeply($flash->session_key, 'FLASHY', "session_key set");
is($flash->get("test"), "value", "  got test value");
is($flash->get("foo"), "bar", "  got foo value");

# Keep
ok($flash->keep('test'), "keep test key");
is_deeply(scalar $flash->keep_keys, [ 'test' ], "  keep list contains key");

# Discard
ok($flash->discard('test'), "discarded test key");
is_deeply(scalar $flash->keep_keys, [ ], "  keep list is empty");

# Test keep and discard with no parameters.
ok($flash->keep, "keep with no args");
is_deeply([ sort $flash->keep_keys ], [ sort $flash->keys ], "  keeping all keys");
ok($flash->discard, "discard with no args");
ok(scalar @{$flash->keep_keys} == 0, "  keep list is empty");

# Cleanup
ok($flash->cleanup(), "cleanup");
ok($flash->is_empty, "  flash is empty");


# More complicated cleanup test
$session = My::Session->new(
    _flash => {
        info     => 'there was a spark',
        warnings => 'now your hair is on fire',
        errors   => 'stop drop and roll!!',
    },
    _flash_keep => [ 'errors', 'warnings' ],
);
$flash = CGI::Session::Flash->new($session);

is($flash->cleanup_done, 0, "cleanup_done is false");
ok($flash->cleanup, "more advanced flash cleanup");
is($flash->cleanup_done, 1, "cleanup_done is true");
ok(!$flash->is_empty, "  not empty");
ok(!$flash->has_key('info'), "  no longer has info key");
ok($flash->cleanup, "flash cleanup again");
is_deeply([ $flash->keys ], [ 'errors', 'warnings' ], "  still has other keys");

ok($flash->cleanup(1), "forced cleanup");
ok($flash->is_empty, "  now it is empty");
