package DBIO::Test::Conformance;
# ABSTRACT: Shared case table runner: a driver answers every case: correctly, by refusing, or by a declared deviation

use strict;
use warnings;

our $VERSION = '0.900005';

use Scalar::Util ();
use Test::More ();
use mro ();
use DBIO::Core ();
use DBIO::Schema ();
use DBIO::Exception ();
use DBIO::Deploy::Base ();
use DBIO::Exception::Server ();


my $COUNTER = 0;
my $ROW_ID  = 0;   # the next free key of the rows the Bind checks create; reset per case
my %HELD;         # how many rows of a case hold a value, by source, column and value

my %KNOWN_AREA = map { $_ => 1 } qw(DDL Diff Bind Names);


my %TABLE_VERSION = (DDL => 2, Diff => 4, Bind => 1, Names => 1);

sub table_version {
  my ($class, $area) = @_;
  $area //= 'DDL';
  DBIO::Exception->throw("no table version for area '$area'")
    unless exists $TABLE_VERSION{$area};
  return $TABLE_VERSION{$area};
}


sub cases {
  my ($class, $area) = @_;
  DBIO::Exception->throw('cases() needs an area name, e.g. DDL')
    unless defined $area and $area =~ /\A[A-Za-z]\w*\z/;
  my $module = "DBIO::Test::Conformance::Cases::$area";
  (my $file = "$module.pm") =~ s{::}{/}g;
  my $loaded = eval { require $file; 1 };
  DBIO::Exception->throw("no conformance case list for area '$area': $module does not load")
    unless $loaded;
  return $module->cases;
}

# ---------------------------------------------------------------- the seams

sub _unprovided {
  my ($class, $seam) = @_;
  $class = ref($class) || $class;
  DBIO::Exception->throw(
    "$class->$seam must be provided by the driver (see DBIO::Test::Conformance)"
  );
}


sub conformance_live_available { $_[0]->_unprovided('conformance_live_available') }
sub conformance_connect        { $_[0]->_unprovided('conformance_connect') }
sub conformance_install        { $_[0]->_unprovided('conformance_install') }
sub conformance_cleanup        { $_[0]->_unprovided('conformance_cleanup') }
sub conformance_fact           { $_[0]->_unprovided('conformance_fact') }
sub conformance_diff_is_empty  { $_[0]->_unprovided('conformance_diff_is_empty') }
sub conformance_upgrade        { $_[0]->_unprovided('conformance_upgrade') }


sub conformance_deploy         { undef }


sub conformance_apply_name     { $_[0]->_unprovided('conformance_apply_name') }


sub conformance_name_kinds     { {} }


sub conformance_namespace        { undef }

sub conformance_quote_ident {
  my ($class, $schema, $name) = @_;
  my $quote = $schema->storage->sql_maker->quote_char;
  return $name unless defined $quote and length(ref $quote ? join '', @$quote : $quote);
  my ($open, $close) = ref $quote ? @$quote : ($quote, $quote);
  (my $inner = $name) =~ s/\Q$close\E/$close$close/g;
  return $open . $inner . $close;
}
sub conformance_refusals         { {} }
sub conformance_refused_areas    { {} }
sub conformance_answered_through { 0 }


sub conformance_create {
  my ($class, $schema, $source, $values) = @_;
  my $row = $schema->resultset($source)->create({ %{ $values || {} } });
  $row->discard_changes;
  return { $row->get_columns };
}


sub conformance_count {
  my ($class, $schema, $source, $cond) = @_;
  return $schema->resultset($source)->search($cond || {})->count;
}


sub conformance_delete {
  my ($class, $schema, $source, $cond) = @_;
  return $schema->resultset($source)->search($cond || {})->delete({ all => !$cond });
}


sub conformance_find {
  my ($class, $schema, $source, $cond) = @_;
  my $row = $schema->resultset($source)->search($cond || {})->first;
  return undef unless $row;
  return { $row->get_columns };
}


sub conformance_update {
  my ($class, $schema, $source, $cond, $set) = @_;
  return $schema->resultset($source)->search($cond || {})->update($set, { all => !$cond });
}


sub conformance_populate {
  my ($class, $schema, $source, $rows) = @_;
  $schema->resultset($source)->populate($rows);
  return;
}

# ---------------------------------------------------- declarations, offline


sub check_declarations {
  my ($class, $area) = @_;
  my %known = map { $_->{name} => 1 } @{ $class->cases($area) };
  my @problem;

  my $check = sub {
    my ($label, $decl, $cases) = @_;
    return "$label: not a hash" unless ref $decl eq 'HASH';
    my @p;
    my $kind = $decl->{kind} // '';
    if ($kind eq 'deviation' and !$cases) {
      return "$label: kind must be 'server' or 'pending', not 'deviation'";
    }
    if ($kind eq 'deviation') {
      push @p, "$label: a deviation needs a fact (qr//) naming what the server does"
        unless ref $decl->{fact} eq 'Regexp';
      push @p, "$label: a deviation needs a reason, the text of why it is accepted"
        unless defined $decl->{reason} and !ref $decl->{reason} and length $decl->{reason};
      return @p;
    }
    push @p, "$label: kind must be 'server' or 'pending', not '$kind'"
      unless $kind eq 'server' or $kind eq 'pending';
    push @p, "$label: reason must be a regex (qr//)"
      unless ref $decl->{reason} eq 'Regexp';
    return @p;
  };

  my $refusals = $class->conformance_refusals;
  for my $name (sort keys %$refusals) {
    next unless _area_of_case_name($name) eq $area;
    push @problem, "refusal '$name': unknown case" unless $known{$name};
    push @problem, "refusal '$name': a Names case takes no refusal declaration (a refusal is one of its answers)"
      if $area eq 'Names';
    push @problem, $check->("refusal '$name'", $refusals->{$name}, 1);
  }
  my $areas = $class->conformance_refused_areas;
  for my $name (sort keys %$areas) {
    push @problem, "refused area $name: unknown area" unless $KNOWN_AREA{$name};
    push @problem, "refused area $name: the Names list is answered per kind by conformance_name_kinds"
      if $name eq 'Names';
    push @problem, $check->("refused area $name", $areas->{$name});
  }
  my $through = $class->conformance_answered_through;
  if (ref $through eq 'HASH') {
    for my $name (sort keys %$through) {
      push @problem, "conformance_answered_through: unknown area $name"
        unless $KNOWN_AREA{$name};
      push @problem, "conformance_answered_through for $name must be a non-negative integer"
        unless defined $through->{$name} and $through->{$name} =~ /\A[0-9]+\z/;
    }
  }
  else {
    push @problem, 'conformance_answered_through must be a non-negative integer'
      unless defined $through and !ref $through and $through =~ /\A[0-9]+\z/;
  }
  return @problem;
}

# the area a case name belongs to, by its prefix; a name with none of the
# prefixes is checked with DDL, which reports it as an unknown case
sub _area_of_case_name {
  my ($name) = @_;
  return 'Diff' if $name =~ /\Adiff-/;
  return 'Bind' if $name =~ /\Abind-/;
  return 'Names' if $name =~ /\Aname-/;
  return 'DDL';
}

# the version of an area's list a driver declared it answered through: a
# scalar counts for DDL only, a hash ref per area, a missing area is 0
sub _through_for {
  my ($class, $area) = @_;
  my $through = $class->conformance_answered_through;
  return ref $through eq 'HASH' ? ($through->{$area} // 0)
       : $area eq 'DDL'         ? $through
       :                          0;
}

# ------------------------------------------------------------ the run itself


sub results {
  my ($class, $area, %opt) = @_;
  my @cases = @{ $class->cases($area) };
  if (my $only = $opt{only}) {
    my %want = map { $_ => 1 } @$only;
    @cases = grep { $want{ $_->{name} } } @cases;
  }

  my $refusals = $class->conformance_refusals;
  my $through  = $class->_through_for($area);
  my $strict   = $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
  my $areas    = $class->conformance_refused_areas;
  my $diff_refused = exists $areas->{Diff};
  # a refused area is a refusal of every case of the list, of the declared kind
  my $area_refusal = $area ne 'DDL' ? $areas->{$area} : undef;

  my @results;
  for my $case (@cases) {
    my $own = $refusals->{ $case->{name} };
    my $result = $area eq 'Names'
      ? $class->_run_names_case($case)
      : $class->_run_case($area, $case, $own // $area_refusal, $diff_refused);
    # a refusal that came from the declared area, not from the case itself
    $result->{via_area} = $area
      if !$own and $area_refusal and ($result->{status} eq 'pending' or $result->{status} eq 'refused');
    $result->{reason} = $area_refusal->{reason} if $result->{via_area};
    if ($result->{status} eq 'fail' and $case->{since} > $through and !$strict) {
      $result->{status}  = 'todo';
      $result->{message} = "newer than answered_through $through: $result->{message}";
    }
    push @results, $result;
  }
  return @results;
}


sub summary_line {
  my ($class, $results) = @_;
  my (%area_cases, @area_order);
  for my $r (grep { $_->{via_area} } @$results) {
    push @area_order, $r->{via_area} unless $area_cases{ $r->{via_area} };
    push @{ $area_cases{ $r->{via_area} } }, $r;
  }
  my @pending = grep { $_->{status} eq 'pending' and !$_->{via_area} } @$results;
  my @todo    = grep { $_->{status} eq 'todo' } @$results;
  my @dev     = grep { $_->{status} eq 'deviation' } @$results;
  my @part;
  for my $area (@area_order) {
    my @cases = @{ $area_cases{$area} };
    my $first = $cases[0];
    my $n = scalar @cases;
    my $count = $n . ' case' . ($n == 1 ? '' : 's');
    if ($first->{status} eq 'pending') {
      push @part, "$area area pending: $count";
    }
    else {
      my $reason = ref $first->{reason} eq 'Regexp'
        ? (re::regexp_pattern($first->{reason}))[0] : $first->{reason};
      push @part, "$area area refused by the server ($reason): $count";
    }
  }
  push @part, scalar(@pending) . ' pending refusal' . (@pending == 1 ? '' : 's') . ': '
    . join(', ', map { $_->{case} } @pending)
    if @pending;
  push @part, scalar(@dev) . ' deviation' . (@dev == 1 ? '' : 's') . ': '
    . join(', ', map { "$_->{case} ($_->{reason})" } @dev)
    if @dev;
  push @part, scalar(@todo) . ' case' . (@todo == 1 ? '' : 's')
    . ' newer than the answered table version: '
    . join(', ', map { $_->{case} } @todo)
    if @todo;
  return @part ? join('; ', @part) : undef;
}


sub run {
  my ($class, $area) = @_;
  my $tb = Test::More->builder;

  my @problem = $class->check_declarations($area);
  Test::More::ok(!@problem, 'the conformance declarations are whole')
    or Test::More::diag(join "\n", @problem);

  unless ($class->conformance_live_available) {
    Test::More::diag(scalar(@{ $class->cases($area) })
      . ' cases not run: no server to run against');
    return;
  }

  my @results = $class->results($area);
  for my $r (@results) {
    my $label = "$r->{case}: $r->{status}";
    if ($r->{status} eq 'todo') {
      $tb->todo_start($r->{message});
      Test::More::ok(0, $label);
      $tb->todo_end;
    }
    elsif ($r->{status} eq 'fail') {
      Test::More::ok(0, $label);
      Test::More::diag("$r->{case}: $r->{message}");
    }
    else {
      Test::More::ok(1, $label);
    }
  }

  my $line = $class->summary_line(\@results);
  Test::More::diag($line) if defined $line;
  return;
}

# A Names case (ADR 0077): the driver sets the name through its identifier
# quoting and shows the same name back, or refuses with a DBIO::Exception. A
# server's own error, or another name, is a failure; so is any exception
# that is not a DBIO::Exception. A kind the driver does not declare is not
# applicable.
sub _run_names_case {
  my ($class, $case) = @_;
  my ($kind, $name) = @{ $case->{input} }{qw(kind name)};
  my %r = (case => $case->{name});

  return { %r, status => 'na',
           message => "the driver declares no $kind (conformance_name_kinds)" }
    unless $class->conformance_name_kinds->{$kind};

  # the missing seam is the driver's programming error, never a refusal
  return { %r, status => 'fail',
           message => (ref($class) || $class)
                    . '->conformance_apply_name must be provided by the driver (see DBIO::Test::Conformance)' }
    if $class->can('conformance_apply_name') == \&DBIO::Test::Conformance::conformance_apply_name;

  my $shown;
  my $ok = eval { $shown = $class->conformance_apply_name($kind, $name); 1 };
  unless ($ok) {
    my $error = $@ || 'unknown error';
    my $text  = "$error"; $text =~ s/\s+\z//;
    return { %r, status => 'fail', message => "the database answered, not the driver: $text" }
      if Scalar::Util::blessed($error) and $error->isa('DBIO::Exception::Server');
    return { %r, status => 'refused', message => $text }
      if Scalar::Util::blessed($error) and $error->isa('DBIO::Exception');
    return { %r, status => 'fail', message => "not a DBIO::Exception: $text" };
  }

  return { %r, status => 'fail',
           message => "the $kind was set, but introspection shows "
                    . (defined $shown ? _show($shown) : 'nothing')
                    . ' for ' . _show($name) }
    unless defined $shown and $shown eq $name;
  return { %r, status => 'pass', message => '' };
}

# One case: drive it, then turn what happened into one answer.
sub _run_case {
  my ($class, $area, $case, $refusal, $diff_refused) = @_;
  my $name  = $case->{name};
  my $state = { errors => [], cleanup_error => undef };

  my $ok = eval { $class->_drive($area, $case, $state, $diff_refused); 1 };
  my $exception = $ok ? undef : ($@ || 'unknown error');

  my %r = (case => $name);

  if (defined $state->{cleanup_error}) {
    return { %r, status => 'fail',
             message => "cleanup failed: $state->{cleanup_error}" };
  }

  return { %r, status => 'na', message => $state->{na} }
    if defined $state->{na} and !defined $exception;

  if ($refusal and $refusal->{kind} eq 'deviation') {
    if (defined $exception) {
      my $text = "$exception"; $text =~ s/\s+\z//;
      return { %r, status => 'fail',
               message => "an exception is not a deviation: $text" };
    }
    unless (@{ $state->{errors} }) {
      return { %r, status => 'fail',
               message => "stale deviation: declared ($refusal->{reason}) but the case runs correctly" };
    }
    my $seen = join '; ', @{ $state->{errors} };
    return { %r, status => 'fail',
             message => "the result does not match the declared fact $refusal->{fact}: $seen" }
      unless $seen =~ $refusal->{fact};
    return { %r, status => 'deviation', message => $seen, reason => $refusal->{reason} };
  }

  if (defined $exception) {
    unless ($refusal) {
      return { %r, status => 'fail',
               message => "unexpected exception, and no refusal is declared for this case: $exception" };
    }
    my @missing = $class->_refusal_problems($case, $refusal, $exception);
    return { %r, status => 'fail',
             message => 'the refusal does not meet the convention: '
                      . join('; ', @missing) . " -- got: $exception" }
      if @missing;
    my $status = $refusal->{kind} eq 'pending' ? 'pending' : 'refused';
    my $text = "$exception"; $text =~ s/\s+\z//;
    return { %r, status => $status, message => $text };
  }

  if ($refusal) {
    return { %r, status => 'fail',
             message => "stale refusal: declared $refusal->{kind}"
                      . ' but the case succeeded' . (@{ $state->{errors} }
                          ? ' with wrong results: ' . join('; ', @{ $state->{errors} }) : '') };
  }

  if (@{ $state->{errors} }) {
    return { %r, status => 'fail', message => join('; ', @{ $state->{errors} }) };
  }

  return { %r, status => 'pass', message => '' };
}

sub _drive {
  my ($class, $area, $case, $state, $diff_refused) = @_;
  $ROW_ID = 0;
  %HELD   = ();
  return $class->_drive_diff($case, $state) if $area eq 'Diff';

  my $schema_class = $class->_build_schema_class($case);
  my $schema = $class->conformance_connect($schema_class);

  my $namespace;
  my $namespace_given = 0;
  my $ran = eval {
    $class->_resolve_view_definitions($schema, $case->{input}{sources});
    $namespace = $class->conformance_namespace($schema, $case);
    $namespace_given = 1;
    $class->conformance_install($schema, $case);
    for my $expect (@{ $case->{expect} }) {
      my $error = $class->_check($schema, $case, $expect);
      push @{ $state->{errors} }, $error if defined $error;
    }
    # postcondition 1 belongs to the install list; a value is not a declaration
    if ($area eq 'DDL' and !@{ $state->{errors} } and !$diff_refused
        and !$class->conformance_diff_is_empty($schema, $case)) {
      push @{ $state->{errors} },
        'diff: installing the declaration and diffing against the same declaration is not empty';
    }
    1;
  };
  my $failure = $ran ? undef : ($@ || 'unknown error');

  if ($namespace_given) {
    my $cleaned = eval { $class->conformance_cleanup($schema, $case, $namespace); 1 };
    $state->{cleanup_error} = ($@ || 'unknown error') unless $cleaned;
  }
  else {
    # no mark, nothing to remove; cleanup also disconnects, so close here
    eval { $schema->storage->disconnect };
  }

  die $failure if defined $failure;
  return;
}

# A Diff case: install `from`, load the rows, hand the driver the unconnected
# class of `to` and let it upgrade; the expectations and the second
# postcondition are asked of the schema it returns.
sub _drive_diff {
  my ($class, $case, $state) = @_;
  my $input = $case->{input};

  my $from = $class->conformance_connect($class->_build_schema_class($case, $input->{from}));
  my $schema = $from;   # the connected schema the case works with right now

  my $namespace;
  my $namespace_given = 0;
  my $ran = eval {
    $class->_resolve_view_definitions($from, $input->{from}{sources});
    $namespace = $class->conformance_namespace($from, $case);
    $namespace_given = 1;
    $class->conformance_install($from, $case);
    for my $row (@{ $input->{rows} || [] }) {
      $class->conformance_create($from, $row->{source}, $row->{values});
    }

    my $quote = sub { $class->conformance_quote_ident($from, $_[0]) };
    my $to_class = $class->_build_schema_class($case, $input->{to}, $quote);

    my $to;
    if ($input->{deploy}) {
      my $deploy = $class->conformance_deploy($from, $to_class, $case);
      unless (defined $deploy) {
        $state->{na} = 'the driver provides no conformance_deploy';
        return 1;
      }
      DBIO::Exception->throw((ref($class) || $class)
        . '->conformance_deploy must return a DBIO::Deploy::Base over the connected target schema')
        unless Scalar::Util::blessed($deploy) and $deploy->isa('DBIO::Deploy::Base')
           and Scalar::Util::blessed($deploy->schema) and $deploy->schema->isa('DBIO::Schema');
      $to = $deploy->schema;
      $schema = $to;
      $class->_run_deploy_check($input->{deploy}, $deploy, $case, $state);
    }
    else {
      $to = $class->conformance_upgrade($from, $to_class, $case);
      DBIO::Exception->throw((ref($class) || $class)
        . '->conformance_upgrade must return the connected schema of the target declaration')
        unless Scalar::Util::blessed($to) and $to->isa('DBIO::Schema');
      $schema = $to;
    }

    for my $expect (@{ $case->{expect} }) {
      my $error = $class->_check($schema, $case, $expect);
      push @{ $state->{errors} }, $error if defined $error;
    }
    if (!@{ $state->{errors} } and !$class->conformance_diff_is_empty($schema, $case)) {
      push @{ $state->{errors} },
        'diff: after the upgrade, a diff against the target declaration is not empty';
    }
    1;
  };
  my $failure = $ran ? undef : ($@ || 'unknown error');

  if ($namespace_given) {
    my $cleaned = eval { $class->conformance_cleanup($schema, $case, $namespace); 1 };
    $state->{cleanup_error} = ($@ || 'unknown error') unless $cleaned;
  }
  else {
    eval { $schema->storage->disconnect };
  }
  # the schema the upgrade started from is closed last: it may share its handle
  eval { $from->storage->disconnect }
    if Scalar::Util::refaddr($schema) != Scalar::Util::refaddr($from);

  die $failure if defined $failure;
  return;
}

# The deploy cases of the Diff list: what the deploy object of the driver does
# with a diff. Problems go to $state->{errors}; the database is brought to the
# target declaration in the end, so the shared postconditions hold.
sub _run_deploy_check {
  my ($class, $decl, $deploy, $case, $state) = @_;
  my $check = $decl->{check};
  my $schema = $deploy->schema;
  my $err = sub { push @{ $state->{errors} }, @_ };
  my $unchanged = sub {
    my ($what) = @_;
    for my $expect (@{ $decl->{unchanged} || [] }) {
      my $e = $class->_check($schema, $case, $expect);
      $err->("$what, but $e") if defined $e;
    }
  };

  if ($check eq 'inherited') {
    my $ref = ref $deploy;
    for my $m (qw(apply upgrade)) {
      my $own = $ref->can($m);
      $err->("$ref does not inherit $m from DBIO::Deploy::Base; a driver takes part through "
        . '_check_before_apply and _execute_diff')
        unless $own and $own == DBIO::Deploy::Base->can($m);
    }
    $deploy->upgrade;
  }
  elsif ($check eq 'dry_run') {
    my $diff = $deploy->diff;
    $err->('the diff of the case has no changes') unless $diff->has_changes;
    my $seen = $deploy->apply($diff, dry_run => 1);
    $err->('apply with dry_run did not return the diff') unless $seen;
    $unchanged->('apply with dry_run ran something');
    $deploy->upgrade;
  }
  elsif ($check eq 'guard') {
    my $diff = $deploy->diff;
    my $thrown = eval { $deploy->apply($diff); 1 } ? undef : ($@ || 'unknown error');
    if (!defined $thrown) {
      $err->('apply of a destructive diff without allow_destructive did not throw');
    }
    elsif (!(Scalar::Util::blessed($thrown) and $thrown->isa('DBIO::Exception'))
           or $thrown->isa('DBIO::Exception::Server')) {
      $err->("apply of a destructive diff without allow_destructive threw something other than a DBIO::Exception: $thrown");
    }
    elsif ("$thrown" !~ /allow_destructive/) {
      $err->("the refusal does not name allow_destructive: $thrown");
    }
    $unchanged->('apply without allow_destructive ran a statement');
    $deploy->apply($deploy->diff, allow_destructive => 1);
  }
  else {
    DBIO::Exception->throw("case $case->{name}: unknown deploy check '$check'");
  }
  return;
}

# the {{identifier}} places of a view definition are resolved once the storage
# exists: the hook quotes them by the rule of the driver
sub _resolve_view_definitions {
  my ($class, $schema, $sources) = @_;
  my $quote = sub { $class->conformance_quote_ident($schema, $_[0]) };
  for my $def (@$sources) {
    my $view = $def->{view} or next;
    (my $sql = $view->{definition}) =~ s/\{\{(.+?)\}\}/$quote->($1)/ge;
    $schema->source($def->{name})->view_definition($sql);
  }
  return;
}

sub _refusal_problems {
  my ($class, $case, $refusal, $exception) = @_;

  return 'it is not a DBIO::Exception'
    unless Scalar::Util::blessed($exception) and $exception->isa('DBIO::Exception');
  return 'it is a DBIO::Exception::Server: a server error handed through is not a refusal'
    if $exception->isa('DBIO::Exception::Server');

  my $text = "$exception";
  my $subject = $case->{subject} || {};
  my @sources = $class->_case_sources($case);
  my $src = $subject->{source} // $sources[0]{name};
  my ($def) = grep { $_->{name} eq $src } @sources;
  my $table = $def->{table};

  my @missing;
  push @missing, "the text does not contain the stem 'refus'" unless $text =~ /refus/i;
  push @missing, "the text does not name the table '$table'"
    unless defined $table and index($text, $table) >= 0;
  push @missing, "the text does not name the column '$subject->{column}'"
    if defined $subject->{column}
      and $text !~ /(?<![A-Za-z0-9_\$])\Q$subject->{column}\E(?![A-Za-z0-9_\$])/;
  push @missing, "the text does not match the declared reason $refusal->{reason}"
    unless $text =~ $refusal->{reason};
  return @missing;
}

# ------------------------------------------------- building a case's classes

# every source declaration of a case, the target declaration of a Diff case first
sub _case_sources {
  my ($class, $case) = @_;
  my $input = $case->{input};
  return @{ $input->{sources} } if $input->{sources};
  return map { @{ $input->{$_}{sources} } } qw(to from);
}

# the table of a source moniker, for a source the schema no longer knows
sub _table_of {
  my ($class, $case, $moniker) = @_;
  my ($def) = grep { $_->{name} eq $moniker } $class->_case_sources($case);
  DBIO::Exception->throw("case $case->{name}: no source '$moniker'") unless $def;
  return $def->{table};
}

# $decl is the declaration to build: the case's input, or the from / to of a
# Diff case; $quote, when given, resolves the {{name}} of a view definition
# right away (a class that is connected only later has no storage to ask)
sub _build_schema_class {
  my ($class, $case, $decl, $quote) = @_;
  $decl //= $case->{input};
  my $base = 'DBIO::Test::Conformance::_Case' . ++$COUNTER;
  my $schema_class = "$base\::Schema";

  my $derive = sub {
    my ($pkg, $parent) = @_;
    no strict 'refs';
    @{"${pkg}::ISA"} = ($parent);
    mro::set_mro($pkg, 'c3');
  };
  $derive->($schema_class, 'DBIO::Schema');

  my %package;
  my @sources = @{ $decl->{sources} };

  for my $def (@sources) {
    my $pkg = $package{ $def->{name} } = "$base\::Result::$def->{name}";
    $derive->($pkg, 'DBIO::Core');
    $pkg->table_class('DBIO::ResultSource::View') if $def->{view};
    $pkg->table($def->{table});
    if (my $view = $def->{view}) {
      my $rsrc = $pkg->result_source_instance;
      $rsrc->is_virtual($view->{virtual} ? 1 : 0);
      my $sql = $view->{definition};
      $sql =~ s/\{\{(.+?)\}\}/$quote->($1)/ge if $quote;
      $rsrc->view_definition($sql);
    }
    $pkg->add_columns(@{ $def->{columns} });
    $pkg->set_primary_key(@{ $def->{primary_key} }) if $def->{primary_key};
    $pkg->add_unique_constraint(@$_) for @{ $def->{unique} || [] };
    $pkg->result_source_instance->add_index_declaration($_)
      for @{ $def->{indexes} || [] };
  }

  # relationships after every package exists: they name each other
  for my $def (@sources) {
    my $pkg = $package{ $def->{name} };
    for my $rel (@{ $def->{relationships} || [] }) {
      my $type = $rel->{type};
      $pkg->$type($rel->{name}, $package{ $rel->{source} }, $rel->{cond},
                  $rel->{attrs} || ());
    }
  }

  $schema_class->register_class($_->{name}, $package{ $_->{name} }) for @sources;
  return $schema_class;
}

# ------------------------------------------------------ the expectation kinds

my %CHECK = (
  read_back      => '_check_read_back',
  rejects        => '_check_rejects',
  search_by      => '_check_search_by',
  auto_key       => '_check_auto_key',
  cascade_delete => '_check_cascade_delete',
  fact           => '_check_fact',
  rows_kept      => '_check_rows_kept',
  count          => '_check_count',
  bind_roundtrip => '_check_bind_roundtrip',
  bind_lob_ops   => '_check_bind_lob_ops',
  bind_literal   => '_check_bind_literal',
);


sub expectation_kinds { sort keys %CHECK }

sub _check {
  my ($class, $schema, $case, $expect) = @_;
  my ($kind, $args) = %$expect;
  my $method = $CHECK{$kind}
    or DBIO::Exception->throw("case $case->{name}: unknown expectation kind '$kind'");
  return $class->$method($schema, $args, $case);
}

sub _show {
  my ($v) = @_;
  return 'NULL' unless defined $v;
  return '[' . join(', ', map { _show($_) } @$v) . ']' if ref $v eq 'ARRAY';
  return "'$v'";
}

sub _same {
  my ($got, $want) = @_;
  return 1 if !defined $got and !defined $want;
  return 0 if !defined $got or !defined $want;
  if (ref $want eq 'ARRAY') {
    return 0 unless ref $got eq 'ARRAY' and @$got == @$want;
    for my $i (0 .. $#$want) { return 0 unless _same($got->[$i], $want->[$i]) }
    return 1;
  }
  return 0 if ref $got;
  return $got eq $want ? 1 : 0;
}

sub _check_read_back {
  my ($class, $schema, $a) = @_;
  my $row = $class->conformance_create($schema, $a->{source}, $a->{create});
  my @bad;
  for my $col (sort keys %{ $a->{is} || {} }) {
    push @bad, "$a->{source}.$col: expected " . _show($a->{is}{$col}) . ", read back " . _show($row->{$col})
      unless _same($row->{$col}, $a->{is}{$col});
  }
  for my $col (sort keys %{ $a->{isnt} || {} }) {
    push @bad, "$a->{source}.$col: read back " . _show($row->{$col}) . ", which it must not be"
      if _same($row->{$col}, $a->{isnt}{$col});
  }
  for my $col (sort keys %{ $a->{like} || {} }) {
    push @bad, "$a->{source}.$col: read back " . _show($row->{$col}) . ", expected to match $a->{like}{$col}"
      unless defined $row->{$col} and $row->{$col} =~ $a->{like}{$col};
  }
  return @bad ? join('; ', @bad) : undef;
}

sub _check_rejects {
  my ($class, $schema, $a) = @_;
  $class->conformance_create($schema, $a->{source}, $a->{first}) if $a->{first};
  my $accepted = eval { $class->conformance_create($schema, $a->{source}, $a->{create}); 1 };
  return "$a->{source}: the server accepted a row it must reject"
    if $accepted;
  return undef;
}

# conformance_count, with an undef answer turned into a failure text: a count
# that returns nothing is a broken seam, never a number to compare
sub _counted {
  my ($class, $schema, $source, $cond) = @_;
  my $n = $class->conformance_count($schema, $source, $cond);
  return (undef, "conformance_count returned undef for $source") unless defined $n;
  return ($n, undef);
}

sub _check_search_by {
  my ($class, $schema, $a) = @_;
  $class->conformance_create($schema, $a->{source}, $a->{create});
  my $through = $a->{through} // $a->{source};
  my ($found, $bad) = $class->_counted($schema, $through, { $a->{column} => $a->{value} });
  return $bad if defined $bad;
  return "$through.$a->{column}: " . _show($a->{value}) . " found $found rows, expected 1"
    unless $found == 1;
  return undef;
}

sub _check_auto_key {
  my ($class, $schema, $a) = @_;
  my $row = $class->conformance_create($schema, $a->{source}, $a->{create} || {});
  my @pk = $schema->source($a->{source})->primary_columns;
  my @unset = grep { !defined $row->{$_} or $row->{$_} eq '' } @pk;
  return "$a->{source}: the key " . join(', ', @unset) . ' was not set by the server'
    if @unset;
  return undef;
}

sub _check_cascade_delete {
  my ($class, $schema, $a) = @_;
  my $parent = $class->conformance_create($schema, $a->{parent}, $a->{parent_values});
  my %child  = %{ $a->{child_values} || {} };
  my %link;
  for my $ccol (keys %{ $a->{link} }) {
    $child{$ccol} = $link{$ccol} = $parent->{ $a->{link}{$ccol} };
  }
  $class->conformance_create($schema, $a->{child}, \%child);
  my %pk = map { $_ => $parent->{$_} } $schema->source($a->{parent})->primary_columns;
  $class->conformance_delete($schema, $a->{parent}, \%pk);
  my ($left, $bad) = $class->_counted($schema, $a->{child}, \%link);
  return $bad if defined $bad;
  return "$a->{child}: $left rows remain after the parent was deleted, expected cascade"
    if $left;
  return undef;
}

sub _check_fact {
  my ($class, $schema, $a, $case) = @_;
  my %args = %$a;
  my $name = delete $args{name};
  my $want = delete $args{is};
  # a source the upgrade dropped is no longer in the schema: its table is the
  # one the case declared
  $args{table} = (grep { $_ eq $a->{source} } $schema->sources)
    ? $schema->source($a->{source})->name
    : $class->_table_of($case, $a->{source});
  my $got = $class->conformance_fact($schema, $name, \%args);
  if ($name eq 'column_names') {
    $got  = [ sort @$got ] if ref $got eq 'ARRAY';
    $want = [ sort @$want ];
  }
  my $on = join '.', grep { defined } @$a{qw(source column)};
  return "$name of $on: expected " . _show($want) . ', the server shows ' . _show($got)
    unless _same($got, $want);
  return undef;
}

sub _check_rows_kept {
  my ($class, $schema, $a) = @_;
  my $find = $a->{find};
  my $what = "$a->{source} row (" . join(', ', map { "$_ = " . _show($find->{$_}) } sort keys %$find) . ')';
  my $row = $class->conformance_find($schema, $a->{source}, $find);
  return "$what: gone after the upgrade" unless $row;
  my @bad;
  for my $col (sort keys %{ $a->{is} || {} }) {
    my $error = _compare($row->{$col}, $a->{is}{$col}, "$what, $col after the upgrade");
    push @bad, $error if defined $error;
  }
  return @bad ? join('; ', @bad) : undef;
}

sub _check_count {
  my ($class, $schema, $a) = @_;
  my ($n, $bad) = $class->_counted($schema, $a->{source}, $a->{where} || {});
  return $bad if defined $bad;
  return "$a->{source}: $n rows match, expected $a->{is}" unless $n == $a->{is};
  return undef;
}

# a value for a message: short and plain as it is, else its length and start
sub _describe {
  my ($v) = @_;
  return 'NULL' unless defined $v;
  return "'$v'" if length($v) <= 24 and $v =~ /\A[\x20-\x7e]*\z/;
  return length($v) . ' characters starting '
    . join(' ', map { sprintf '%02x', ord } split //, substr($v, 0, 6));
}

# undef when got and want are the same string, else the failure text; for a
# long value it says where they part
sub _compare {
  my ($got, $want, $what) = @_;
  return undef if _same($got, $want);
  my $text = "$what: expected " . _describe($want) . ', read back ' . _describe($got);
  if (defined $got and defined $want and !ref $got) {
    my $n = length($got) < length($want) ? length($got) : length($want);
    my $at = 0;
    $at++ while $at < $n and substr($got, $at, 1) eq substr($want, $at, 1);
    $text .= " (first difference at position $at)";
  }
  return $text;
}

# --------------------------------------------------------- the Bind checks

sub _check_bind_roundtrip {
  my ($class, $schema, $a) = @_;
  my ($src, $col) = @$a{qw(source column)};
  my ($pk) = $schema->source($src)->primary_columns;
  my @bad;

  my $push = sub { push @bad, $_[0] if defined $_[0] };
  for my $v (@{ $a->{values} }) {
    for my $op (@{ $a->{ops} }) {
      my $what = "$src.$col $op";
      my $held_key = join "\0", $src, $col, $v;
      if ($op eq 'int_first') {
        # a statement that binds an integer, before the value is bound
        my (undef, $bad) = $class->_counted($schema, $src, { $pk => 0 });
        push @bad, "$what: $bad" if defined $bad;
      }
      elsif ($op eq 'create') {
        my $row = $class->conformance_create($schema, $src, { $pk => ++$ROW_ID, $col => $v });
        $push->(_compare($row->{$col}, $v, $what));
        $HELD{$held_key}++;
      }
      elsif ($op eq 'find') {
        my $row = $class->conformance_find($schema, $src, { $col => $v });
        if ($row) { $push->(_compare($row->{$col}, $v, $what)) }
        else      { push @bad, "$what: no row found by " . _describe($v) }
      }
      elsif ($op eq 'search') {
        my ($n, $bad) = $class->_counted($schema, $src, { $col => $v });
        if (defined $bad) { push @bad, "$what: $bad"; next }
        push @bad, "$what: " . _describe($v) . " found $n rows, expected " . ($HELD{$held_key} // 0)
          unless $n == ($HELD{$held_key} // 0);
      }
      elsif ($op eq 'update' or $op eq 'populate') {
        my $key = ++$ROW_ID;
        if ($op eq 'update') {
          $class->conformance_create($schema, $src, { $pk => $key });
          $class->conformance_update($schema, $src, { $pk => $key }, { $col => $v });
        }
        else {
          $class->conformance_populate($schema, $src, [ { $pk => $key, $col => $v } ]);
        }
        my $row = $class->conformance_find($schema, $src, { $pk => $key });
        if ($row) { $push->(_compare($row->{$col}, $v, $what)) }
        else      { push @bad, "$what: the row $key is not there" }
        $HELD{$held_key}++;
      }
      else {
        DBIO::Exception->throw("bind_roundtrip: unknown operation '$op'");
      }
    }
  }
  return @bad ? join('; ', @bad) : undef;
}

sub _check_bind_lob_ops {
  my ($class, $schema, $a) = @_;
  my ($src, $col, $label) = @$a{qw(source column label_column)};
  my ($pk) = $schema->source($src)->primary_columns;
  my $value = $a->{value};
  my @bad;

  # create({}): the row exists and the LOB is empty (NULL)
  my $empty = $class->conformance_create($schema, $src, {});
  push @bad, "$src.$col create({}): read back " . _describe($empty->{$col}) . ', expected NULL'
    if defined $empty->{$col};

  # update of the LOB alone; the caller's hash keeps the value, not a placeholder
  my %set = ($col => $value);
  $class->conformance_update($schema, $src, { $pk => $empty->{$pk} }, \%set);
  push @bad, _compare($set{$col}, $value, "$src.$col update: the caller's hash")
    if !_same($set{$col}, $value);
  my $row = $class->conformance_find($schema, $src, { $pk => $empty->{$pk} });
  push @bad, _compare($row && $row->{$col}, $value, "$src.$col update of the LOB only")
    if !$row or !_same($row->{$col}, $value);

  # populate mixing NULL and values
  my @want = ( [ 'lob-a', undef ], [ 'lob-b', $value ], [ 'lob-c', undef ] );
  my @rows = map { +{ $label => $_->[0], $col => $_->[1] } } @want;
  $class->conformance_populate($schema, $src, \@rows);
  for my $i (0 .. $#want) {
    push @bad, _compare($rows[$i]{$col}, $want[$i][1], "$src.$col populate: the caller's row $i")
      if !_same($rows[$i]{$col}, $want[$i][1]);
    my $got = $class->conformance_find($schema, $src, { $label => $want[$i][0] });
    if (!$got) { push @bad, "$src populate: row '$want[$i][0]' is not there"; next }
    push @bad, _compare($got->{$col}, $want[$i][1], "$src.$col populate row '$want[$i][0]'")
      if !_same($got->{$col}, $want[$i][1]);
  }
  return @bad ? join('; ', @bad) : undef;
}

sub _check_bind_literal {
  my ($class, $schema, $a) = @_;
  my ($src, $col) = @$a{qw(source column)};
  (my $sql = $a->{literal}) =~ s/\{\{(.+?)\}\}/$class->conformance_quote_ident($schema, $1)/ge;
  $class->conformance_create($schema, $src, $a->{create});

  my @bad;
  my ($hit, $hit_bad) = $class->_counted($schema, $src, \[ $sql, $a->{value} ]);
  push @bad, "$src.$col literal SQL: $hit_bad" if defined $hit_bad;
  push @bad, "$src.$col literal SQL: the bind " . _describe($a->{value}) . " found $hit rows, expected 1"
    if !defined $hit_bad and $hit != 1;
  my ($miss, $miss_bad) = $class->_counted($schema, $src, \[ $sql, $a->{other} ]);
  push @bad, "$src.$col literal SQL: $miss_bad" if defined $miss_bad;
  push @bad, "$src.$col literal SQL: the bind " . _describe($a->{other}) . " found $miss rows, expected 0"
    if !defined $miss_bad and $miss != 0;
  return @bad ? join('; ', @bad) : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Conformance - Shared case table runner: a driver answers every case: correctly, by refusing, or by a declared deviation

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

  package DBIO::Foo::Test::Conformance;
  use base 'DBIO::Test::Conformance';

  sub conformance_live_available { $ENV{DBIO_TEST_FOO_DSN} ? 1 : 0 }

  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->load_components('Foo');
    return $schema_class->connect(@ENV{qw(DBIO_TEST_FOO_DSN DBIO_TEST_FOO_USER DBIO_TEST_FOO_PASS)});
  }

  sub conformance_install { my ($class, $schema, $case) = @_; $schema->deploy }
  sub conformance_cleanup { my ($class, $schema, $case, $ns) = @_; ... drop what the case created, found by $ns; nothing without a mark ... }
  sub conformance_fact    { my ($class, $schema, $name, $args) = @_; ... read it back through Introspect ... }
  sub conformance_diff_is_empty { my ($class, $schema, $case) = @_; ... }

  sub conformance_answered_through { { DDL => 1, Diff => 1, Bind => 1 } }

  sub conformance_refusals {{
    'ddl-foreign-key' => {
      kind   => 'pending',                       # not built yet
      reason => qr/foreign keys are not emitted yet/,
    },
    'ddl-ident-special-chars' => {
      kind   => 'server',                        # this engine cannot do it
      reason => qr/cannot hold a quote character in a name/,
    },
    'ddl-type-size-char' => {
      kind   => 'deviation',                  # the engine does it differently
      fact   => qr/accepted a row it must reject/,   # what the run observes
      reason => 'the engine keeps the declared length but does not enforce it',
    },
  }}

=head1 DESCRIPTION

One list of cases, stated once in core, answered by every driver (ADR 0060).
A case is a schema declaration in DBIO's terms plus what must be observable
on the server afterwards. This module is the runner: it builds the result
classes of a case, hands them to the driver through a handful of seams,
checks the expectation and reports one answer per case.

There are exactly three acceptable answers:

=over 4

=item correct

The default. The case runs and its expectation holds. Needs no declaration.

=item refuses

The driver decides, before it emits anything it knows the server will reject,
to throw -- and says so in the driver's declaration
(L</conformance_refusals>). A declared refusal is a test, not a skip: the case
is driven, the exception has to come and has to meet L</The refusal
convention>, and a declared refusal that succeeds is a failure.

=item deviates

The engine does something else than the case expects, and the driver says
exactly what, and why that is accepted, in the same declaration
(C<kind =E<gt> 'deviation'>, L</Declaring refusals>). The case is driven, its
expectation has to fail in the declared way, and a deviation the case no
longer shows is a failure. Where a refusal is the driver's decision to throw,
a deviation is the server's behaviour taken as it is: SQLite stores 11
characters in C<CHARACTER(10)> and has no check to say otherwise. A deviation
answers the case like the other two (L</conformance_answered_through>).

=back

Silently wrong results nobody declared, SQL the server rejects and a server
error handed through are not answers; they are failures. There is no
per-case skip.

A driver subclasses this, answers the seams of L</WRITING A DRIVER'S CLASS>
and ships three lines of test file:

  use DBIO::SQLite::Test::Conformance;
  DBIO::SQLite::Test::Conformance->run('DDL');

There are three lists, one per area, and a driver runs each in a test file of
its own:

=over 4

=item DDL

L<DBIO::Test::Conformance::Cases::DDL>: one declaration is installed; the
server shows what it became.

=item Diff

L<DBIO::Test::Conformance::Cases::Diff>: a declaration is installed, rows are
loaded, the database is upgraded to a second declaration; the server shows the
result and the rows.

=item Bind

L<DBIO::Test::Conformance::Cases::Bind>: values go through a column by every
operation of the ResultSet API and must come back as written.

=item Names

L<DBIO::Test::Conformance::Cases::Names>: a schema name, an extension name and
a load library, each as a plain name and as a name with a quote, a semicolon,
a blank, a backslash or a line break (L</Names>).

=back

Each list has a table version of its own (L</table_version>) and a driver
answers each through a version of its own (L</conformance_answered_through>).
Core's own test of this class uses a mock driver and never a database; a
conformance run against a server belongs in the driver's dist.

=head1 METHODS

=head2 table_version

  my $v = DBIO::Test::Conformance->table_version;          # DDL
  my $v = DBIO::Test::Conformance->table_version('Diff');

The version of the case table of an area, C<DDL> without an argument. Each
list has its own version and starts at 1. A case carries the version that
added it as C<since>; a driver declares the version it answered through, per
area, as L</conformance_answered_through>. Throws for an unknown area.

=head2 cases

  my $cases = DBIO::Test::Conformance->cases('DDL');

The arrayref of cases of an area, a fresh copy. Throws for an area without a
list.

=head2 conformance_live_available

Seam, must be provided. See L</WRITING A DRIVER'S CLASS>.

=head2 conformance_connect

Seam, must be provided.

=head2 conformance_install

Seam, must be provided.

=head2 conformance_cleanup

Seam, must be provided. Removes only what the case created, found by the
mark L</conformance_namespace> returned; with no mark it removes nothing. The
runner does not call it when C<conformance_namespace> threw.

=head2 conformance_fact

Seam, must be provided.

=head2 conformance_diff_is_empty

Seam, must be provided.

=head2 conformance_upgrade

Seam, must be provided by a driver that runs the Diff list. See
L</WRITING A DRIVER'S CLASS>.

=head2 conformance_deploy

Seam with a default: C<undef>, so the deploy cases of the Diff list are not
applicable. See L</WRITING A DRIVER'S CLASS>.

=head2 conformance_apply_name

Needed to run the Names list for a kind the driver declares
(L</conformance_name_kinds>). See L</Names>.

=head2 conformance_name_kinds

Seam with a default: no kind, so every Names case is not applicable. A hash
ref of the kinds the engine has: C<schema> (a namespace the connect key
C<schema> names), C<extension> (a database extension by name), C<library> (a
library an extension loads).

=head2 conformance_namespace

Seam with a default: none. Returns the mark C<conformance_cleanup> works from;
throws when no empty namespace can be had.

=head2 conformance_quote_ident

Seam with a default: the quoting rule of the connected storage's SQL maker
(C<quote_char>, a single character or an opening and a closing one); without
one, C<$name> unchanged. A closing quote character inside C<$name> is doubled
(C<]> for the pair C<[>, C<]>; the character itself for a single one).

=head2 conformance_refusals

Seam with a default: no refusals.

=head2 conformance_refused_areas

Seam with a default: no area refused.

=head2 conformance_answered_through

Seam with a default: 0. A scalar counts for the DDL list only; a hash ref
gives the version per area.

=head2 conformance_create

Seam with a working default through the ResultSet API.

=head2 conformance_count

Seam with a working default through the ResultSet API.

=head2 conformance_delete

Seam with a working default through the ResultSet API.

=head2 conformance_find

  my $row = $class->conformance_find($schema, $source, \%condition);

Seam with a working default through the ResultSet API: the first row of
C<$source> matching C<%condition>, read fresh from the server, as a hashref of
its columns; C<undef> when none matches.

=head2 conformance_update

  my $n = $class->conformance_update($schema, $source, \%condition, \%set);

Seam with a working default through the ResultSet API: update the matching
rows with one C<UPDATE>. C<%set> is passed as the caller's hash, not a copy.

=head2 conformance_populate

  $class->conformance_populate($schema, $source, \@rows);

Seam with a working default through the ResultSet API: insert the rows (hash
refs, all with the same keys) in void context. C<@rows> is the caller's array;
the runner checks that it still holds the values afterwards.

=head2 check_declarations

  my @problems = $class->check_declarations('DDL');

What can be checked without a server: every declared refusal names a known
case, has kind C<server>, C<pending> or C<deviation>; a regex C<reason>;
a regex C<fact> and a non-empty string C<reason> for
C<deviation> (not allowed for an area); the same for every refused area; C<conformance_answered_through>
is a non-negative integer. Returns the problems as strings, none when the
declaration is whole. L</run> makes it the first test.

=head2 results

  my @results = $class->results('DDL');
  my @results = $class->results('DDL', only => [ 'ddl-foreign-key' ]);

Drive every case of the area and return one hashref per case:
C<< { case, status, message } >> and, for C<deviation>, C<reason>. It does not
touch L<Test::More>. C<status> is

=over 4

=item pass

The case is correct.

=item refused

A declared C<server> refusal came, and met the convention.

=item pending

A declared C<pending> refusal came, and met the convention.

=item fail

Anything else: a wrong result, an unexpected or malformed exception, a stale
refusal, a failed cleanup, a diff that is not empty.

=item deviation

A declared C<deviation> showed, as declared. Carries C<reason>.

=item todo

Would be C<fail>, for a case newer than L</conformance_answered_through>
outside C<AUTHOR_TESTING> and C<RELEASE_TESTING>.

=item na

A Names case of a kind the driver does not declare (L</Names>), or a deploy
case of the Diff list for a driver without L</conformance_deploy>.

=back

C<only> restricts the run to the named cases.

=head2 summary_line

  my $line = $class->summary_line(\@results);

The one line that closes a run: a refused area once (area, kind, the reason of a
server one, and the number of its cases), the
other pending refusals, the deviations with their reasons, and
the cases still newer than the answered table version. A case is named only
where it was refused by itself (L</conformance_refusals>), never once per case
of a refused area. C<undef> when there is nothing to say.

=head2 run

  DBIO::Foo::Test::Conformance->run('DDL');

Write the tests: first one for the declarations (L</check_declarations>),
then, when L</conformance_live_available>, one per case; a C<todo> case runs
as a C<TODO> test. The closing summary line is printed with C<diag>. Without a
server only the declarations are checked and the number of cases not run is
said. Does not call C<done_testing>.

=head2 expectation_kinds

  my @kinds = DBIO::Test::Conformance->expectation_kinds;

The expectation kinds a case may use, sorted.

=head1 WRITING A DRIVER'S CLASS

Name it C<DBIO::E<lt>DriverE<gt>::Test::Conformance> and keep it under
F<lib/>, so an extension dist can reuse it. Every method is a class method.

Seams that B<must> be provided (the base dies naming the seam and the class):

=over 4

=item conformance_live_available

True when there is a server to run against: the driver's C<DBIO_TEST_*>
variables, and its DBD present. A driver with no server to gate on (an
in-memory SQLite) answers true.

=item conformance_connect($schema_class)

C<$schema_class> is a fresh L<DBIO::Schema> subclass with the case's result
classes registered. Load the driver component into it, connect, and return the
connected schema. Never connect the class twice; every case gets its own.

=item conformance_install($schema, $case)

Install the case's declaration through the driver's public entry point
(C<< $schema->deploy >>, or what the driver's deploy class exposes). Throw the
driver's refusal from here when the driver cannot do the case. C<$case> is the
case hash, for a driver that needs its name.

=item conformance_cleanup($schema, $case, $namespace)

Remove what the case created, and disconnect. C<$namespace> is the mark
L</conformance_namespace> returned; remove only what that mark identifies,
and nothing when it identifies nothing. Runs after every case that got its
namespace, also after a failure of the install or a check; it is not called
when L</conformance_namespace> threw (the runner closes the connection then).

=item conformance_fact($schema, $name, \%args)

Measure one fact the server shows, through the driver's Introspect, and return
it. The vocabulary is under L</Facts>. C<%args> carries what the case named
(C<source>, C<column>, C<columns>, C<namespace>, ...) and C<table>, the table
name the source was declared with. An unknown fact name is the driver's
programming error and throws.

=item conformance_diff_is_empty($schema, $case)

True when a diff of the installed database against the same declaration is
empty. It is asked after every case that otherwise passed (the postcondition
"install, then diff against the same declaration, is empty") unless the driver
declares the Diff area refused (L</conformance_refused_areas>). It is asked
after the upgrade of a Diff case as well (postcondition 2), of the schema
L</conformance_upgrade> returned, and is not asked of a Bind case.

=item conformance_upgrade($schema, $to_class, $case)

Needed to run the Diff list. C<$schema> is the connected schema of the C<from>
declaration, installed, with the case's rows in it. C<$to_class> is a fresh
L<DBIO::Schema> subclass with the result classes of the C<to> declaration
registered and not connected (the view definitions in it are resolved).
Connect it to the same database -- load the driver component into it as
L</conformance_connect> does, and where the engine's database is the
connection (an in-memory SQLite) share the handle -- run the upgrade through
the driver's public entry point (C<upgrade> of the deploy class) and return the
connected schema of C<$to_class>. Throw the driver's refusal from here when the
driver cannot do the case. The runner checks the expectations and the diff
postcondition against the returned schema, hands it to
L</conformance_cleanup>, and closes C<$schema> itself afterwards; so cleanup
must not close a handle the other schema still needs, but may close its own.

=item conformance_deploy($schema, $to_class, $case)

Optional, for the deploy cases of the Diff list (C<diff-deploy-*>, table
version 4). Same arguments and same connecting as L</conformance_upgrade>, but
instead of upgrading, return the driver's deploy object over the connected
target schema: C<< DBIO::Foo::Deploy->new(schema => $to) >> (a
L<DBIO::Deploy::Base>; the runner reads the schema from its C<schema>). The
default returns C<undef>: the deploy cases are then C<na> for the driver. The
runner calls C<apply> and C<upgrade> on the object and checks the database
through the facts; it needs nothing else from the driver.

=back

Seams with a working default:

=over 4

=item conformance_namespace($schema, $case)

Give the case an empty namespace -- a schema on PostgreSQL, a database on
MySQL, a table-name prefix where the engine has nothing else -- and return a
mark for L</conformance_cleanup>, which removes only what that mark
identifies. Throw when no empty namespace can be had (the database or schema
is not empty): the case is then reported as failed and
L</conformance_cleanup> is not called. Default: none, returns C<undef>. Necessary
whenever a diff compares the whole visible database, so that nothing another
case left behind comes back as a C<DROP>.

=item conformance_quote_ident($schema, $name)

Return C<$name> quoted the way this driver writes an identifier into SQL. The
runner builds the definition of a view from identifiers it quotes through this
hook, because a view definition is SQL of the user, which the driver does not
rewrite. Default: the quoting rule of the connected storage -- the
C<quote_char> of its SQL maker (one character, or an opening and a closing
one); without a C<quote_char> the name stays as it is.

=item conformance_create($schema, $source, \%values)

C<< create >> a row of C<$source> through the ResultSet API, read it back
fresh from the server, and return the columns as a hashref.

=item conformance_count($schema, $source, \%condition)

The number of rows of C<$source> matching C<%condition>.

=item conformance_delete($schema, $source, \%condition)

Delete the matching rows with one C<DELETE>, leaving cascades to the server.

=item conformance_find($schema, $source, \%condition)

The first row of C<$source> matching C<%condition>, read fresh from the
server, as a hashref of its columns; C<undef> when none matches.

=item conformance_update($schema, $source, \%condition, \%set)

Update the matching rows with one C<UPDATE>. C<%set> is the caller's hash, not
a copy: the runner checks that it still holds the values afterwards.

=item conformance_populate($schema, $source, \@rows)

Insert the rows (hash refs with the same keys), the way C<populate> does in
void context. C<@rows> is the caller's array; the runner checks that it still
holds the values afterwards.

=item conformance_refusals

The hashref of declared refusals, default C<{}>. See L</Declaring refusals>.

=item conformance_refused_areas

The hashref of areas the driver does not do at all, default C<{}>. C<Diff> and
C<Bind> are known: a driver without a Diff declares

  sub conformance_refused_areas {{
    Diff => { kind => 'pending', reason => qr/diff is not built yet/ },
  }}

and the diff postcondition of the DDL list is then not asked of it. The
declaration is checked like any other (L</check_declarations>).

The runner treats every case of the refused area as a declared refusal of that
kind and reason, unless the case has a refusal of its own: the
case is driven, the driver's seam has to throw a refusal that meets L</The
refusal convention> (stem C<refus>, the table of the case's C<subject>, the
reason), and the result is C<refused> or C<pending>. A case of the area that
runs through is a stale refusal and fails. The area is a refusal, never a
deviation.

=item conformance_answered_through

The table version (L</table_version>) the driver's answers were written
against. Default C<0>: a driver that does not declare it has answered nothing,
and every case counts as newer.

A scalar is the version of the DDL list and says nothing about the others,
which then count as 0. A hash ref gives it per area:

  sub conformance_answered_through { { DDL => 1, Diff => 1 } }

An area the hash does not name is 0. A driver that answers a list of an area
for which it is at 0 stays green outside C<AUTHOR_TESTING> and
C<RELEASE_TESTING>, the cases running as C<TODO>. See L</New cases and
released drivers>.

=back

=head2 Names

A schema name (the connect key C<schema>), the name of a database extension
and the name of a library an extension loads are identifiers (ADR 0077). The
driver writes one into a statement only through its identifier quoting or a
bind, or refuses it. The Names list drives each kind with a plain name and
with five names a statement built by concatenation cannot take. There are two
answers, neither declared:

=over 4

=item set

The server shows the name as given: C<conformance_apply_name> returns it as
introspection reads it back.

=item refused

The driver throws a L<DBIO::Exception> (the check core makes of C<;>, a line
break, CR and NUL counts: the driver need not repeat it). Status C<refused>.

=back

An error of the server (L<DBIO::Exception::Server>: a syntax error), another
name than the one given and an exception that is not a DBIO exception are
failures.

The driver declares the kinds its engine has with C<conformance_name_kinds>
(C<schema>, C<extension>, C<library>); a case of a kind it does not declare has
status C<na> and is green. This is the capability, not a skip of a case.
C<conformance_apply_name($kind, $name)> does the whole of one case: connects a
fresh connection with the connect key (schema), declares the extension or
activates the library, reads the name back through introspection, removes
what it created, disconnects, and returns the name read back. A refusal
declaration (L</Declaring refusals>) does not exist for this list; a refusal is
an answer.

=head2 Declaring refusals

C<conformance_refusals> returns a hashref keyed by case name:

  { case_name => { kind => 'server' | 'pending', reason => qr/.../ } }
  { case_name => { kind => 'deviation', fact => qr/.../, reason => 'why' } }

=over 4

=item kind C<server>

The engine cannot do it. Permanent.

=item kind C<pending>

The driver does not do it yet. The C<reason> says why. That line separates
"not built" from "does not exist on this server".

=item reason

For a refusal, a regex the refusal's message must match.

=item kind C<deviation>

The engine answers the case's expectation differently, permanently, and the
driver accepts that. The case runs to the end without throwing and its
expectation fails; the declaration says how:

=over 4

=item fact

A regex the failure text of the run must match. It is the statement of what
the server does, in the words of the runner's own failure message, so a
different wrong result is not hidden behind the declaration.

=item reason

A non-empty string: why the deviation is accepted. A deviation without one is
rejected by L</check_declarations>.

=back

An exception is not a deviation, and a case that runs correctly under a
declared deviation fails as a stale deviation. A refused area is never a
deviation.

=back

C<pending> is green. The run ends with one line, per refusal and its kind,
printed by L</run> and returned by L</summary_line>:

  3 pending refusals: ddl-foreign-key, ddl-fk-actions, ...

A refused area (L</conformance_refused_areas>) is one entry, not one per case:

  Diff area pending: 20 cases

and, for a server-kind area, C<Diff area refused by the server (reason): 20 cases>.
A case is named in the line only where it carries a refusal of its own.

and, for deviations, with their reasons:

  1 deviation: ddl-type-size-char (the engine keeps the declared length but does not enforce it)

=head2 The refusal convention

A refusal is a DBIO exception, thrown through C<< $schema->throw_exception >>
(or C<< DBIO::Exception->throw >>) by the driver itself -- before the server
is asked. Its text

=over 4

=item *

contains the stem C<refus> (case-insensitive: refuses, refused, refusal),

=item *

names the table, as the case declared it, and, when the case has a column
(C<subject> of the case), the column -- exactly: the column's name stands in
the text as a whole identifier, so C<id> is not named by C<user_id>,

=item *

matches the declared C<reason>.

=back

It is not a L<DBIO::Exception::Server> and not a bare string: a server error
that reaches the caller is the server's decision, a refusal is the driver's.
The runner checks exactly these and names the part that is missing.

=head2 New cases and released drivers

Every case carries C<since>, the table version of its list that added it. A
case with C<since> greater than L</conformance_answered_through> for its area
is still driven and
reported, but a failure of it only turns the suite red under
C<AUTHOR_TESTING> or C<RELEASE_TESTING>; otherwise it runs as a C<TODO> and
the summary line counts it. A driver raises the number when its answers are
complete, deliberately, in the same change.

=head1 CASES

A case is a hash (see L<DBIO::Test::Conformance::Cases::DDL>):

  { name, since, subject, input => { sources => [ ... ] }, expect => [ ... ] }

The input of a Diff case has two declarations and rows
(L<DBIO::Test::Conformance::Cases::Diff>):

  input => {
    from => { sources => [ ... ] },
    to   => { sources => [ ... ] },
    rows => [ { source => 'Parent', values => { id => 1 } }, ... ],
  }

C<from> and C<to> are sources as below. The runner installs C<from>, creates
C<rows> in order through L</conformance_create>, has the driver upgrade to
C<to> (L</conformance_upgrade>) and checks C<expect> against the database as it
is then. The input of a Bind case is a DDL input
(L<DBIO::Test::Conformance::Cases::Bind>).

=head2 Input

C<< input->{sources} >> is a list of sources in declaration order. A source:

  {
    name          => 'Child',                       # the moniker
    table         => 'child',
    columns       => [ id => { data_type => 'integer' }, ... ],   # ordered pairs
    primary_key   => [ 'id' ],                      # optional
    unique        => [ [ constraint_name => [ 'a', 'b' ] ], ... ],
    relationships => [ { type => 'belongs_to', name => 'parent',
                         source => 'Parent', cond => 'parent_id',
                         attrs => { on_delete => 'CASCADE' } }, ... ],
    indexes       => [ { name => 'idx', columns => [ ... ], unique => 0 }, ... ],
    view          => { definition => 'SELECT ...', virtual => 0 },   # makes it a view
  }

In the definition of a view, every C<{{name}}> is an identifier: the runner
replaces it, after the connect, by C<name> quoted through
L</conformance_quote_ident> (C<SELECT {{id}} FROM {{base}}>).

Column definitions use the base types of L<DBIO::Schema::Type>, and C<varchar>
with a C<size> for a bounded string, which every driver writes. C<source> in a
relationship is the moniker of another source of the case. The runner builds
these as result classes in a package of its own; the case never contains SQL.

=head2 Expectations

Every entry of C<expect> is a hash with one key, the kind. The expectation is
what the server shows, never a piece of SQL text.

=over 4

=item read_back

  { read_back => { source => 'Note', create => { id => 1 },
                   is => { note => "it's" }, isnt => { ... }, like => { ... } } }

Create the row, read it fresh from the server, compare the named columns:
C<is> by C<eq> (C<undef> means NULL), C<isnt> by C<ne>, C<like> by regex.

=item rejects

  { rejects => { source => 'Pair', first => { ... }, create => { ... } } }

C<first> (optional) is created and must succeed; then C<create> must be
rejected by the server. Accepting it is a failure.

=item search_by

  { search_by => { source => 'Order', create => { ... },
                   through => 'View', column => 'group', value => 'h' } }

Create the row in C<source>, then exactly one row must be found by
C<column = value> in C<through> (default C<source>).

=item auto_key

  { auto_key => { source => 'Counter', create => { name => 'x' } } }

Create without the primary key; the row read back has every key column set.

=item cascade_delete

  { cascade_delete => { parent => 'Parent', parent_values => { id => 1 },
                        child => 'Child', child_values => { id => 1 },
                        link => { parent_id => 'id' } } }

Create the parent and a child whose C<link> columns point at it (child column
=E<gt> parent column), delete the parent, and the child must be gone.

=item fact

  { fact => { name => 'column_size', source => 'Sized', column => 'c', is => 10 } }

A fact read through the driver's Introspect (L</conformance_fact>) must equal
C<is>: strings by C<eq>, array refs elementwise, C<undef> for "not there".
A fact about a source the upgrade dropped (C<source> is the moniker of the
C<from> declaration, which the upgraded schema no longer knows) carries the
table name the case declared as C<table>.

=item rows_kept

  { rows_kept => { source => 'Base', find => { id => 1 }, is => { name => 'x' } } }

For a Diff case: a row loaded before the upgrade is still there. The row
matching C<find> is read fresh (L</conformance_find>); it must exist and the
named columns must equal C<is> (C<undef> means NULL). Without C<is> only its
existence is checked.

=item count

  { count => { source => 'Base', where => { name => 'x' }, is => 1 } }

The number of rows of C<source> matching C<where> (all when absent) is C<is>.

=item bind_roundtrip

  { bind_roundtrip => { source => 'Val', column => 'v',
                        values => [ '01234', '007' ],
                        ops => [ qw(create find search update populate) ] } }

For a Bind case, each of C<values> goes through C<column> (the other columns
of the source must be nullable; the key is the first primary key column, which
the runner fills) by each operation of C<ops>, in order, and must come back
exactly as written (C<eq>, bytes for bytes; a failure says where the first
difference is). Every operation goes through a data seam:

=over 4

=item create

C<create> a row holding the value (L</conformance_create>); the row read back
holds it.

=item find

The row found by the value (L</conformance_find>) holds it.

=item search

Exactly as many rows are found by the value (L</conformance_count>) as rows
hold it at that point: the ones C<create>, C<update> and C<populate> made.

=item update

C<create> a row with the column NULL, C<update> it to the value
(L</conformance_update>), read it back by its key.

=item populate

C<populate> a row holding the value (L</conformance_populate>), read it back
by its key.

=item int_first

A statement that binds an integer (a count by key 0) runs before the next
operation, for the faults where an earlier bind decides the next one's type.

=back

=item bind_lob_ops

  { bind_lob_ops => { source => 'Doc', column => 'body',
                      label_column => 'label', value => $bytes } }

For a Bind case with a LOB column, the key an auto-increment: C<create({})>
leaves the LOB NULL; an update of the LOB alone stores C<value> and the hash
the caller passed still holds it, not a placeholder; a C<populate> of three rows
mixing NULL and the value stores each as given and leaves the caller's rows
holding what they held. C<label_column> is a text column the rows are found by.

=item bind_literal

  { bind_literal => { source => 'Note', column => 'txt', create => { id => 1, txt => 'x' },
                      value => 'x', other => 'y',
                      literal => q{{{txt}} = ? AND 'a?b' = 'a?b' /* a ? */} } }

For a Bind case: create the row, then count with literal SQL
C<< \[ $literal, $bind ] >> as the condition. The bind C<value> finds one row
and C<other> none, whatever C<?> the literal holds in a string or a comment.
C<{{name}}> in the literal is an identifier, quoted through
L</conformance_quote_ident>.

=back

=head2 Facts

=over 4

=item object_kind

C<source>. C<'table'>, C<'view'>, or C<undef> when the server holds no such
object.

=item table_name

C<source>. The table name as Introspect reads it back, exactly (case, spaces,
quote characters), C<undef> when absent.

=item table_in_namespace

C<source>, C<namespace>, C<unqualified>. 1 when the table C<unqualified> is in namespace
C<namespace>, else 0.

=item column_names

C<source>. The column names the server holds, as an array ref; the runner
sorts both sides.

=item column_size

C<source>, C<column>. The declared size of the column.

=item column_auto_increment

C<source>, C<column>. 1 or 0.

=item primary_key_columns

C<source>. The primary key's columns as an array ref, C<[]> for none.

=item unique_exists

C<source>, C<columns>. 1 when a unique constraint over exactly these columns
exists, else 0.

=item foreign_key_count

C<source>. The number of foreign key constraints of the table.

=item index_count

C<source>, C<columns>. The number of indexes (the primary key excluded) over
exactly these columns; the one backing a unique constraint or a foreign key
counts, so a duplicate shows as 2.

=back

The diff postcondition is not an expectation and is not written into a case:
it holds for every DDL case (install, then diff against the same declaration,
is empty) and every Diff case (upgrade, then diff against the target
declaration, is empty), wherever the driver has a Diff.

=head1 Running a list over an async transport

An async transport (C<DBIO::Async>, the C<ev> dists) runs the Bind list over
its own bind path (ADR 0060, decision 7). It does so with the same lists and the
same runner: every operation a Bind case performs on data goes through one of
the data seams, and nothing else of the database is touched.

  seam                      the operation
  conformance_create        create a row, read it back
  conformance_find          the first row matching a condition, or undef
  conformance_count         the number of rows matching a condition
  conformance_update        update the matching rows
  conformance_populate      insert a list of rows
  conformance_delete        delete the matching rows

Each has a default over the synchronous ResultSet API. A transport's subclass
overrides L</conformance_connect> to connect through the transport and these
seams to issue the operation through it and wait for the Future in the seam,
returning what the synchronous default returns:

  package DBIO::PostgreSQL::EV::Test::Conformance;
  use base 'DBIO::PostgreSQL::Test::Conformance';

  sub conformance_create {
    my ($class, $schema, $source, $values) = @_;
    return $class->_wait($schema->resultset($source)->create_async({ %$values }));
  }
  # ... conformance_find, _count, _update, _populate likewise

The install, namespace, fact and diff seams stay the driver's own and run on
the blocking connection of the same driver; the Bind list asks no fact and no
diff. A value must reach the server by the transport's bind path or the case
fails; there is nothing in the runner to bypass it.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
