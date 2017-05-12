use strict;
use Test::More tests => 7;
use Test::Exception;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

use Bot::ChatBots::Whatever;

my $w;
lives_ok { $w = Bot::ChatBots::Whatever->new } 'new lives';
isa_ok $w, 'Bot::ChatBots::Whatever';
can_ok $w, qw< process processor >;

my $processor;
lives_ok { $processor = $w->processor } 'processor method lives';

my $record = {hey => 'you'};
my $out;
lives_ok { $out = $processor->($record) } 'processor sub invocation lives';
is_deeply $out, $record, 'same record passthrough';
is_deeply $out, {hey => 'you', foo => 'bar'}, 'content as expected';

done_testing();
