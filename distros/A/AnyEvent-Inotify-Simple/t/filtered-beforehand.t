use strict;
use warnings;
use Test::More;

use AnyEvent::Inotify::Simple;
use Directory::Scratch;

use MooseX::Declare;

my $event;
my $tmp = Directory::Scratch->new;

my $watched = 0;
my $mock = class AIS extends AnyEvent::Inotify::Simple {
    before watch { $watched++ }
};

$tmp->touch('foo');
$tmp->touch('foo~');
$tmp->touch('perfectly/cromulent');
$tmp->touch('.git/config');
$tmp->touch('.git/whatever');

my $notify = $mock->meta->name->new(
    directory      => "$tmp",
    event_receiver => sub { $event = [@_] },
    filter         => sub { $_[0] =~ /[.]git|~$/ },
);

ok $notify;
$notify->poll;

is $watched, 2, 'only watching root and perfectly; not .git';

done_testing;
