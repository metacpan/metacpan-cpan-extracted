use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use DBIO::Core;
use DBIO::Generate::Style::Vanilla;
use DBIO::Generate::Style::Cake;
use DBIO::Generate::Style::Candy;

# ---------------------------------------------------------------------------
# Regression: a non-scalar arg to result_class_extra_statements.
#
# result_class_extra_statements (DBIO::Introspect::Base) is documented to
# hand its args to the emitter "verbatim". PostgreSQL passes a def hashref
# for pg_index / pg_trigger / pg_rls / pg_check_constraint -- a non-scalar
# arg neither style handled: Vanilla stringified the ref to "HASH(0x...)"
# and spliced that raw (does not compile); Cake/Candy called _dump_val($_)
# as a plain function so $_[1] was always undef (every arg rendered as
# undef). Cake was fixed in k185; Candy carried the same latent $_[1] bug
# and is fixed here (k190).
#
# This drives all three styles with a nested-hashref extra_statement, evals
# the emitted source, and asserts both that it compiles AND that the def
# reaches the call with its structure intact -- not just non-fatal output.
# ---------------------------------------------------------------------------

my $def = {
  columns => ['embedding'],
  using   => 'ivfflat',
  with    => { lists => '100' },
};

my $extra_statements = [
  [ pg_index => 'users_embedding_idx', $def ],
];

sub base_spec {
  my (%extra) = @_;
  return {
    moniker            => 'Item',
    table              => 'items',
    column_order       => [qw/id/],
    columns            => {
      id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    },
    pk                  => [qw/id/],
    uniq                => [],
    relationships       => [],
    extra_statements    => $extra_statements,
    is_view             => 0,
    view_definition     => undef,
    result_base_class   => 'DBIO::Core',
    components          => [],
    additional_classes  => [],
    %extra,
  };
}

# ---------------------------------------------------------------------------
# Vanilla: __PACKAGE__->pg_index("users_embedding_idx", {...}); is a real
# method call resolved via `use base 'DBIO::Core'`. Capture what arrives.
# ---------------------------------------------------------------------------
{
  my @captured;
  no warnings 'once';
  local *DBIO::Core::pg_index = sub { my $self = shift; push @captured, [@_]; return 1; };

  my $spec = base_spec(class => 'My::Schema::Result::VanillaExtra');
  my $code = DBIO::Generate::Style::Vanilla->emit($spec);

  unlike $code, qr/HASH\(0x/, 'Vanilla: hashref arg is not raw-stringified';

  my $compiled = eval $code; ## no critic (ProhibitStringyEval)
  is $@, '', 'Vanilla: emitted code with a nested-hashref extra_statement compiles'
    or diag $code;
  ok $compiled, 'Vanilla: emitted code returns true';

  is_deeply(
    $captured[0],
    [ 'users_embedding_idx', $def ],
    'Vanilla: pg_index args, including the nested hashref, survive verbatim'
  );
}

# ---------------------------------------------------------------------------
# Cake: `pg_index "users_embedding_idx", {...};` is a bareword DSL call
# resolved through `use DBIO::Cake;`'s import. Stub the minimum surface.
# ---------------------------------------------------------------------------
{
  my @captured;
  {
    no strict 'refs';
    no warnings 'redefine';
    *{'DBIO::Cake::import'} = sub {
      my $caller = caller;
      *{"${caller}::table"}       = sub { return; };
      *{"${caller}::col"}         = sub { return; };
      *{"${caller}::primary_key"} = sub { return; };
      *{"${caller}::pg_index"}    = sub { push @captured, [@_]; return 1; };
    };
    $INC{'DBIO/Cake.pm'} = __FILE__;
  }

  my $spec = base_spec(class => 'My::Schema::Result::CakeExtra');
  my $code = DBIO::Generate::Style::Cake->emit($spec);

  unlike $code, qr/^pg_index\s+undef,\s*undef;/m, 'Cake: hashref arg does not render as undef';

  my $tmpdir = tempdir(CLEANUP => 1);
  my $file = File::Spec->catfile($tmpdir, 'CakeExtra.pm');
  open my $fh, '>', $file or die "open $file: $!";
  print $fh $code;
  close $fh;

  my $ok = eval { require $file; 1 };
  is $@, '', 'Cake: emitted code with a nested-hashref extra_statement compiles'
    or diag $code;
  ok $ok, 'Cake: require succeeded';

  is_deeply(
    $captured[0],
    [ 'users_embedding_idx', $def ],
    'Cake: pg_index args, including the nested hashref, survive verbatim'
  );
}

# ---------------------------------------------------------------------------
# Candy: `pg_index('users_embedding_idx', {...});` is a DSL call resolved
# through `use DBIO::Candy;`'s import. Candy had the same latent bug Cake
# had before k185 -- _dump_val read $_[1] instead of $_[0], so with a
# non-empty extra_statements list every arg rendered as undef. Stub the
# minimum surface and assert the args reach the call with real values.
# ---------------------------------------------------------------------------
{
  my @captured;
  {
    no strict 'refs';
    no warnings 'redefine';
    *{'DBIO::Candy::import'} = sub {
      my $caller = caller;
      *{"${caller}::table"}       = sub { return; };
      *{"${caller}::has_column"}  = sub { return; };
      *{"${caller}::primary_key"} = sub { return; };
      *{"${caller}::pg_index"}    = sub { push @captured, [@_]; return 1; };
    };
    $INC{'DBIO/Candy.pm'} = __FILE__;
  }

  my $spec = base_spec(class => 'My::Schema::Result::CandyExtra');
  my $code = DBIO::Generate::Style::Candy->emit($spec);

  unlike $code, qr/^pg_index\(undef,\s*undef\);/m, 'Candy: hashref arg does not render as undef';

  my $tmpdir = tempdir(CLEANUP => 1);
  my $file = File::Spec->catfile($tmpdir, 'CandyExtra.pm');
  open my $fh, '>', $file or die "open $file: $!";
  print $fh $code;
  close $fh;

  my $ok = eval { require $file; 1 };
  is $@, '', 'Candy: emitted code with a nested-hashref extra_statement compiles'
    or diag $code;
  ok $ok, 'Candy: require succeeded';

  is_deeply(
    $captured[0],
    [ 'users_embedding_idx', $def ],
    'Candy: pg_index args, including the nested hashref, survive verbatim'
  );
}

done_testing;
