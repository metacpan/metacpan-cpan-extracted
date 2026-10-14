#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# wrap composes with a real future. Future does not capture contexts itself;
# each callback is wrapped by hand, as a loop author would.

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future is not installed' }
use Context::Vars qw($id);

my %pending;
my @read;
sub fetch { my ($name) = @_; $pending{$name} = Future->new }
sub handle {
    my ($name) = @_;
    $id = $name;
    return fetch($name)
        ->then(Context::Vars->wrap(sub { push @read, "then reads $id with @_"; Future->done("$id done") }))
        ->on_done(Context::Vars->wrap(sub { push @read, "on_done reads $id with @_" }));
}

my @f = (handle('A'), handle('B'));
$id = 'top';
$pending{B}->done('b-result');
$pending{A}->done('a-result');

is_deeply(\@read, [
    'then reads B with b-result', 'on_done reads B with B done',
    'then reads A with a-result', 'on_done reads A with A done',
], 'each callback of each future read its own request, resolved in the opposite order');
is($id, 'top', 'and the code that resolved them reads its own');
is_deeply([map { $_->get } @f], ['A done', 'B done'], 'both futures carry their results');
@f = ();
is(Context::Vars::_live_holders(), 0, 'nothing is held once the futures are gone');

done_testing;
