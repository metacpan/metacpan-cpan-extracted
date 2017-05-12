use strict;
use warnings;
use Test::More tests => 4;
use AnyEvent::Git::Wrapper;
use File::Temp qw( tempdir );

my $git = AnyEvent::Git::Wrapper->new( tempdir CLEANUP => 1 );
isa_ok $git, 'AnyEvent::Git::Wrapper';
isa_ok $git, 'Git::Wrapper';

ok $git->can('status'), 'can status';
ok !$git->can('foobarbaz'), 'can\'t foobarbaz';
