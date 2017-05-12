use utf8;
use Test::Base;

plan 'no_plan';

use Path::Class qw/file/;
use AnyEvent::APNS;


my $cer = "$ENV{HOME}/dev/apns/test.cer";
my $key = "$ENV{HOME}/dev/apns/test.key";

my $token = file("$ENV{HOME}/dev/apns/token.bin")->slurp;
{
    my $cv = AnyEvent->condvar;

    my $apns; $apns = AnyEvent::APNS->new(
        certificate => $cer,
        private_key => $key,
        sandbox     => 1,
        on_connect  => sub {
            $apns->send($token => { aps => { alert => "テスト！" }});
            $apns->handler->on_drain(sub { undef $_[0]; $cv->send });
        },
    )->connect;

    $cv->recv;

    ok(1, "app runs ok, check your phone");
}


{
     my $cer_content = file($cer)->slurp;
     my $key_content = file($key)->slurp;

     my $cv = AnyEvent->condvar;

     my $apns; $apns = AnyEvent::APNS->new(
         certificate     => \$cer_content,
         private_key     => \$key_content,
         sandbox         => 1,
         on_connect      => sub {
             $apns->send($token => { aps => { alert => "もう一回テスト！" }});
             $apns->handler->on_drain(sub { undef $_[0]; $cv->send });
         },
     )->connect;

     $cv->recv;

     ok(1, "app runs ok, check your phone again");
}
