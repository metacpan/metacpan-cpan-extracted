use strict;
use warnings;
use Test::More tests => 1;

use Data::Compare;
$SIG{ALRM} = sub { fail("timeout"); exit };
alarm(5);

TODO: {
    local $TODO = "broken";
    ok(0);
    # ok(Data::Compare::Compare(_get_data()), "yay, didn't timeout");
}

sub _get_data {
my $VAR1 = {
'bodies' => bless( {
'774e1dee53a6c80d99cca81f188abf91' => bless( {
'body' => 'Get Lost!
For the 2th time',
'headers' => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Billy 2',
'messages' => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => bless( {
'From' => 'Jonny 1',
'messages' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => bless( {
'body' => bless( {
'body' => 'Let me count the ways.... 3',
'headers' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Sally 3',
'messages' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '0a763e41c9c22e1a97fcef68e37d2564'
}, 'Quarantine::Header' ),
'340954c191bbbadfbd7ab37e62ac91c0' => {},
'655c7a5d8f36c58632a92e9c318fa9b4' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Fred 2',
'messages' => bless( {
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '655c7a5d8f36c58632a92e9c318fa9b4'
}, 'Quarantine::Header' ),
'7020baa09e5801d94724257ee8fba3bc' => bless( {
'body' => bless( {
'body' => 'Get Lost!
For the 3th time',
'headers' => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {},
'ddd55caf8ac04ed3e75224cd12847bac' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Billy 3',
'messages' => bless( {
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => 'ddd55caf8ac04ed3e75224cd12847bac'
}, 'Quarantine::Header' )
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Fred 3',
'messages' => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '7020baa09e5801d94724257ee8fba3bc'
}, 'Quarantine::Header' ),
'bbed5198630e5d982f474ddb946b5cb6' => bless( {
'body' => bless( {
'body' => 'Let me count the ways.... 2',
'headers' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Sally 2',
'messages' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => 'bbed5198630e5d982f474ddb946b5cb6'
}, 'Quarantine::Header' ),
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::SMessages' )
}, 'Quarantine::Sender' ),
'uniq' => '340954c191bbbadfbd7ab37e62ac91c0'
}, 'Quarantine::Header' ),
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'81a987f71ec224975ad33bcd09e9ebe4' => {},
'e3973a2585798a8e85f3a9a6a6ece156' => {},
'f5794e56fc5ecd3a92a3586da3b6392a' => {}
}, 'Quarantine::Bodies' ),
'buckets' => bless( {
0 => bless( {
'a' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
3 => bless( {
4 => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
6 => bless( {
5 => bless( {
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
7 => bless( {
0 => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
'b' => bless( {
'b' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
'd' => bless( {
'd' => bless( {
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' )
}, 'Quarantine::Buckets' ),
'headers' => bless( {}, 'Quarantine::Headers' ),
'recipients' => bless( {
'Billy 2' => {},
'Billy 3' => {},
'Fred 2' => {},
'Fred 3' => {},
'Sally 2' => {},
'Sally 3' => {}
}, 'Quarantine::Recipients' ),
'senders' => bless( {
'Jonny 1' => {}
}, 'Quarantine::Senders' )
};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'body'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'recipients'}[0]{'messages'}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'body'}{'headers'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'recipients'}[0]{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'sender'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'body'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'recipients'}[0]{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'sender'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'body'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'recipients'}[0]{'messages'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'sender'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'recipients'}[0]{'messages'}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'sender'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'body'}{'headers'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'recipients'}[0]{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'sender'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR1->{'bodies'}{'81a987f71ec224975ad33bcd09e9ebe4'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'};
$VAR1->{'bodies'}{'e3973a2585798a8e85f3a9a6a6ece156'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'body'};
$VAR1->{'bodies'}{'f5794e56fc5ecd3a92a3586da3b6392a'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'body'};
$VAR1->{'buckets'}{0}{'a'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR1->{'buckets'}{3}{4}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR1->{'buckets'}{6}{5}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR1->{'buckets'}{7}{0}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR1->{'buckets'}{'b'}{'b'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR1->{'buckets'}{'d'}{'d'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR1->{'recipients'}{'Billy 2'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'recipients'}[0];
$VAR1->{'recipients'}{'Billy 3'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'recipients'}[0];
$VAR1->{'recipients'}{'Fred 2'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'recipients'}[0];
$VAR1->{'recipients'}{'Fred 3'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'recipients'}[0];
$VAR1->{'recipients'}{'Sally 2'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'recipients'}[0];
$VAR1->{'recipients'}{'Sally 3'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'recipients'}[0];
$VAR1->{'senders'}{'Jonny 1'} = $VAR1->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};


my $VAR2 = {
'bodies' => bless( {
'774e1dee53a6c80d99cca81f188abf91' => bless( {
'body' => 'Get Lost!
For the 2th time',
'headers' => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Billy 2',
'messages' => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => bless( {
'From' => 'Jonny 1',
'messages' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => bless( {
'body' => bless( {
'body' => 'Let me count the ways.... 3',
'headers' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Sally 3',
'messages' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '0a763e41c9c22e1a97fcef68e37d2564'
}, 'Quarantine::Header' ),
'340954c191bbbadfbd7ab37e62ac91c0' => {},
'655c7a5d8f36c58632a92e9c318fa9b4' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Fred 2',
'messages' => bless( {
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '655c7a5d8f36c58632a92e9c318fa9b4'
}, 'Quarantine::Header' ),
'7020baa09e5801d94724257ee8fba3bc' => bless( {
'body' => bless( {
'body' => 'Get Lost!
For the 3th time',
'headers' => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {},
'ddd55caf8ac04ed3e75224cd12847bac' => bless( {
'body' => {},
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Billy 3',
'messages' => bless( {
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => 'ddd55caf8ac04ed3e75224cd12847bac'
}, 'Quarantine::Header' )
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Fred 3',
'messages' => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => '7020baa09e5801d94724257ee8fba3bc'
}, 'Quarantine::Header' ),
'bbed5198630e5d982f474ddb946b5cb6' => bless( {
'body' => bless( {
'body' => 'Let me count the ways.... 2',
'headers' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'header' => 'Re: Stuff',
'recipients' => bless( [
bless( {
'To' => 'Sally 2',
'messages' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::RMessages' )
}, 'Quarantine::Recipient' )
], 'Quarantine::RList' ),
'sender' => {},
'uniq' => 'bbed5198630e5d982f474ddb946b5cb6'
}, 'Quarantine::Header' ),
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::SMessages' )
}, 'Quarantine::Sender' ),
'uniq' => '340954c191bbbadfbd7ab37e62ac91c0'
}, 'Quarantine::Header' ),
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::BHeaders' )
}, 'Quarantine::Body' ),
'81a987f71ec224975ad33bcd09e9ebe4' => {},
'e3973a2585798a8e85f3a9a6a6ece156' => {},
'f5794e56fc5ecd3a92a3586da3b6392a' => {}
}, 'Quarantine::Bodies' ),
'buckets' => bless( {
0 => bless( {
'a' => bless( {
'0a763e41c9c22e1a97fcef68e37d2564' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
3 => bless( {
4 => bless( {
'340954c191bbbadfbd7ab37e62ac91c0' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
6 => bless( {
5 => bless( {
'655c7a5d8f36c58632a92e9c318fa9b4' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
7 => bless( {
0 => bless( {
'7020baa09e5801d94724257ee8fba3bc' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
'b' => bless( {
'b' => bless( {
'bbed5198630e5d982f474ddb946b5cb6' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' ),
'd' => bless( {
'd' => bless( {
'ddd55caf8ac04ed3e75224cd12847bac' => {}
}, 'Quarantine::Bucket2' )
}, 'Quarantine::Bucket1' )
}, 'Quarantine::Buckets' ),
'headers' => bless( {}, 'Quarantine::Headers' ),
'recipients' => bless( {
'Billy 2' => {},
'Billy 3' => {},
'Fred 2' => {},
'Fred 3' => {},
'Sally 2' => {},
'Sally 3' => {}
}, 'Quarantine::Recipients' ),
'senders' => bless( {
'Jonny 1' => {}
}, 'Quarantine::Senders' )
};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'body'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'recipients'}[0]{'messages'}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'body'}{'headers'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'recipients'}[0]{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'sender'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'body'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'recipients'}[0]{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'sender'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'body'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'recipients'}[0]{'messages'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'sender'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'recipients'}[0]{'messages'}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'sender'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'body'}{'headers'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'recipients'}[0]{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'sender'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR2->{'bodies'}{'81a987f71ec224975ad33bcd09e9ebe4'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'};
$VAR2->{'bodies'}{'e3973a2585798a8e85f3a9a6a6ece156'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'body'};
$VAR2->{'bodies'}{'f5794e56fc5ecd3a92a3586da3b6392a'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'body'};
$VAR2->{'buckets'}{0}{'a'}{'0a763e41c9c22e1a97fcef68e37d2564'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'};
$VAR2->{'buckets'}{3}{4}{'340954c191bbbadfbd7ab37e62ac91c0'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'};
$VAR2->{'buckets'}{6}{5}{'655c7a5d8f36c58632a92e9c318fa9b4'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'};
$VAR2->{'buckets'}{7}{0}{'7020baa09e5801d94724257ee8fba3bc'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'};
$VAR2->{'buckets'}{'b'}{'b'}{'bbed5198630e5d982f474ddb946b5cb6'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'};
$VAR2->{'buckets'}{'d'}{'d'}{'ddd55caf8ac04ed3e75224cd12847bac'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'};
$VAR2->{'recipients'}{'Billy 2'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'recipients'}[0];
$VAR2->{'recipients'}{'Billy 3'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'body'}{'headers'}{'ddd55caf8ac04ed3e75224cd12847bac'}{'recipients'}[0];
$VAR2->{'recipients'}{'Fred 2'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'655c7a5d8f36c58632a92e9c318fa9b4'}{'recipients'}[0];
$VAR2->{'recipients'}{'Fred 3'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'7020baa09e5801d94724257ee8fba3bc'}{'recipients'}[0];
$VAR2->{'recipients'}{'Sally 2'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'bbed5198630e5d982f474ddb946b5cb6'}{'recipients'}[0];
$VAR2->{'recipients'}{'Sally 3'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'}{'messages'}{'0a763e41c9c22e1a97fcef68e37d2564'}{'recipients'}[0];
$VAR2->{'senders'}{'Jonny 1'} = $VAR2->{'bodies'}{'774e1dee53a6c80d99cca81f188abf91'}{'headers'}{'340954c191bbbadfbd7ab37e62ac91c0'}{'sender'};

return ($VAR1, $VAR2);
}

