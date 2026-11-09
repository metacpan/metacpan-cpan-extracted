use strict;
use warnings;

use Test::More;

# DBIO::Test::Conformance, the Names list (ADR 0060, ADR 0077, karr k391): a
# schema name (connect key 'schema'), an extension name and a load library are
# identifiers. A driver sets them through its identifier quoting, so the
# server shows the name as given, or refuses with a DBIO::Exception. A syntax
# error from the database, or a different name on the server, is a failure.
# The drivers below are mocks; no database is involved.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::Names;
use DBIO::Exception;
use DBIO::Exception::Server;
use DBIO::Util ();

{
  package NamesConf;
  use base 'DBIO::Test::Conformance';

  our (%KINDS, %SERVER);

  sub conformance_live_available { 1 }
  sub conformance_answered_through { { Names => 1 } }
  sub conformance_name_kinds { \%KINDS }

  # a driver that quotes: whatever name comes, the server shows it as given
  sub conformance_apply_name {
    my ($class, $kind, $name) = @_;
    return $name;
  }

  package NamesConf::Refusing;
  our @ISA = ('NamesConf');
  # a driver that sets plain names and refuses the rest, through its own
  # DBIO::Exception
  sub conformance_apply_name {
    my ($class, $kind, $name) = @_;
    DBIO::Util::assert_identifier_text("The $kind name", $name);
    DBIO::Exception->throw("The driver refuses the $kind name: it cannot be quoted here")
      if $name =~ /["\\\s]/;
    return $name;
  }

  package NamesConf::Concatenating;
  our @ISA = ('NamesConf');
  # SET search_path TO $name, as a naive driver writes it
  sub conformance_apply_name {
    my ($class, $kind, $name) = @_;
    die DBIO::Exception::Server->new(message => 'syntax error at or near "b"') if $name =~ /["; \\\n]/;
    return $name;
  }

  package NamesConf::Mangling;
  our @ISA = ('NamesConf');
  # sets something, but not the name that was given
  sub conformance_apply_name { my ($class, $kind, $name) = @_; (my $n = $name) =~ s/\W.*//s; return $n }
}

my $cases = DBIO::Test::Conformance->cases('Names');
is scalar @$cases, 18, 'three kinds, a plain name and five odd ones';
is_deeply [ sort keys %{ { map { $_->{input}{kind} => 1 } @$cases } } ],
  [qw(extension library schema)], 'schema, extension and load library';
is_deeply [ sort map { $_->{input}{name} } grep { $_->{input}{kind} eq 'schema' } @$cases ],
  [ sort ('a_b', 'a"b', 'a;b', 'a b', 'a\\b', "a\nb") ],
  'the names: plain, quote, semicolon, blank, backslash, newline';
is(DBIO::Test::Conformance->table_version('Names'), 1, 'the list has a table version');
is_deeply [ grep { $_->{since} != 1 } @$cases ], [], 'all cases are of version 1';

sub statuses {
  my ($class, %kinds) = @_;
  local %NamesConf::KINDS = %kinds;
  my %count;
  $count{ $_->{status} }++ for $class->results('Names');
  return \%count;
}
my %all = (schema => 1, extension => 1, library => 1);

is_deeply statuses('NamesConf', %all), { pass => 18 }, 'a driver that quotes passes every case';

is_deeply statuses('NamesConf::Refusing', %all), { pass => 3, refused => 15 },
  'refusing with a DBIO::Exception is an answer, with no declaration';

my $naive = statuses('NamesConf::Concatenating', %all);
is $naive->{fail}, 15, 'a syntax error from the database fails each name it cannot take';
is $naive->{pass}, 3, '... and the plain ones pass';
{
  local %NamesConf::KINDS = %all;
  my ($r) = NamesConf::Concatenating->results('Names', only => ['name-schema-quote']);
  like $r->{message}, qr/syntax error/, 'the failure carries what the database said';
}

is statuses('NamesConf::Mangling', %all)->{fail}, 15,
  'a name that comes back as another name fails';

is_deeply statuses('NamesConf::Concatenating', schema => 1), { pass => 1, fail => 5, na => 12 }
  , 'a kind the driver does not declare is not applicable, never a failure';
is_deeply statuses('NamesConf'), { na => 18 }, 'no capability, nothing asked of the driver';

{
  local %NamesConf::KINDS = ();
  my @calls;
  no warnings qw(redefine once);
  local *NamesConf::conformance_apply_name = sub { push @calls, 1; $_[2] };
  NamesConf->results('Names');
  is scalar @calls, 0, 'a kind without the capability does not reach the apply seam';
}

# a newer case than the driver answered stays green outside the release gates
{
  local %NamesConf::KINDS = %all;
  local $ENV{AUTHOR_TESTING} = 0;
  local $ENV{RELEASE_TESTING} = 0;
  no warnings qw(redefine once);
  local *NamesConf::Concatenating::conformance_answered_through = sub { { Names => 0 } };
  my $c = { }; $c->{ $_->{status} }++ for NamesConf::Concatenating->results('Names');
  is_deeply $c, { pass => 3, todo => 15 }, 'answered_through 0: the failures run as todo';
}

# declarations: a refusal cannot be declared for a Names case
{
  package NamesConf::Declares;
  our @ISA = ('NamesConf');
  sub conformance_refusals { { 'name-schema-quote' => { kind => 'server', reason => qr/x/ } } }
}
my @problem = NamesConf::Declares->check_declarations('Names');
like "@problem", qr/name-schema-quote.*Names/, 'a Names case takes no refusal declaration';
is_deeply [ NamesConf->check_declarations('Names') ], [], 'a driver with none declares nothing wrong';

# the seams must be provided
{
  package NamesConf::Bare;
  use base 'DBIO::Test::Conformance';
  sub conformance_live_available { 1 }
}
is_deeply [ map { $_->{status} } NamesConf::Bare->results('Names') ], [ ('na') x 18 ],
  'the default capability declares nothing';
{
  local %NamesConf::KINDS = %all;
  package NamesConf::NoApply;
  our @ISA = ('NamesConf::Bare');
  sub conformance_name_kinds { { schema => 1 } }
  package main;
  local $ENV{RELEASE_TESTING} = 1;
  my ($r) = NamesConf::NoApply->results('Names', only => ['name-schema-quote']);
  is $r->{status}, 'fail', 'a declared kind without the apply seam fails';
  like $r->{message}, qr/conformance_apply_name must be provided/, '... naming the seam';
}

done_testing;
