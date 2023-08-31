use strict;
use warnings;
BEGIN { eval q{ use EV } }
use Test::More;
use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Temp qw( tempdir );
use File::Spec;

# don't really have time at the moment to figure out why this
# isn't at least failing on MSWin32 (it spews some permission
# errors and then gets stuck), so skip this test.  There
# are plenty of other tests that will fail on Windows anyway.
plan skip_all => 'print not supported on windows' if $^O eq 'MSWin32';
plan tests => 3;

my $dir = tempdir( CLEANUP => 1 );
my $fh;
open($fh, '>', File::Spec->catfile($dir, 'child.pl'));
print $fh join "\n", "#!$^X",
                     'use File::Spec;',
                     "open(\$out, '>', File::Spec->catfile('$dir', 'child.out'));",
                     'while(<STDIN>) {',
                     '  print $out $_',
                     '}';
close $fh;

my $done = AnyEvent->condvar;

my $ipc = AnyEvent::Open3::Simple->new(
  on_exit => sub {
    $done->send;
  },
  on_start => sub {
    my($proc) = @_;
    eval { $proc->say('message1') };
    diag $@ if $@;
    eval { $proc->say('message2') };
    diag $@ if $@;
    eval { $proc->close };
    diag $@ if $@;
  },
);

my $timeout = AnyEvent->timer(
  after => 5,
  cb    => sub { diag 'timeout!'; exit 2 },
);

my $proc = $ipc->run($^X, File::Spec->catfile($dir, 'child.pl'));
isa_ok $proc, 'AnyEvent::Open3::Simple';

$done->recv;

open($fh, '<', File::Spec->catfile($dir, 'child.out'));
my @list = <$fh>;
close $fh;

chomp $_ for @list;

is $list[0], 'message1', 'list[0] = message1';
is $list[1], 'message2', 'list[1] = message2';
