use strict;
use warnings;
no warnings 'deprecated';
BEGIN { eval q{ use EV } }
use Test::More tests => 3;
use AnyEvent;
use AnyEvent::Open3::Simple;
use File::Temp qw( tempdir );
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );
my $fh;
open($fh, '>', File::Spec->catfile($dir, 'child.pl'));
print $fh "#!$^X\n";
print $fh 'use File::Spec;', "\n";
print $fh "open(\$out, '>', File::Spec->catfile('$dir', 'child.out'));", "\n";
print $fh 'while(<STDIN>) {', "\n";
print $fh '  print $out $_', "\n";
print $fh '}', "\n";
close $fh;

foreach my $stdin ([ qw( message1 message2 ) ], join("\n", qw( message1 message2 )))
{
  subtest 'run ' . ((ref $stdin) ? 'list ref' : 'string') => sub {
    plan tests => 4;

    my $done = AnyEvent->condvar;

    my $ipc = AnyEvent::Open3::Simple->new(
      on_exit => sub {
        $done->send(1);
      },
    );

    my $timeout = AnyEvent->timer(
      after => 5,
      cb    => sub { diag 'timeout!'; $done->send(0) },
    );

    my $proc = $ipc->run($^X, File::Spec->catfile($dir, 'child.pl'), ref $stdin ? $stdin : \$stdin);
      isa_ok $proc, 'AnyEvent::Open3::Simple';

      is $done->recv, 1, 'no timeout';

      open($fh, '<', File::Spec->catfile($dir, 'child.out'));
      my @list = <$fh>;
      close $fh;

      chomp $_ for @list;

      is $list[0], 'message1', 'list[0] = message1';
      is $list[1], 'message2', 'list[1] = message2';

  };

}

subtest constructor => sub {
  plan tests => 2;

  my $in='';
  eval { AnyEvent::Open3::Simple->new( stdin => \$in ) };
  isnt $@, '', 'throws exception';
  like $@, qr{stdin passed into AnyEvent::Open3::Simple\-\>new no longer supported}, 'has message';
  note "error=$@";
};
