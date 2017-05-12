use Test::More tests => 6;
use Test::Exception;
use strict;
use warnings;

use AnyEvent::Filesys::Notify;

use Test::Without::Module qw(Linux::Inotify2 Mac::FSEvents IO::KQueue);

my $w = AnyEvent::Filesys::Notify->new(
    dirs        => ['t'],
    cb          => sub { },
    no_external => 1
);
isa_ok( $w, 'AnyEvent::Filesys::Notify' );
ok( $w->does('AnyEvent::Filesys::Notify::Role::Fallback'),  '... Fallback' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::Inotify2'), '... Inotify2' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::FSEvents'), '... FSEvents' );
ok( !$w->does('AnyEvent::Filesys::Notify::Role::KQueue'),   '... KQueue' );

SKIP: {
    skip 'Test for Mac/Linux/BSD only', 1
      unless $^O eq 'linux'
      or $^O eq 'darwin'
      or $^O =~ /bsd/;

    throws_ok {
        AnyEvent::Filesys::Notify->new( dirs => ['t'], cb => sub { } );
    }
    qr/You may want to install/, 'fails ok';
}

done_testing;
