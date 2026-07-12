use strict;
use warnings;
use Test::More;

# Each tombstone must die unconditionally on load. This is the whole
# contract of a redirect stub -- if it stops dying, the takeover is
# silently useless. Two shapes:
#   renamed -- die message must name the replacement module
#   removed -- die message must say so, and must NOT claim a replacement
my %tombstone = (
  'DBIO::MySQL::Async'                     => { type => 'renamed', match => qr/DBIO::MySQL::EV\b/ },
  'DBIO::MySQL::Async::Pool'                => { type => 'renamed', match => qr/DBIO::MySQL::EV::Pool\b/ },
  'DBIO::MySQL::Async::QueryExecutor'       => { type => 'renamed', match => qr/DBIO::MySQL::EV::QueryExecutor\b/ },
  'DBIO::MySQL::Async::Storage'             => { type => 'renamed', match => qr/DBIO::MySQL::EV::Storage\b/ },
  'DBIO::MySQL::Async::TransactionContext'  => { type => 'renamed', match => qr/DBIO::MySQL::EV::TransactionContext\b/ },
  'DBIO::PostgreSQL::Async'                 => { type => 'renamed', match => qr/DBIO::PostgreSQL::EV\b/ },
  'DBIO::PostgreSQL::Async::ConnectInfo'    => { type => 'renamed', match => qr/DBIO::PostgreSQL::EV::ConnectInfo\b/ },
  'DBIO::PostgreSQL::Async::Pool'           => { type => 'renamed', match => qr/DBIO::PostgreSQL::EV::Pool\b/ },
  'DBIO::PostgreSQL::Async::Storage'        => { type => 'renamed', match => qr/DBIO::PostgreSQL::EV::Storage\b/ },
  'DBIO::PostgreSQL::Async::TransactionContext' => { type => 'renamed', match => qr/DBIO::PostgreSQL::EV::TransactionContext\b/ },
  'DBIO::Test::Future'                      => { type => 'renamed', match => qr/DBIO::Future::Immediate\b/ },
  'Dist::Zilla::Plugin::DBIO::SetCopyrightHolder' => { type => 'renamed', match => qr/Dist::Zilla::Plugin::DBIO::SetMeta\b/ },
  'DBIO::StartupCheck'                      => { type => 'removed', match => qr/removed/i },
);

plan tests => 3 * scalar keys %tombstone;

for my $mod (sort keys %tombstone) {
  my $spec = $tombstone{$mod};

  my $ok = eval "require $mod; 1";
  ok(!$ok, "$mod dies on load");
  like($@, $spec->{match}, "$mod die message matches expected pattern");

  if ($spec->{type} eq 'removed') {
    unlike($@, qr/renamed/i, "$mod die message does not falsely claim a rename");
  } else {
    like($@, qr/renamed/i, "$mod die message says it was renamed");
  }
}
