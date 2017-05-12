# 10-bl.t - Test the basic functionality of the DNS::BL class. This
# includes tokenisation, accessors, return values reported, dynamic
# language extension.

# $Id: 10-bl.t,v 1.2 2004/10/11 14:23:31 lem Exp $

use Test::More;
use NetAddr::IP;

my $thing = 'are belong to us';
my @stuff = ('', 'a', undef, 'All your base', \$thing);
my @g_parse = (
	       q{verb 1 2 3},
	       q{verb 1 2 3},
	       q{verb 1 2 3},
	       q{verb 1 2 3},
	       q{verb 0 2 3},
	       q{verb 1 0 3},
	       q{verb 1 2 0},
	       q{verb "this is a quoted string" or not},
	       q{verb "this is a quoted string #with no comment" or not},
	       q{verb 1 2 "quoted at the end"},
	       q{verb "first arg" "second arg" "third arg"},
	       q{verb "first arg#nc" "second arg#nc" "third arg#nc"},
	       q{verb "first arg #nc" "second arg #nc" "third arg #nc"},
	       q{verb "first arg # nc" "second arg # nc" "third arg # nc"},
	       q{verb "" "" ""},
	       q{verb "#" "#" "#"},
	       q{verb "# " "# " "# "},
	       q{verb " #" " #" " #"},
	       q{verb "1st arg" "" ""},
	       q{verb "" "2nd arg" ""},
	       q{verb "" "" "3rd arg"},

	       # It is technically correct to quote the verb or any other
	       # argument... This is shell-ish

	       q{"verb" 1 2 3},
	       q{"verb" "this is a quoted string" or not},
	       q{"verb" 1 2 "quoted at the end"},
	       q{"verb" "first arg" "second arg" "third arg"},
	       q{"verb" "" "" ""},
	       q{"verb" "1st arg" "" ""},
	       q{"verb" "" "2nd arg" ""},
	       q{"verb" "" "" "3rd arg"},
	       );
my @b_parse = (
	       q{verb "this is bad}, #"},
	       q{verb a "bad thing}, #"},
	       q{verb a "bad}, #"},
	       q{"verb}, #"},
	       );

my @e_parse = (
	       q{},
	       q{ },
	       q{  },
	       );

my $tests = 9 + @stuff + 120 * @g_parse + 60 * @b_parse + 60 * @e_parse;

plan tests => $tests + 1;

SKIP:
{
    skip "Failed to use DBS::BL", $tests
	unless use_ok('DNS::BL');

    # Type related tests...
    my $bl;
    isa_ok($bl = new DNS::BL, "DNS::BL", 'new DNS::BL');
    isa_ok($bl = DNS::BL->new, "DNS::BL", 'DNS::BL->new');

    # get/set accessors
    for (@stuff)
    {
	$bl->set('1stKey', $_);
	is($bl->get('1stKey'), $_, 
	   "get <" . (defined $_ ? $_ : 'undef') . ">");
    }

    is($bl->set('2ndKey', 'AYB'), undef, "Correct return on 1st insert");
    is($bl->set('2ndKey', 'ABTU'), 'AYB', "Correct return on 2nd insert");
    is($bl->set('2ndKey', 'SSUTB'), 'ABTU', "Correct return afterwards");

    # Basic verb registration
    my @r;

    *DNS::BL::cmds::verb::execute = sub {
	my $self = shift;
	isa_ok($self, 'DNS::BL', 
	       "Correct type of the object in handler");
	is(@_, 4, "Correct number of tokens parsed");
	is($_[0], 'verb', "Correct first parameter");
	return (&DNS::BL::DNSBL_OK(), "Ok from my handler");
    };

    # Now test the "good" examples
    for my $p (@g_parse)
    {
	for my $S ("$p", "$p ", " $p", " $p ")
	{
	    for my $s ("$S", "$S#", "$S# ", 
		       "$S#comment", "$S# comment")
	    {
		@r = $bl->parse($s); 
		is(@r, 2, "Correct number of return values from handler");
		is($r[0], &DNS::BL::DNSBL_OK(), "OK return code from handler");
		is($r[1], "Ok from my handler",
		   "Correct message from handler");
	    }
	}
    }

    do {
	no warnings;
	*{DNS::BL::cmds::verb::execute} = 
	    sub {fail("Handler called on bad input")};
    };

    # Now test with the bad inputs
    for my $p (@b_parse)
    {
	for my $S ("$p", "$p ", " $p", " $p ")
	{
	    for my $s ("$S", "$S#", "$S# ", 
		       "$S#comment", "$S# comment")
	    {
		@r = $bl->parse($s);		# Original test case
		is(@r, 2, "Correct number of return values to (bad) register");
		is($r[0], &DNS::BL::DNSBL_ESYNTAX(), 
		   "ESYNTAX return on bad input");
		is($r[1], 'End of command within a quoted string', 
		   "Correct message on bad input");
	    }
	}
    }

    # Test variations of the proverbial empty line... A trivial case
    for my $p (@e_parse)
    {
	for my $S ("$p", "$p ", " $p", " $p ")
	{
	    for my $s ("$S", "$S#", "$S# ", 
		       "$S#comment", "$S# comment")
	    {
		@r = $bl->parse($s); 
		is(@r, 2, "Correct number of return values from handler");
		is($r[0], &DNS::BL::DNSBL_OK(), "OK return code from parse()");
		is($r[1], "-- An empty line, huh?", 
		   "Catchy message from parse()");
	    }
	}
    }

    # Test our ability (or lack of) to load a module when an unseen
    # verb is invoked
    @r = $bl->parse('nosuchverb really exists');
    is(@r, 2, "Correct number of return values from parse (bad verb)");
    is($r[0], &DNS::BL::DNSBL_ESYNTAX(), "Syntax error was flagged");
    unless (ok($r[1] =~ /^Verb nosuchverb undefined:/, 
	       "Proper error message")
	    and ok($r[1] =~ m!DNS/BL/cmds/nosuchverb\.pm !, 
		   "Attempted to load proper module"))
    {
	diag "The returned error was\n$r[1]\n";
    }
};

__END__

$Log: 10-bl.t,v $
Revision 1.2  2004/10/11 14:23:31  lem
Handle "0" at end of line correctly

Revision 1.1.1.1  2004/10/08 15:08:32  lem
Initial import

