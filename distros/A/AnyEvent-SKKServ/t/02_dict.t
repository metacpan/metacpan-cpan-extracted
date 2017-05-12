use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'Test::TCP';
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Encode;

use AnyEvent::SKKServ;

sub on_request {
    my ($hdl, $req) = @_;
    my %dict = (
        'はつねみく'   => "1/初音ミク/初音未来/ハツネミク/はつねミク/はつねみく/\n",
        'かがみねりん' => "1/鏡音リン/鏡音鈴/かがみねりん/カガミネリン/ｶｶﾞﾐﾈﾘﾝ/\n",
        'かがみねれん' => "1/鏡音レン/かがみねれん/カガミネレン/ｶｶﾞﾐﾈﾚﾝ/\n",
    );

    $req = decode_utf8($req);
    if (exists $dict{$req}) {
        $hdl->push_write(encode_utf8($dict{$req}));
    } else {
        $hdl->push_write("4\n");
    }
}

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;

        my $skkserv = AnyEvent::SKKServ->new(
            port => $port,
            on_request => \&on_request,
        );
        $skkserv->run;

        AE::cv()->recv;
    },
);

my $cv = AE::cv();

tcp_connect '127.0.0.1', $server->port, sub {
    my ($fh) = @_ or die $!;
    my $hdl; $hdl = AnyEvent::Handle->new(
        fh => $fh,
    );

    $hdl->push_write(encode_utf8('1はつねみく '));
    $hdl->push_read(regex => qr/\n/, sub {
        is decode_utf8($_[1]), "1/初音ミク/初音未来/ハツネミク/はつねミク/はつねみく/\n";
    });

    $hdl->push_write(encode_utf8('1かがみねりん '));
    $hdl->push_read(regex => qr/\n/, sub {
        is decode_utf8($_[1]), "1/鏡音リン/鏡音鈴/かがみねりん/カガミネリン/ｶｶﾞﾐﾈﾘﾝ/\n";
    });

    $hdl->push_write(encode_utf8('1かがみねれん '));
    $hdl->push_read(regex => qr/\n/, sub {
        is decode_utf8($_[1]), "1/鏡音レン/かがみねれん/カガミネレン/ｶｶﾞﾐﾈﾚﾝ/\n";
    });

    $hdl->push_write(encode_utf8('1めぐりねるか '));
    $hdl->push_read(regex => qr/\n/, sub {
        is decode_utf8($_[1]), "4\n";

        undef $hdl;
        $cv->send;
    });
};

$cv->recv;

done_testing;
