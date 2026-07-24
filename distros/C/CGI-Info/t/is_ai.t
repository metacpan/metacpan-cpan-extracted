#!perl -w

use strict;
use warnings;
use Test::Most tests => 56;

BEGIN { use_ok('CGI::Info') }

# A stable loopback-ish IP used as REMOTE_ADDR throughout
my $REMOTE = '1.2.3.4';

AI: {
	# ---------------------------------------------------------------
	# Baseline: no CGI environment at all => not an AI crawler
	# ---------------------------------------------------------------
	delete $ENV{REMOTE_ADDR};
	delete $ENV{HTTP_USER_AGENT};
	delete $ENV{IS_AI};

	my $i = new_ok('CGI::Info');
	ok($i->is_ai() == 0, 'no env => is_ai returns 0');

	# Only REMOTE_ADDR present (no UA) => still 0
	$ENV{REMOTE_ADDR} = $REMOTE;
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 0, 'REMOTE_ADDR only, no UA => is_ai returns 0');

	# ---------------------------------------------------------------
	# ClaudeBot (Anthropic) -- present in the known-bots regex too
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0 (+http://www.anthropic.com)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'ClaudeBot => is_ai true');
	ok($i->is_robot() == 1,               'ClaudeBot => is_robot true (invariant)');
	ok($i->browser_type() eq 'ai',        'ClaudeBot => browser_type is ai');

	# ---------------------------------------------------------------
	# GPTBot (OpenAI training crawler)
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.2; +https://openai.com/gptbot)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'GPTBot => is_ai true');
	ok($i->is_robot() == 1,               'GPTBot => is_robot true (invariant)');
	ok($i->browser_type() eq 'ai',        'GPTBot => browser_type is ai');

	# ---------------------------------------------------------------
	# ChatGPT-User -- no "bot" or "spider" token in the UA, so the
	# old is_robot() regex alone would have missed it.  This tests
	# the is_ai() => is_robot() invariant for tricky UAs.
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); ChatGPT-User/1.0; +https://openai.com/bot)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'ChatGPT-User => is_ai true');
	ok($i->is_robot() == 1,               'ChatGPT-User => is_robot true (no "bot" token - tests invariant)');

	# ---------------------------------------------------------------
	# PerplexityBot
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; PerplexityBot/1.0; +https://perplexity.ai/perplexitybot)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'PerplexityBot => is_ai true');

	# ---------------------------------------------------------------
	# CCBot (Common Crawl -- primary data source for many LLM trainers)
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'CCBot/2.0 (https://commoncrawl.org/faq/)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'CCBot => is_ai true');

	# ---------------------------------------------------------------
	# cohere-ai -- unusual UA pattern with no "bot" or "spider" token
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'cohere-ai/1.0';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'cohere-ai => is_ai true');
	ok($i->is_robot() == 1,               'cohere-ai => is_robot true (no "bot" token)');

	# ---------------------------------------------------------------
	# Google-Extended (AI training opt-out signal) -- no "bot"/"spider"
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (compatible; Google-Extended)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'Google-Extended => is_ai true');
	ok($i->is_robot() == 1,               'Google-Extended => is_robot true (no "bot" token)');

	# ---------------------------------------------------------------
	# meta-externalagent (Meta/Facebook AI training) -- no bot/spider
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'meta-externalagent/1.1 (+https://developers.facebook.com/docs/sharing/webmasters/crawler)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'meta-externalagent => is_ai true');
	ok($i->is_robot() == 1,               'meta-externalagent => is_robot true (no "bot" token)');

	# ---------------------------------------------------------------
	# anthropic-ai token (alternative Anthropic UA pattern)
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'anthropic-ai/1.0';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'anthropic-ai UA => is_ai true');
	ok($i->is_robot() == 1,               'anthropic-ai UA => is_robot true (no "bot" token)');

	# ---------------------------------------------------------------
	# Claude-Web (alternative Anthropic headless-browser UA)
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Claude-Web/1.0';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 1,                  'Claude-Web => is_ai true');
	ok($i->is_robot() == 1,               'Claude-Web => is_robot true (no "bot" token)');

	# ---------------------------------------------------------------
	# Ordinary desktop browser -- must NOT trigger is_ai
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 0,                  'Chrome desktop UA => is_ai false');
	ok($i->browser_type() ne 'ai',        'Chrome desktop UA => browser_type not ai');

	# ---------------------------------------------------------------
	# Googlebot -- is a robot (search engine) but NOT an AI trainer
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';
	$i = new_ok('CGI::Info');
	ok($i->is_ai() == 0,                  'Googlebot => is_ai false (search, not AI trainer)');
	ok($i->is_robot() == 1,               'Googlebot => is_robot true');

	# ---------------------------------------------------------------
	# IS_AI environment variable override (for testing / classification)
	# ---------------------------------------------------------------
	{
		local $ENV{IS_AI} = 1;
		$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 Firefox/120';
		$i = new_ok('CGI::Info');
		ok($i->is_ai() == 1, 'IS_AI=1 env override forces true for non-AI UA');
	}

	{
		local $ENV{IS_AI} = 0;
		$ENV{HTTP_USER_AGENT} = 'ClaudeBot/1.0';
		$i = new_ok('CGI::Info');
		ok($i->is_ai() == 0, 'IS_AI=0 env override forces false for known AI UA');
	}

	# ---------------------------------------------------------------
	# Call-order invariant: is_robot() called BEFORE is_ai()
	# ChatGPT-User has no "bot"/"spider" token so the old is_robot()
	# regex alone would return 0; the fix is that is_robot() now calls
	# is_ai() internally.
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); ChatGPT-User/1.0; +https://openai.com/bot)';
	$i = new_ok('CGI::Info');
	ok($i->is_robot() == 1, 'call order: is_robot() first => true for ChatGPT-User');
	ok($i->is_ai()   == 1, 'call order: is_ai()    after => still true');

	# ---------------------------------------------------------------
	# Call-order invariant: is_ai() called BEFORE is_robot()
	# Setting $self->{is_robot} inside is_ai() means the subsequent
	# is_robot() call hits the cache and returns true.
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'Claude-Web/1.0';
	$i = new_ok('CGI::Info');
	ok($i->is_ai()   == 1, 'call order: is_ai()   first => true for Claude-Web');
	ok($i->is_robot() == 1, 'call order: is_robot() after => true (set by is_ai)');

	# ---------------------------------------------------------------
	# Security invariant: SQL injection in an AI crawler UA must still
	# trigger status 403 via is_robot().  Previously is_ai() ran first
	# and the injection check was never reached.
	# is_ai() on a fresh instance still correctly identifies the UA.
	# ---------------------------------------------------------------
	$ENV{HTTP_USER_AGENT} = 'GPTBot/1.0 SELECT foo AND bar FROM baz';
	$i = new_ok('CGI::Info');
	ok($i->is_robot(),                   'SQL injection in GPTBot UA => is_robot true');
	cmp_ok($i->status(), '==', 403,      'SQL injection in GPTBot UA => status 403');

	# A separate instance checks the AI identity of the same UA pattern
	# (without injection the regex still matches GPTBot token)
	$ENV{HTTP_USER_AGENT} = 'GPTBot/1.0';
	$i = new_ok('CGI::Info');
	ok($i->is_ai(),                      'clean GPTBot UA => is_ai true on fresh instance');
}
