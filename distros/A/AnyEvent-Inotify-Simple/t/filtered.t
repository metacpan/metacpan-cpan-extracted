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

my $notify = $mock->meta->name->new(
    directory      => "$tmp",
    event_receiver => sub { $event = [@_] },
    filter         => sub { my $file = shift; $file =~ /~$|.git/ },
);

ok $notify;

$tmp->touch('foo');
$notify->poll;
ok $event;
is $watched, 1, 'watching root';
undef $event;

$tmp->touch('foo~');
$notify->poll;
ok !$event, 'foo~ is filtered';
is $watched, 1, 'watching root, nothing else';
undef $event;

$tmp->touch('perfectly/cromulent');
$notify->poll;
$notify->poll;
ok $event, 'watching a perfectly cromulent file';
is $watched, 2, 'watching root and perfectly';
undef $event;

$tmp->touch('.git/config');
$tmp->touch('.git/whatever');
$notify->poll;
ok !$event, '.git is not watched';
is $watched, 2, 'not watching .git';
undef $event;

done_testing;
