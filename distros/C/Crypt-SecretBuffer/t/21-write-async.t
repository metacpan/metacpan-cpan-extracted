use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

subtest 'write_async to pipe' => sub {
    my ($r,$w) = pipe_with_data();
    my $buf = Crypt::SecretBuffer->new('async test');
    my $res = $buf->write_async($w);
    my $len = length('async test');
    if (ref $res) {
        my ($wrote,$err) = $res->wait(5);
        is($wrote,$len,'async wrote all');
        is($err,0,'no error');
    } else {
        is($res,$len,'write completed immediately');
    }
    close $w; local $/; my $got=<$r>; is($got,'async test','pipe got data'); close $r;
};

subtest 'write_async with PTY' => sub {
    skip_all('IO::Pty required') unless eval { require IO::Pty; IO::Pty->new(); 1 };
    setup_tty_helper(sub{
        my ($send,$recv,$tty)=@_;
        my $buf = Crypt::SecretBuffer->new('pty secret');
        my $res = $buf->write_async($tty);
        $send->(sleep => .1);
        $send->('read_pty');
        my ($act,$data) = $recv->();
        is([$act,$data],[read=>'pty secret'],'data received');
        if (ref $res) { my ($w,$e)=$res->wait(5); is $w,length('pty secret'),'all written'; is $e,0,'no err'; }
    });
};

done_testing;

