use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# Offline test for karr k153: a text the catalog hands over is read in time
# linear in its length.
#
# Claim: a trigger's function and arguments come from the catalog columns
# (pg_trigger.tgfoid, tgargs), never from a pattern run over the text of
# pg_get_triggerdef; and the trailing whitespace and semicolons of a view or
# function definition are cut by one pass from the end. A long run of
# whitespace inside such a text, in a trigger argument or in a definition,
# costs no more than its length.
#
# Each timed case runs in a child process that is killed at the deadline, so
# a superlinear read fails the test instead of hanging the suite.

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

# Runs $code in a child; true when it ended inside $limit seconds.
sub finishes_within {
  my ($limit, $code) = @_;
  my $pid = fork;
  die "fork failed" unless defined $pid;
  if (!$pid) {
    my $start = [ Time::HiRes::gettimeofday ];
    $code->();
    exit(Time::HiRes::tv_interval($start) < $limit ? 0 : 1);
  }
  my $deadline = Time::HiRes::time + $limit + 3;
  while (Time::HiRes::time < $deadline) {
    my $done = waitpid $pid, 1;    # WNOHANG
    return $? == 0 if $done == $pid;
    Time::HiRes::sleep 0.02;
  }
  kill 'KILL', $pid;
  waitpid $pid, 0;
  return 0;
}

my $MB     = 1_000_000;
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

  ok finishes_within(0.1, sub {
      $call->(function_signature => 'f()', argument_count => 1,
        arguments_hex => unpack('H*', "$SPACES\0"));
    }), 'a trigger argument of 16 000 blanks is read in under 0.1 s';

  my $big = "f('$SPACES');";
  my $intro = DBIO::PostgreSQL::Introspect::Mock->new(
    preserve_case => 0,
    model => { triggers => { 'public.t' => { trg => {
      timing => 'BEFORE', event => 'INSERT', orientation => 'ROW',
      definition => "CREATE TRIGGER trg BEFORE INSERT ON public.t FOR EACH ROW EXECUTE FUNCTION f('$SPACES')",
      execute    => "f('$SPACES')",
    } } } },
  );
  my @stmts;
  ok finishes_within(0.1, sub { @stmts = $intro->result_class_extra_statements('public.t') }),
    'the generator takes the call from the model, in under 0.1 s with 16 000 blanks in the definition';
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

  ok finishes_within(0.5, sub { $view->("SELECT 1" . (' ' x $MB) . "FROM t;") }),
    'a view definition with a 1 MB run of blanks inside is read in under 0.5 s';
  ok finishes_within(0.5, sub { $view->("SELECT '" . (' ' x $MB) . "';") }),
    'a 1 MB run of blanks ahead of a closing semicolon, in under 0.5 s';
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

  ok finishes_within(0.5, sub { $function->("CREATE FUNCTION f() AS x" . (' ' x $MB) . "y") }),
    'a function definition with a 1 MB run of blanks inside is written in under 0.5 s';

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

  ok finishes_within(0.5, sub { $view_sql->("SELECT 1" . (' ' x $MB) . "FROM t;") }),
    'a view definition with a 1 MB run of blanks inside is written in under 0.5 s';
}

done_testing;
