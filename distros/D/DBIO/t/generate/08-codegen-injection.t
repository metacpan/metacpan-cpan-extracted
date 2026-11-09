use strict;
use warnings;
use Test::More;

# A generated word such as `exit` must not end this process if it ever runs.
BEGIN { *CORE::GLOBAL::exit = sub { die "exit called\n" } }
use File::Temp qw/tempdir/;
use File::Spec;

# ---------------------------------------------------------------------------
# SECURITY REGRESSION TEST
#
# Intent: a DB-derived identifier (column / table / constraint / relationship /
# moniker name, default value, view definition, ...) must NEVER become
# executable Perl in a generated Result class. A hostile DB column name such as
#
#   id => {} ); BEGIN { ...arbitrary code... } __PACKAGE__->add_columns( zzz => {
#
# spliced UNESCAPED into the generated source would run arbitrary Perl the
# moment the module is require'd. Every DB-derived string must instead be
# emitted as a properly-escaped Perl string literal (B::perlstring), and the
# bareword `package` position must be validated.
#
# This test drives the emitters directly with hostile $specs and proves the
# injected code does NOT run. The PoC used a real SQLite DB to obtain the
# malicious identifiers; core tests forbid a real DB, so we hand-build the
# $spec carrying the same hostile strings.
# ---------------------------------------------------------------------------

use DBIO::Generate::Util ();
use DBIO::Cake ();    # the real one: its type_function_names is the allowlist
use DBIO::Generate::Style::Vanilla;
use DBIO::Generate::Style::Cake;
use DBIO::Generate::Style::Candy;
use DBIO::Generate::Style::Moo;
use DBIO::Generate::Style::Moose;

my $tmpdir = tempdir(CLEANUP => 1);

# The sentinel: injected code is crafted to create this file. If it exists
# after require'ing a generated module, arbitrary code executed -> FAIL.
my $sentinel = File::Spec->catfile($tmpdir, 'PWNED');
$ENV{DBIO_INJECTION_SENTINEL} = $sentinel;

# Payload fragment that creates the sentinel when executed as Perl. Embedded
# into hostile identifiers below. We reference the sentinel via the env var so
# the payload is self-contained no matter where it lands in the source.
my $PAYLOAD = q{open my $fh, '>', $ENV{DBIO_INJECTION_SENTINEL}; print $fh 'pwned'; close $fh;};

# A hostile column name modelled on the real PoC vector: it tries to close the
# add_columns( call, run a BEGIN block, and re-open a benign add_columns(.
my $evil_col =
  qq{id => {} ); BEGIN { $PAYLOAD } __PACKAGE__->add_columns( zzz => { x => q{1} } };

# Hostile table name: tries to close the string + call + inject a BEGIN block.
my $evil_table = qq{evil'); BEGIN { $PAYLOAD } (};

# Hostile default value containing a quote, a semicolon, a backslash and a
# newline break-out -- the naive s/'/\\'/g escaping these emitters used to do
# misses the backslash and the newline.
my $evil_default = qq{x'; BEGIN { $PAYLOAD } '\\ \n __PACKAGE__->add_columns(};

# Hostile unique-constraint name, relationship name and view definition.
my $evil_uniq_name = qq{u'); BEGIN { $PAYLOAD } ('};
my $evil_rel_name  = qq{r', 'X'); BEGIN { $PAYLOAD } ('};
my $evil_view_def  = qq{SELECT 1'); BEGIN { $PAYLOAD } ('};

# Hostile, NON-NUMERIC column size. `size` is DB-reported column metadata and
# was the lone hand-built splice that escaped the first pass (Vanilla emitted
# `size => $info->{size}` raw). Carried on a column whose NAME is benign so the
# size is the *sole* injection vector -- if escaping the size regresses, only
# this case can fire the sentinel.
my $evil_size = qq{1 } . q[} ); BEGIN { open my $fh, '>', $ENV{DBIO_INJECTION_SENTINEL}; print $fh 'pwned'; close $fh } __PACKAGE__->add_columns( zzz => { x => 1 ];

# Build a hostile spec for a given style/class. The class name itself stays a
# valid package (the package-name validator is exercised separately below);
# every other field is poisoned.
sub hostile_spec {
  my ($class) = @_;
  return {
    moniker      => "Evil\n$PAYLOAD",         # newline break-out of # ABSTRACT:
    class        => $class,
    table        => $evil_table,
    column_order => [ $evil_col, 'sized', 'safe' ],
    columns      => {
      $evil_col => {
        data_type     => qq{int'); BEGIN { $PAYLOAD } ('},
        size          => qq{1); BEGIN { $PAYLOAD } (},
        is_nullable   => 0,
        default_value => $evil_default,
      },
      # benign name, hostile non-numeric size -> isolates the size sink
      sized => { data_type => 'integer', size => $evil_size, is_nullable => 0 },
      safe  => { data_type => 'integer', is_nullable => 1 },
    },
    pk    => [ $evil_col ],
    uniq  => [ [ $evil_uniq_name, [ $evil_col ] ] ],
    relationships => [
      { method => 'belongs_to',
        args   => [ $evil_rel_name, qq{X'); BEGIN { $PAYLOAD } ('},
                    { qq{foreign.$evil_col} => qq{self'); BEGIN { $PAYLOAD } ('} }, {} ] },
    ],
    extra_statements  => [],
    is_view           => 1,
    view_definition   => $evil_view_def,
    result_base_class => 'DBIO::Core',
    components        => [],
    additional_classes => [],
  };
}

# ---------------------------------------------------------------------------
# Stub the runtime DSL / base so requiring a generated module is a pure no-op.
# After this, the ONLY way the sentinel can appear is injected code running --
# the legitimate DSL/methods do nothing. We prime %INC so the generated
# `use DBIO::Cake;` etc. find these stubs instead of the real modules.
# ---------------------------------------------------------------------------

# Every bareword DSL function / method name the emitters can emit. All no-ops.
my @DSL_FUNCS = qw(
  table table_class view_definition
  load_components
  col column primary_column nullable_column has_column
  null auto_inc
  primary_key set_primary_key
  unique unique_constraint add_unique_constraint
  add_columns result_source_instance
  belongs_to has_many has_one might_have many_to_many
  integer varchar text bigint smallint
  extends meta make_immutable
);

{
  no strict 'refs';
  no warnings 'redefine';

  # A stub package whose import() installs no-op DSL subs into its caller.
  my $make_dsl_stub = sub {
    my ($pkg) = @_;
    *{"${pkg}::import"} = sub {
      my $caller = caller;
      for my $f (@DSL_FUNCS) {
        # meta / make_immutable must resolve via @ISA to the DBIO::Core stubs
        # (meta returns a FakeMeta object); a local no-op returning undef would
        # break `__PACKAGE__->meta->make_immutable`.
        next if $f eq 'meta' || $f eq 'make_immutable';
        no warnings 'redefine';
        *{"${caller}::${f}"} = sub { return; };
      }
      # `extends 'Base'` must wire up @ISA so the generated
      # __PACKAGE__->method(...) calls resolve to the DBIO::Core stub methods.
      no warnings 'redefine';
      *{"${caller}::extends"} = sub {
        no strict 'refs';
        push @{"${caller}::ISA"}, @_;
      };
    };
  };

  # `use Moo;` / `use Moose;` install the `extends` keyword into the caller, so
  # the stubs must too (otherwise `extends "..."` is a bareword syntax error and
  # the benign control can't compile). Treat them like the DSL stubs.
  $make_dsl_stub->($_) for qw(DBIO::Cake DBIO::Candy Moo Moose);

  # Pure-import no-op stubs (the remaining Moo/Moose toolchain pieces).
  for my $pkg (qw(MooX::NonMoose MooseX::NonMoose MooseX::MarkAsMethods)) {
    *{"${pkg}::import"} = sub { return; };
  }

  # DBIO::Core: usable both as `use base 'DBIO::Core'` and as the method sink
  # for __PACKAGE__->table(...) etc. Provide no-op methods for everything except
  # result_source_instance / meta, which need to return chainable objects below.
  for my $f (@DSL_FUNCS) {
    next if $f eq 'result_source_instance' || $f eq 'meta';
    *{"DBIO::Core::${f}"} = sub { return; };
  }
  # result_source_instance must return an object that also no-ops view_definition
  *{"DBIO::Core::result_source_instance"} = sub {
    return bless {}, 'DBIO::Core::FakeRSI';
  };
  *{"DBIO::Core::FakeRSI::view_definition"} = sub { return; };
  *{"DBIO::Core::meta"} = sub { return bless {}, 'DBIO::Core::FakeMeta'; };
  *{"DBIO::Core::FakeMeta::make_immutable"} = sub { return; };

  # Prime %INC so `use`/`require` of these never hits the real modules.
  for my $pkg (qw(DBIO::Cake DBIO::Candy DBIO::Core Moo Moose
                  MooX::NonMoose MooseX::NonMoose MooseX::MarkAsMethods)) {
    (my $file = "${pkg}.pm") =~ s{::}{/}g;
    $INC{$file} ||= __FILE__;
  }
}

my %style = (
  vanilla => 'DBIO::Generate::Style::Vanilla',
  cake    => 'DBIO::Generate::Style::Cake',
  candy   => 'DBIO::Generate::Style::Candy',
  moo     => 'DBIO::Generate::Style::Moo',
  moose   => 'DBIO::Generate::Style::Moose',
);

my $n = 0;
sub require_generated {
  my ($code, $tag) = @_;
  $n++;
  my $file = File::Spec->catfile($tmpdir, "Gen${n}.pm");
  open my $fh, '>', $file or die "open $file: $!";
  print $fh $code;
  close $fh;

  # Compile/run the generated module exactly like require would.
  unlink $sentinel if -e $sentinel;
  my $ok = eval { require $file; 1 };
  my $err = $@;
  return ($ok, $err, $file);
}

# --- Hostile specs: injected code must NOT run, for every style -------------
my $i = 0;
for my $name (sort keys %style) {
  my $class = "Injection::Test::" . ucfirst($name) . (++$i);
  my $spec  = hostile_spec($class);

  my $code = eval { $style{$name}->emit($spec) };
  ok defined $code, "$name: emit() produced source for hostile spec"
    or do { diag "emit died: $@"; next };

  my ($ok, $err) = require_generated($code, $name);

  # The generated module may or may not compile cleanly (a poisoned identifier
  # safely embedded as a string literal yields valid Perl; we don't require
  # compilation to fail). What MUST hold: no injected code executed.
  ok !-e $sentinel,
    "$name: hostile identifiers did NOT execute injected code (no sentinel)";

  unlink $sentinel if -e $sentinel;
}

# --- Benign negative control: clean spec loads, creates no sentinel ---------
for my $name (sort keys %style) {
  my $class = "Benign::Test::" . ucfirst($name);
  my $spec  = {
    moniker      => 'User',
    class        => $class,
    table        => 'users',
    column_order => [qw/id name/],
    columns      => {
      id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      name => { data_type => 'varchar', size => 100, is_nullable => 1 },
    },
    pk    => [qw/id/],
    uniq  => [],
    relationships => [],
    extra_statements => [],
    is_view => 0,
    view_definition => undef,
    result_base_class => 'DBIO::Core',
    components => [],
    additional_classes => [],
  };

  my $code = $style{$name}->emit($spec);
  my ($ok, $err) = require_generated($code, "benign-$name");
  ok $ok, "$name: benign spec compiles cleanly" or diag $err;
  ok !-e $sentinel, "$name: benign spec creates no sentinel";

  unlink $sentinel if -e $sentinel;
}

# --- Package-name validator must croak on a hostile class -------------------
{
  my $evil_class = q{Foo; BEGIN { open my $f,'>',$ENV{DBIO_INJECTION_SENTINEL} } package Bar};
  for my $name (sort keys %style) {
    my $spec = hostile_spec($evil_class);
    my $code = eval { $style{$name}->emit($spec) };
    ok( !defined($code) && $@,
      "$name: emit() croaks on a hostile package/class name" )
      or diag "expected croak, got code:\n$code";
  }

  # And the helper itself, directly.
  eval { DBIO::Generate::Util::assert_pkg($evil_class) };
  like $@, qr/package name/, 'assert_pkg croaks on hostile package name';

  eval { DBIO::Generate::Util::assert_pkg('My::Schema::Result::User') };
  is $@, '', 'assert_pkg accepts a well-formed package name';
}

# --- Type words: a data_type is data, never a Perl word ---------------------
# Perl quote-like operators (qx q qq s y tr m), __END__ and exit are plain
# identifiers; as a bareword type they would be code. Only the type functions
# DBIO::Cake exports may appear as a bareword; every other type is a string.
{
  my @words = qw(qx q qq qw s y tr m __END__ __DATA__ exit die);

  for my $name (sort keys %style) {
    for my $word (@words) {
      my $class = "Word::Test::" . ucfirst($name) . (++$i);
      my $spec  = {
        moniker      => 'W',
        class        => $class,
        table        => 'w',
        column_order => [qw/a b/],
        columns      => {
          a => { data_type => $word, is_nullable => 0 },
          b => { data_type => 'integer', is_nullable => 0 },
        },
        pk => [qw/a/], uniq => [], relationships => [], extra_statements => [],
        is_view => 0, view_definition => undef,
        result_base_class => 'DBIO::Core', components => [], additional_classes => [],
      };
      my $code = $style{$name}->emit($spec);
      my ($ok, $err) = require_generated($code, "word-$name-$word");
      ok $ok, "$name: type word '$word' compiles" or diag $err;
      ok !-e $sentinel, "$name: type word '$word' runs no code";
      unlink $sentinel if -e $sentinel;
      unlike $code, qr/(?:=>|\s)\Q$word\E\s*(?:[;,(]|$)/m,
        "$name: type word '$word' is not emitted as a bareword"
        if $name eq 'cake';
    }
  }

  # The allowlist is DBIO::Cake's own list of type functions.
  ok( DBIO::Cake->can('type_function_names'), 'DBIO::Cake lists its type functions' );
  my %bare_ok = map { $_ => 1 } eval { DBIO::Cake->type_function_names };
  ok $bare_ok{varchar} && $bare_ok{integer}, 'type_function_names has the column types';
  ok !$bare_ok{$_}, "type_function_names does not list '$_'" for qw(qx q s y exit col table null);

  # A listed type keeps the DSL word form, any other type is a string.
  my $spec = {
    moniker => 'W', class => 'Word::Test::CakeWord', table => 'w',
    column_order => [qw/a/],
    columns => { a => { data_type => 'varchar', size => 20 } },
    pk => [], uniq => [], relationships => [], extra_statements => [],
    is_view => 0, result_base_class => 'DBIO::Core', components => [],
  };
  my $cake = 'DBIO::Generate::Style::Cake';
  like $cake->emit($spec), qr/col "a" => varchar\(20\);/,
    'cake: an exported type function keeps the word form';
  $spec->{columns}{a} = { data_type => 'qx', size => 20 };
  like $cake->emit($spec), qr/col "a" => data_type => "qx", size => 20;/,
    'cake: any other type is a string literal';
}

# --- Method names: a method is an identifier, nothing else ------------------
{
  my @bad = (
    q{foo; BEGIN { $ENV{X} } bar},
    q{a b}, q{1abc}, q{foo-bar}, q{foo(}, qq{foo\nbar}, '', q{Foo::bar},
  );
  my $base = sub {
    return {
      moniker => 'M', class => 'Method::Test', table => 'm',
      column_order => [qw/a/],
      columns => { a => { data_type => 'integer', is_nullable => 0 } },
      pk => [qw/a/], uniq => [], relationships => [], extra_statements => [],
      is_view => 0, view_definition => undef,
      result_base_class => 'DBIO::Core', components => [], additional_classes => [],
    };
  };
  for my $name (sort keys %style) {
    for my $bad (@bad) {
      my $spec = $base->();
      $spec->{extra_statements} = [ [ $bad, 'x' ] ];
      my $code = eval { $style{$name}->emit($spec) };
      my $err  = $@;
      ok !defined($code) && $err, "$name: extra_statements method is checked";
      like $err, qr/extra_statements method/, "$name: the message names the key";
      unlike $err, qr/BEGIN|\$ENV/, "$name: the message carries no value";

      $spec = $base->();
      $spec->{relationships} = [ { method => $bad, args => [ 'r', 'X', { 'foreign.a' => 'self.a' }, {} ] } ];
      $code = eval { $style{$name}->emit($spec) };
      $err  = $@;
      ok !defined($code) && $err, "$name: relationship method is checked";
      like $err, qr/relationship method/, "$name: the message names the key";
      unlike $err, qr/BEGIN|\$ENV/, "$name: the message carries no value";
    }

    # An identifier that is no relationship method is refused for a relation.
    my $spec = $base->();
    $spec->{relationships} = [ { method => 'unlink', args => [ 'r', 'X', { 'foreign.a' => 'self.a' }, {} ] } ];
    ok !defined(eval { $style{$name}->emit($spec) }) && $@,
      "$name: a relationship method must be a known relationship method";

    # The known ones and a driver's identifier-shaped statement go through.
    for my $m (qw/belongs_to has_many has_one might_have many_to_many/) {
      $spec = $base->();
      $spec->{relationships} = [ { method => $m, args => [ 'r', 'X', { 'foreign.a' => 'self.a' }, {} ] } ];
      ok defined(eval { $style{$name}->emit($spec) }), "$name: $m is emitted";
    }
    $spec = $base->();
    $spec->{extra_statements} = [ [ pg_index => 'i', { columns => ['a'] } ] ];
    ok defined(eval { $style{$name}->emit($spec) }), "$name: an identifier method is emitted";
  }
}

# --- Vanilla extra_statements: a string is a string, code is a scalar ref ----
{
  my $hostile = qq{x'); BEGIN { $PAYLOAD } ('};
  my $spec = {
    moniker => 'V', class => 'Verbatim::Test', table => 'v',
    column_order => [qw/a/],
    columns => { a => { data_type => 'integer', is_nullable => 0 } },
    pk => [qw/a/], uniq => [], relationships => [],
    extra_statements => [ [ add_columns => $hostile, 'my-name', 'plain' ] ],
    is_view => 0, view_definition => undef,
    result_base_class => 'DBIO::Core', components => [], additional_classes => [],
  };
  my $code = DBIO::Generate::Style::Vanilla->emit($spec);
  my ($ok, $err) = require_generated($code, 'vanilla-verbatim');
  ok $ok, 'vanilla: plain-string arguments compile' or diag $err;
  ok !-e $sentinel, 'vanilla: a plain-string argument runs no code';
  unlink $sentinel if -e $sentinel;
  like $code, qr/"my-name", "plain"\);/,
    'vanilla: every plain string is a string literal';

  $spec->{extra_statements} = [ [ add_columns => \'1 + 1', \'[ 1, 2 ]' ] ];
  $code = DBIO::Generate::Style::Vanilla->emit($spec);
  like $code, qr/\Q__PACKAGE__->add_columns(1 + 1, [ 1, 2 ]);\E/,
    'vanilla: a scalar ref is Perl code, written as it is';
  ($ok, $err) = require_generated($code, 'vanilla-code-ref');
  ok $ok, 'vanilla: a scalar-ref argument compiles' or diag $err;
}

ok !-e $sentinel, 'final: sentinel was never created across the whole test';

done_testing;
