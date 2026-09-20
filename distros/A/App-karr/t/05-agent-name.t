use strict;
use warnings;
use Test::More;

# ADR 0005 (ticket #281): agent-name is no longer a random two-word generator.
# The name derivation moved into App::karr::AgentName, a reusable module the
# command and karr-foundation both call, so it produces one string from one
# checkout. The old _load_words word list is gone; the behaviour tested here is
# the sanitisation and the --unique suffix. The command-level and KARR_CLAIM
# integration behaviour lives in t/281.

use App::karr::AgentName qw( agent_name sanitize_claim_token );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

subtest 'sanitize_claim_token folds any string to a claim-safe token' => sub {
  is sanitize_claim_token('karr'),        'karr',        'already a token';
  is sanitize_claim_token('My Project'),  'my-project',  'space and case';
  is sanitize_claim_token('a_b.c'),       'a-b-c',       'punctuation to dashes';
  is sanitize_claim_token('--trim--'),    'trim',        'ends trimmed';
  is sanitize_claim_token("caf\x{e9}"),   'caf',         'non-ASCII dropped/folded';
  is sanitize_claim_token(''),            '',            'empty stays empty';
};

subtest 'agent_name(unique => 1) keeps the base and adds a 3-char suffix' => sub {
  # A directory that is NOT inside any git checkout, so the basename itself is
  # the name (no walk up to some ancestor repo root).
  my $parent = tempdir( CLEANUP => 1 );
  my $dir    = path($parent)->child('Widget Shop');
  $dir->mkpath;
  $dir = "$dir";

  my $base = agent_name( dir => $dir );
  is $base, 'widget-shop', 'the sanitised basename';

  my $u = agent_name( dir => $dir, unique => 1 );
  like $u, qr/\Awidget-shop-[a-z0-9]{3}\z/, "base plus suffix: $u";
};

done_testing;
