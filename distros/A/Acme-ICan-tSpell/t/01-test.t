use Test::More;

use Acme::ICan::tSpell;
use Test::MockObject;

(my $tiny = Test::MockObject->new)->mock(
    'get', sub { 
        return { 
            content => '<div class="med"><p class="sp_cnt card-section"><span class="spell">Showing results for</span> <a class="spell" href="/search?q=tanks&amp;spell=1&amp;sa=X&amp;ved=0ahUKEwiswcrA4erSAhUDfRoKHSjgC-kQvwUIGSgA"><b><i>tanks</i></b></a><br><span class="spell_orig">Search instead for</span> <a class="spell_orig" href="/search?q=takns&amp;nfpr=1&amp;sa=X&amp;ved=0ahUKEwiswcrA4erSAhUDfRoKHSjgC-kQvgUIGigB">takns</a><br></p><div class="_cy" id="msg_box" style="display:none"><p class="card-section _fbd"><span><span class="spell" id="srfm"></span>&nbsp;<a class="spell" id="srfl"></a><br></span><span id="sif"><span class="spell_orig" id="sifm"></span>&nbsp;<a class="spell_orig" id="sifl"></a><br></span></p></div></div>', 
            success => 1 
        } 
    }
);

=pod
my $this_thing = Acme::ICan'tSpell->new;

is $this_thing->spell('awsome'), 'awesome';
is $this_thing->spell('takns'), 'tanks';
is $this_thing->spell('thakns'), 'thanks';

is $this_thing->spell('thakn yuo'), 'thank you';
=cut

my $acme = Acme::ICan::tSpell->new(
    tiny => $tiny,
);

is $acme->spell('takns'), 'tanks';

(my $dead = Test::MockObject->new)->mock('get', sub { return  {
	'reason' => 'Not Found',
	 'headers' => {
					 'vary' => 'Accept-Encoding',
					 'server' => 'nginx/1.10.0 (Ubuntu)',
					 'connection' => 'keep-alive',
					 'date' => 'Mon, 13 Mar 2017 15:49:56 GMT',
					 'content-length' => '178',
					 'content-type' => 'text/html'
			   },
	'protocol' => 'HTTP/1.1',
	'status' => '404',
};});

my $dead_client = Acme::ICan'tSpell->new(
    tiny => $dead,
);

eval { $dead_client->spell("takns"); };
my $death = $@;
like($death, qr/^something went terribly wrong/, "caught the carp");

done_testing();

