use strict;
use warnings;
use Test::More;
use Time::HiRes ();

use FindBin;
use lib "$FindBin::Bin/lib";
use CpuGrowth qw(growth_ratio calibrate);

# Offline test: a text the catalog hands over is read in time linear in its
# length.
#
# Claim: a trigger's function and arguments come from the catalog columns
# (pg_trigger.tgfoid, tgargs), never from a pattern run over the text of
# pg_get_triggerdef; and the trailing whitespace and semicolons of a view or
# function definition are cut by one pass from the end. A long run of
# whitespace inside such a text, in a trigger argument or in a definition,
# costs no more than its length.
#
# Each growth case runs in a child process: it picks how often to repeat the
# read so that the small run needs 0.1 s of CPU, builds the input for the
# length and for 8 times that, and reports the ratio of the CPU times (linear:
# 8 at most, less where the fixed cost of a call weighs in; quadratic: near 64;
# the limit is 24). CPU time, not the wall clock, so a loaded machine or a
# coverage run slows both runs alike. The child is killed at a hard deadline,
# so a superlinear read fails the test instead of hanging the suite.

use DBIO::PostgreSQL::Introspect::Triggers ();
use DBIO::PostgreSQL::Util qw(trim_end);
use DBIO::PostgreSQL::Diff ();
use DBIO::PostgreSQL::Diff::Function ();

package DBIO::PostgreSQL::Introspect::Mock;
use base 'DBIO::PostgreSQL::Introspect';

sub new {
  my ($class, %args) = @_;
  return bless \%args, $class;
}
sub _build_model { die "should not be called" }

package main;

my $FACTOR   = 8;
my $LIMIT    = 3 * $FACTOR;
my $DEADLINE = 60;
my $LENGTH   = 4_000;     # the length the repetitions are calibrated at

# Growth of the CPU time of $run->($build->($n)) from $LENGTH to $FACTOR *
# $LENGTH, measured in a child that is killed after $DEADLINE seconds. One read
# of a text this long takes far less than the 0.1 s the small run needs, so the
# run repeats it on the same input; the child picks the repetitions that bring
# the small run to 0.1 s of CPU, the memory stays that of one text.
# Returns ($ratio, $small_cpu, $repetitions), or an empty list when the child
# did not report in time.
sub growth_in_child {
  my ($build, $run) = @_;
  pipe my $reader, my $writer or die "pipe failed: $!";
  my $pid = fork;
  die "fork failed" unless defined $pid;
  if (!$pid) {
    close $reader;
    my $repeated = sub { my ($in) = @_; $run->($in->[0]) for 1 .. $in->[1] };
    my $reps = calibrate(sub { [ $build->($LENGTH), $_[0] ] }, $repeated, 1, 1.25, 0.1, 1);
    my ($ratio, $small) = growth_ratio(sub { [ $build->($_[0]), $reps ] },
      $repeated, $LENGTH, $FACTOR, 1);
    print {$writer} "$ratio $small $reps\n";
    close $writer;
    exit 0;
  }
  close $writer;
  my $deadline = Time::HiRes::time + $DEADLINE;
  my $done = 0;
  while (Time::HiRes::time < $deadline) {
    if (waitpid($pid, 1) == $pid) { $done = 1; last }    # WNOHANG
    Time::HiRes::sleep 0.02;
  }
  if (!$done) {
    kill 'KILL', $pid;
    waitpid $pid, 0;
    return;
  }
  my $line = <$reader>;
  return unless $? == 0 && defined $line && $line =~ /^(\S+) (\S+) (\d+)$/;
  return ($1, $2, $3);
}

# $what is the claim; the CPU time for $FACTOR times the length stays below
# $LIMIT times that of the length itself.
sub grows_linearly {
  my ($what, $build, $run) = @_;
  my ($ratio, $small, $reps) = growth_in_child($build, $run);
  if (!defined $ratio) {
    fail "$what: no result within $DEADLINE s";
    return;
  }
  note sprintf '%s: %d repetitions, small run %.3f s CPU, ratio %.2f', $what, $reps, $small, $ratio;
  cmp_ok $ratio, '<', $LIMIT,
    sprintf '%s: CPU time grows %.1f-fold for %d times the length (limit %d)',
      $what, $ratio, $FACTOR, $LIMIT;
}

my $SPACES = ' ' x 16_000;

# --- the trigger: function and arguments from the catalog columns ---------
{
  my $call = sub { DBIO::PostgreSQL::Introspect::Triggers->execute_call({ @_ }) };

  is $call->(function_signature => 'auth.touch_user()', argument_count => 0, arguments_hex => ''),
    'auth.touch_user()', 'a trigger function without arguments';
  is $call->(function_signature => '"My Fn"()', argument_count => 0, arguments_hex => ''),
    '"My Fn"()', 'the name is the one regprocedure wrote, quoted where it needs it';
  is $call->(function_signature => 'f()', argument_count => 2,
      arguments_hex => unpack('H*', "a\0it's\0")),
    q{f('a', 'it''s')}, 'arguments are string literals, a quote doubled';
  is $call->(function_signature => 'f()', argument_count => 2,
      arguments_hex => unpack('H*', "\0x\0")),
    q{f('', 'x')}, 'an empty argument stays an argument';
  my $text = q{EXECUTE FUNCTION g('x')};
  is $call->(function_signature => 'f()', argument_count => 1,
      arguments_hex => unpack('H*', "$text;\0")),
    q{f('EXECUTE FUNCTION g(''x'');')}, 'an argument that looks like the clause is only an argument';
  is $call->(function_signature => undef, argument_count => 0, arguments_hex => ''),
    undef, 'no function, no call';

  grows_linearly 'a trigger argument of blanks is read',
    sub { unpack 'H*', (' ' x $_[0]) . "\0" },
    sub { $call->(function_signature => 'f()', argument_count => 1, arguments_hex => $_[0]) };

  sub trigger_model {
    my ($blanks) = @_;
    DBIO::PostgreSQL::Introspect::Mock->new(
      preserve_case => 0,
      model => { triggers => { 'public.t' => { trg => {
        timing => 'BEFORE', event => 'INSERT', orientation => 'ROW',
        definition => "CREATE TRIGGER trg BEFORE INSERT ON public.t FOR EACH ROW EXECUTE FUNCTION f('$blanks')",
        execute    => "f('$blanks')",
      } } } },
    );
  }
  my $intro = trigger_model($SPACES);
  my @stmts;
  grows_linearly 'the generator takes the call from the model, with blanks in the definition',
    sub { trigger_model(' ' x $_[0]) },
    sub { $_[0]->result_class_extra_statements('public.t') };
  @stmts = $intro->result_class_extra_statements('public.t');
  is_deeply [ grep { $_->[0] eq 'pg_trigger' } @stmts ],
    [[ pg_trigger => 'trg', {
      when => 'BEFORE', event => 'INSERT', for_each => 'ROW', execute => "f('$SPACES')",
    } ]],
    'and the trigger carries the call of the model';
}

# --- trim_end ---------------------------------------------------------------
is trim_end("a b \n\t "), 'a b', 'trim_end cuts trailing whitespace';
is trim_end(" a;; ;\n", ';'), ' a', 'with a set of characters it cuts those too';
is trim_end(" \n"), '', 'only whitespace leaves nothing';
is trim_end(''), '', 'the empty string stays';

# --- view_definition of the introspected model ------------------------------
{
  my $view = sub {
    my ($def) = @_;
    DBIO::PostgreSQL::Introspect::Mock->new(
      preserve_case => 0,
      model => { tables => { 'public.v' => { view_definition => $def } } },
    )->view_definition('public.v');
  };
  is $view->(" SELECT 1\n  FROM t ; \n"), 'SELECT 1
  FROM t', 'a closing semicolon and the blanks around it are cut';
  is $view->("SELECT 1;;"), 'SELECT 1;', 'one semicolon only';
  is $view->("SELECT 1  \n"), 'SELECT 1', 'trailing blanks without semicolon';
  is $view->(undef), undef, 'no definition stays none';

  grows_linearly 'a view definition with a run of blanks inside is read',
    sub { "SELECT 1" . (' ' x $_[0]) . "FROM t;" }, $view;
  grows_linearly 'a run of blanks ahead of a closing semicolon is read',
    sub { "SELECT '" . (' ' x $_[0]) . "';" }, $view;
}

# --- the diff of a function and of a view ----------------------------------
{
  my $function = sub {
    DBIO::PostgreSQL::Diff::Function->new(
      action => 'create', function_key => 'public.f()',
      function_info => { definition => $_[0] },
    )->as_sql;
  };
  is $function->("CREATE FUNCTION f() ...  \n"), 'CREATE FUNCTION f() ...;', 'a function gets its semicolon';
  is $function->("CREATE FUNCTION f() ...;\n\n"), 'CREATE FUNCTION f() ...;', 'and keeps the one it has';

  grows_linearly 'a function definition with a run of blanks inside is written',
    sub { "CREATE FUNCTION f() AS x" . (' ' x $_[0]) . "y" }, $function;

  my $view_sql = sub {
    my ($def) = @_;
    my $target = {
      tables  => { 'public.v' => { schema_name => 'public', table_name => 'v', kind => 'v',
        view_definition => $def, depends_on => [] } },
      columns => { 'public.v' => [ { column_name => 'a', data_type => 'integer' } ] },
    };
    return DBIO::PostgreSQL::Diff->new(source => {}, target => $target)->as_sql;
  };
  like $view_sql->(" SELECT 1 ;\n"), qr/AS\s+SELECT 1;/, 'a view is written without the doubled semicolon';

  grows_linearly 'a view definition with a run of blanks inside is written',
    sub { "SELECT 1" . (' ' x $_[0]) . "FROM t;" }, $view_sql;
}

done_testing;
