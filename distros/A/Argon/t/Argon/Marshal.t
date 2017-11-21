use Test2::Bundle::Extended;
use Argon::Marshal;
use Argon::Message;
use Argon::Constants ':commands';

my $data = [1, 2, 3];

ok my $encoded = encode($data), 'encode';
is decode($encoded), $data, 'decode';

my $msg = Argon::Message->new(cmd => $ID);
ok my $encoded_msg = encode_msg($msg), 'encode_msg';
is decode_msg($encoded_msg), $msg, 'decode_msg';

done_testing;
