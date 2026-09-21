use v5.24;
use Test2::V0;
use FindBin '$Bin';
use experimental 'signatures';
use lib "$Bin/../lib";
use AWS::Signature::V4::Error qw< fail >;

my $secret = 'S3CR3T-value';

sub thrown (@args) { my $e = dies { fail(@args) }; $e }

subtest 'code and message' => sub {
   my $e = thrown(400, 'bad input');
   isa_ok $e, ['Ouch'], 'an Ouch exception';
   is $e->code, 400, 'code';
   is $e->message, 'bad input', 'message';
   is $e->data, undef, 'no data by default';
   is thrown(500, 'internal')->code, 500, 'other code';
};

subtest 'the third argument is passed down' => sub {
   my $e = thrown(400, 'bad option', {option => 'foo', got => $secret});
   is $e->code, 400, 'code';
   is $e->message, 'bad option', 'message';
   is $e->data, {option => 'foo', got => $secret}, 'data is available';
   is $e->hashref->{data}, {option => 'foo', got => $secret}, 'and it is in hashref too';
   unlike "$e", qr{\Q$secret\E|foo}, 'data is not in the stringified error';
   unlike $e->message, qr{\Q$secret\E}, 'nor in the message';

   my $d = [1, 2, 3];
   is thrown(400, 'array', $d)->data, [1, 2, 3], 'not only hashes';
   is thrown(400, 'scalar', 'plain')->data, 'plain', 'nor references';
};

subtest 'data and arguments stay out of the trace' => sub {
   my $e = do {
      package Some::Caller;
      sub run ($password) { main::thrown(400, 'oops', {got => $secret}) }
      run('Hunter2');
   };
   is $e->data, {got => $secret}, 'data kept';
   unlike $e->trace, qr{\Q$secret\E|Hunter2|HASH\(}, 'no arguments in the trace';
};

subtest 'reported where the caller is' => sub {
   my $line = __LINE__ + 1;
   my $e = dies { fail 400, 'here', {some => 'data'} };
   like "$e", qr{ at \S*error\.t line $line\b}, 'file and line of the caller';
};

done_testing;
