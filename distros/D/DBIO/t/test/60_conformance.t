use strict;
use warnings;

use Test::More;

# DBIO::Test::Conformance (ADR 0060, karr k330): the runner and the DDL case
# table, tested without any driver and without any database.
#
# The "server" below is a few dozen lines of Perl behind the runner's seams.
# It answers every case of the DDL list correctly; a scenario then bends one
# thing -- a quirk, a declared refusal, the answered-through number -- and
# asserts which of the five answers the runner reports.

use DBIO::Test::Conformance;
use DBIO::Test::Conformance::Cases::DDL;
use DBIO::Exception;
use DBIO::Exception::Server;
use DBIO::Test::Storage;

# ---------------------------------------------------------------- the server

{
  package MockConf;
  use base 'DBIO::Test::Conformance';

  our (%DB, %QUIRK, %REFUSALS, %AREAS, $THROUGH, $FACT_CALLS);

  sub reset_state {
    %DB = (); %QUIRK = (); %REFUSALS = (); %AREAS = (); $THROUGH = 2;
    $FACT_CALLS = 0;
  }

  sub conformance_live_available { 1 }
  sub conformance_refusals { \%REFUSALS }
  sub conformance_refused_areas { \%AREAS }
  sub conformance_answered_through { $THROUGH }

  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->storage_type('DBIO::Test::Storage');
    return $schema_class->connect(sub { });
  }

  sub conformance_install {
    my ($class, $schema, $case) = @_;
    if (my $t = $QUIRK{throw}{ $case->{name} }) {
      $t->($schema, $case);
    }
    for my $moniker ($schema->sources) {
      my $src = $schema->source($moniker);
      next if $src->can('is_virtual') && $src->is_virtual;
      $DB{ $src->name } = {
        kind => ($src->isa('DBIO::ResultSource::View') ? 'view' : 'table'),
        src  => $src,
        rows => [],
        seq  => 0,
      };
    }
  }

  sub conformance_cleanup { %DB = () }
  sub conformance_diff_is_empty { $QUIRK{diff_nonempty} ? 0 : 1 }

  sub _fks {
    my ($src) = @_;
    my %seen;
    for my $rel ($src->relationships) {
      my $info = $src->relationship_info($rel);
      next unless $info->{attrs}{is_foreign_key_constraint};
      my ($fk) = map { s/^self\.//r } values %{ $info->{cond} };
      $seen{ $info->{source} . '/' . $fk } ||= { rel => $rel, info => $info, column => $fk };
    }
    return values %seen;
  }

  sub conformance_create {
    my ($class, $schema, $moniker, $vals) = @_;
    my $src = $schema->source($moniker);
    my $t   = $DB{ $src->name }
      or die "no such table " . $src->name . "\n";
    die "cannot insert into a view\n" if $t->{kind} eq 'view';
    my $info = $src->columns_info;
    my %row;
    for my $c ($src->columns) {
      my $i = $info->{$c};
      if (exists $vals->{$c})              { $row{$c} = $vals->{$c} }
      elsif (exists $i->{default_value}) {
        my $d = $i->{default_value};
        if (ref $d) { $d = '2026-01-01 00:00:00' }
        elsif ($QUIRK{double_apostrophe}) { $d =~ s/'/''/g }
        $row{$c} = $d;
      }
      elsif ($i->{is_auto_increment})      { $row{$c} = ++$t->{seq} }
      else                                 { $row{$c} = undef }
      die "value too long for column $c\n"
        if !$QUIRK{no_length_check} and defined $row{$c} and !ref $i->{size} and defined $i->{size}
           and $i->{data_type} =~ /char/ and length $row{$c} > $i->{size};
    }
    my %uc = $src->unique_constraints;
    for my $name (sort keys %uc) {
      my @cols = @{ $uc{$name} };
      next if grep { !defined $row{$_} } @cols;
      for my $other (@{ $t->{rows} }) {
        die "unique constraint $name violated\n"
          unless grep { ($other->{$_} // '') ne $row{$_} } @cols;
      }
    }
    for my $fk (_fks($src)) {
      next unless defined $row{ $fk->{column} };
      my $parent = $schema->source($fk->{info}{source});
      my ($pcol) = map { s/^foreign\.//r } keys %{ $fk->{info}{cond} };
      die "foreign key violated\n"
        unless grep { $_->{$pcol} eq $row{ $fk->{column} } }
               @{ $DB{ $parent->name }{rows} };
    }
    push @{ $t->{rows} }, { %row };
    return { %row };
  }

  sub _rows_of {
    my ($schema, $moniker) = @_;
    my $src = $schema->source($moniker);
    my $t = $DB{ $src->name } or die "no such table\n";
    return @{ $t->{rows} } unless $t->{kind} eq 'view';
    my ($base) = $src->view_definition =~ /\bFROM\s+"?(\w+)"?/i;
    return @{ $DB{$base}{rows} };
  }

  sub conformance_count {
    my ($class, $schema, $moniker, $cond) = @_;
    return undef if $QUIRK{count_undef};
    my @rows = _rows_of($schema, $moniker);
    for my $c (keys %$cond) {
      @rows = grep { ($_->{$c} // '') eq $cond->{$c} } @rows;
    }
    return scalar @rows;
  }

  sub conformance_delete {
    my ($class, $schema, $moniker, $cond) = @_;
    my $src = $schema->source($moniker);
    my $t = $DB{ $src->name };
    my @gone;
    my @keep;
    for my $r (@{ $t->{rows} }) {
      (grep { ($r->{$_} // '') ne $cond->{$_} } keys %$cond) ? push(@keep, $r) : push(@gone, $r);
    }
    $t->{rows} = \@keep;
    for my $m ($schema->sources) {
      my $child = $schema->source($m);
      for my $fk (_fks($child)) {
        next unless $schema->source($fk->{info}{source})->name eq $src->name;
        next unless ($fk->{info}{attrs}{on_delete} // '') =~ /cascade/i;
        my ($pcol) = map { s/^foreign\.//r } keys %{ $fk->{info}{cond} };
        my %dead = map { $_->{$pcol} => 1 } @gone;
        my $ct = $DB{ $child->name };
        $ct->{rows} = [ grep { !$dead{ $_->{ $fk->{column} } // '' } } @{ $ct->{rows} } ];
      }
    }
    return scalar @gone;
  }

  sub conformance_fact {
    my ($class, $schema, $name, $args) = @_;
    $FACT_CALLS++;
    my $src = $schema->source($args->{source});
    my $t   = $DB{ $src->name };
    my $info = $src->columns_info;
    return $t ? $t->{kind} : undef                     if $name eq 'object_kind';
    return $info->{ $args->{column} }{size}            if $name eq 'column_size';
    return [ $src->columns ]                           if $name eq 'column_names';
    return $info->{ $args->{column} }{is_auto_increment} ? 1 : 0
                                                       if $name eq 'column_auto_increment';
    return [ $src->primary_columns ]                   if $name eq 'primary_key_columns';
    return $t ? $src->name : undef                     if $name eq 'table_name';
    return $t ? 1 : 0                                  if $name eq 'table_in_namespace';
    return scalar(my @f = _fks($src))                  if $name eq 'foreign_key_count';
    my $want = join ',', @{ $args->{columns} || [] };
    if ($name eq 'unique_exists') {
      my %uc = $src->unique_constraints;
      return (grep { join(',', @$_) eq $want } values %uc) ? 1 : 0;
    }
    if ($name eq 'index_count') {
      my %sets;
      my %uc = $src->unique_constraints;
      $sets{ join ',', @$_ } = 1 for values %uc;
      $sets{ join ',', @{ $_->{columns} } } = 1 for $src->index_declarations;
      $sets{ $_->{column} } = 1 for _fks($src);
      return $sets{$want} ? 1 : 0;
    }
    die "mock does not know fact $name\n";
  }
}

# a server that leaves the data operations to the runner's defaults, over the
# fake storage: what the default seams send is what the storage captures
{
  package MockDefaultOps;
  use base 'DBIO::Test::Conformance';
  sub conformance_live_available { 1 }
  sub conformance_connect {
    my ($class, $schema_class) = @_;
    $schema_class->storage_type('DBIO::Test::Storage');
    my $schema = $schema_class->connect(sub { });
    my $st = $schema->storage;
    $st->mock_persistent(qr/^SELECT\s+me\.id/i, [[1, 'u', 'g', 'e']]);
    $st->mock_persistent(qr/COUNT/i, [[1]]);
    return $schema;
  }
  sub conformance_install { }
  sub conformance_cleanup { }
  sub conformance_diff_is_empty { 1 }
}

# ------------------------------------------------------------ the case table

my $cases = DBIO::Test::Conformance::Cases::DDL->cases;
is scalar(@$cases), 20, q{the DDL list holds the 20 shared cases (D1..D19, D15 as two)};
is(DBIO::Test::Conformance->table_version, 2, q{table version 2});
is_deeply [ map { $_->{name} } grep { $_->{since} == 2 } @$cases ],
  [qw(ddl-type-size-char ddl-type-size-bit)], q{version 2 added the two size cases that replace ddl-type-size-passthrough};

{
  my %seen;
  my @bad;
  for my $c (@$cases) {
    push @bad, "$c->{name}: not ddl-kebab-case"
      unless $c->{name} =~ /^ddl-[a-z0-9]+(?:-[a-z0-9]+)*$/;
    push @bad, "$c->{name}: duplicate" if $seen{ $c->{name} }++;
    push @bad, "$c->{name}: since is not a positive integer"
      unless ($c->{since} // '') =~ /^[1-9][0-9]*$/;
    push @bad, "$c->{name}: since is newer than the table version"
      if ($c->{since} // 0) > DBIO::Test::Conformance->table_version;
    push @bad, "$c->{name}: no expect"
      unless ref $c->{expect} eq 'ARRAY' && @{ $c->{expect} };
    push @bad, "$c->{name}: no input sources"
      unless ref $c->{input}{sources} eq 'ARRAY' && @{ $c->{input}{sources} };
    push @bad, "$c->{name}: no cards" unless ref $c->{cards} eq 'ARRAY';
    push @bad, "$c->{name}: an expect entry is not a one-key hash"
      if grep { ref $_ ne 'HASH' or keys(%$_) != 1 } @{ $c->{expect} || [] };
  }
  is_deeply \@bad, [], 'every case is well formed';
}

{
  my @names = map { $_->{name} } @$cases;
  is_deeply \@names, [qw(
    ddl-default-string-apostrophe ddl-default-digit-string
    ddl-default-expression ddl-enum-value-apostrophe
    ddl-ident-reserved-word ddl-ident-mixed-case ddl-ident-special-chars
    ddl-view-declared ddl-unique-constraint ddl-foreign-key
    ddl-fk-actions ddl-fk-two-rels-one-column ddl-fk-table-order
    ddl-auto-increment ddl-type-size-char ddl-type-size-bit ddl-base-types-roundtrip
    ddl-index-on-unique-columns ddl-qualified-source-name
    ddl-unique-not-null-without-pk
  )], 'D1..D19 in the order of the ADR appendix (D15 as two cases)';
}

# the table is handed out as a copy: a caller cannot damage the next run
{
  my $a = DBIO::Test::Conformance::Cases::DDL->cases;
  $a->[0]{name} = 'tampered';
  is(DBIO::Test::Conformance::Cases::DDL->cases->[0]{name}, 'ddl-default-string-apostrophe', 'cases() hands out a copy');
}

# ------------------------------------------------------- seams without a driver

for my $seam (qw(
  conformance_live_available conformance_connect conformance_install
  conformance_cleanup conformance_fact conformance_diff_is_empty
)) {
  my $err = eval { DBIO::Test::Conformance->$seam(undef, undef, undef); 1 } ? '' : "$@";
  like $err, qr/\Q$seam\E.*must be provided by the driver/s,
    "$seam dies naming itself until a driver provides it";
}

is(DBIO::Test::Conformance->conformance_namespace(undef, {}), undef, 'no namespace by default');
is_deeply(DBIO::Test::Conformance->conformance_refusals, {}, 'no refusals by default');
is(DBIO::Test::Conformance->conformance_answered_through, 0, 'answered through 0 when the driver does not declare it');

# ------------------------------------------------------------- the five answers

sub statuses {
  my (%o) = @_;
  my @r = MockConf->results('DDL', %o);
  return { map { $_->{case} => $_ } @r };
}

{
  local $ENV{AUTHOR_TESTING} = 1;
  local $ENV{RELEASE_TESTING} = 1;
  MockConf::reset_state();

  my @r = MockConf->results('DDL');
  is scalar(@r), 20, q{one result per case};;
  is_deeply [ grep { $_->{status} ne 'pass' } @r ], [],
    'the correct mock answers every case correctly'
    or diag join "\n", map { "$_->{case}: $_->{status}: $_->{message}" }
                       grep { $_->{status} ne 'pass' } @r;
  is $MockConf::FACT_CALLS > 0, 1, 'facts were measured through the seam';
  is scalar(grep { ref $_ ne 'HASH' } @r), 0, 'results are plain hashes';
  is_deeply [ sort keys %{ $r[0] } ], [qw(case message status)],
    'a result carries case, status, message';
}

# wrong: the server silently answers differently
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::QUIRK{double_apostrophe} = 1;
  my $s = statuses(only => ['ddl-default-string-apostrophe', 'ddl-default-digit-string']);
  is $s->{'ddl-default-string-apostrophe'}{status}, 'fail',
    'a silently wrong value is a failure';
  like $s->{'ddl-default-string-apostrophe'}{message}, qr/note/,
    'the failure names the column';
  like $s->{'ddl-default-string-apostrophe'}{message}, qr/it's/,
    'the failure shows the expected value';
  is $s->{'ddl-default-digit-string'}{status}, 'pass', 'the other case is unaffected';
}

# refusals
my $refuse = sub {
  my ($msg) = @_;
  return sub { $_[0]->throw_exception($msg) };
};
my $fk_case = 'ddl-foreign-key';

{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = { kind => 'server', reason => qr/no foreign keys on this engine/ };
  $MockConf::QUIRK{throw}{$fk_case} = $refuse->(
    "install refused for table 'child', column 'parent_id': no foreign keys on this engine"
  );
  my $s = statuses(only => [$fk_case]);
  is $s->{$fk_case}{status}, 'refused', 'a declared refusal that meets the convention is refused'
    or diag $s->{$fk_case}{message};

  # the same answer undeclared is a failure: it is not "also fine"
  %MockConf::REFUSALS = ();
  $s = statuses(only => [$fk_case]);
  is $s->{$fk_case}{status}, 'fail', 'a refusal nobody declared is a failure';
  like $s->{$fk_case}{message}, qr/undeclared|not declared|unexpected/i, '... and says so';
}

# the convention, piece by piece
{
  local $ENV{AUTHOR_TESTING} = 1;
  my %broken = (
    'no stem'       => [ qr/refus/i,
      "install of table 'child' column 'parent_id' failed: no foreign keys on this engine" ],
    'no table'      => [ qr/table name|names the table|table/i,
      "install refused: column 'parent_id' has no foreign keys on this engine" ],
    'no column'     => [ qr/column/i,
      "install refused for table 'child': no foreign keys on this engine" ],
    q{column only as substring} => [ qr/does not name the column/,
      "install refused for table 'child', column 'grand_parent_id': no foreign keys on this engine" ],
    'wrong reason'  => [ qr/reason/i,
      "install refused for table 'child', column 'parent_id': something else entirely" ],
  );
  for my $label (sort keys %broken) {
    MockConf::reset_state();
    $MockConf::REFUSALS{$fk_case} = { kind => 'server', reason => qr/no foreign keys on this engine/ };
    $MockConf::QUIRK{throw}{$fk_case} = $refuse->($broken{$label}[1]);
    my $s = statuses(only => [$fk_case]);
    is $s->{$fk_case}{status}, 'fail', "refusal with $label is a failure";
    like $s->{$fk_case}{message}, $broken{$label}[0], "... the message says what is missing ($label)";
  }

  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = { kind => 'server', reason => qr/./ };
  $MockConf::QUIRK{throw}{$fk_case} = sub {
    DBIO::Exception::Server->throw(
      message => "ERROR: refused for table 'child' column 'parent_id'",
      sqlstate => '42000',
    );
  };
  my $s = statuses(only => [$fk_case]);
  is $s->{$fk_case}{status}, 'fail', 'a server error handed through is not a refusal';
  like $s->{$fk_case}{message}, qr/server/i, '... and the message says it is the server';

  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = { kind => 'server', reason => qr/./ };
  $MockConf::QUIRK{throw}{$fk_case} = sub {
    die "refused for table 'child' column 'parent_id' (a bare string)\n";
  };
  $s = statuses(only => [$fk_case]);
  is $s->{$fk_case}{status}, 'fail', 'a bare string is not a DBIO exception';
  like $s->{$fk_case}{message}, qr/DBIO::Exception/, '... and the message says what was expected';
}

# stale refusal
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::REFUSALS{'ddl-unique-constraint'} = { kind => 'server', reason => qr/./ };
  my $s = statuses(only => ['ddl-unique-constraint']);
  is $s->{'ddl-unique-constraint'}{status}, 'fail', 'a refusal that succeeds fails';
  like $s->{'ddl-unique-constraint'}{message}, qr/stale refusal/, '... as a stale refusal';
}

# deviation: the third answer -- the server does something else, on the record
{
  local $ENV{AUTHOR_TESTING} = 1;
  my $case = q{ddl-type-size-char};
  my $dev = sub {
    return { kind => 'deviation',
             fact   => qr/accepted a row it must reject/,
             reason => 'the engine stores the declared length but does not enforce it',
             @_ };
  };

  MockConf::reset_state();
  $MockConf::QUIRK{no_length_check} = 1;
  my $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'fail', 'a wrong result nobody declared is a failure';

  $MockConf::REFUSALS{$case} = $dev->();
  is_deeply [ MockConf->check_declarations('DDL') ], [], 'a whole deviation declaration has no problems';
  $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'deviation', 'a declared deviation that happens is a deviation'
    or diag $s->{$case}{message};
  like $s->{$case}{message}, qr/accepted a row/, '... and carries what was observed';
  is $s->{$case}{reason}, 'the engine stores the declared length but does not enforce it',
    '... and its reason';
  like(MockConf->summary_line([ $s->{$case} ]), qr/1 deviation: \Q$case\E \(.*does not enforce/,
    'the summary line names the deviation and its reason');

  # stale: the case runs correctly now
  MockConf::reset_state();
  $MockConf::REFUSALS{$case} = $dev->();
  $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'fail', 'a deviation the case no longer shows is a failure';
  like $s->{$case}{message}, qr/stale deviation/, '... as a stale deviation';

  # a different wrong result is not the declared fact
  MockConf::reset_state();
  $MockConf::QUIRK{no_length_check} = 1;
  $MockConf::REFUSALS{$case} = $dev->(fact => qr/something else entirely/);
  $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'fail', 'a result that does not match the declared fact is a failure';
  like $s->{$case}{message}, qr/declared fact/, '... and says so';

  # an exception is not a deviation
  MockConf::reset_state();
  $MockConf::REFUSALS{$case} = $dev->();
  $MockConf::QUIRK{throw}{$case} = $refuse->("install refused for table 'sized', column 'c': no");
  $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'fail', 'an exception is not a deviation';

  # the declaration is checked
  MockConf::reset_state();
  $MockConf::REFUSALS{$case} = $dev->(reason => '');
  like join("\n", MockConf->check_declarations('DDL')), qr/\Q$case\E.*reason/s,
    'a deviation without a reason is rejected';
  $MockConf::REFUSALS{$case} = { kind => 'deviation', reason => 'because' };
  like join("\n", MockConf->check_declarations('DDL')), qr/\Q$case\E.*fact/s,
    'a deviation without a fact is rejected';
  $MockConf::REFUSALS{$case} = $dev->();
  delete $MockConf::REFUSALS{$case}{card};
  $MockConf::AREAS{Diff} = $dev->();
  like join("\n", MockConf->check_declarations('DDL')), qr/refused area Diff.*kind/s,
    'an area cannot be a deviation';

  # answered through counts it
  MockConf::reset_state();
  $MockConf::QUIRK{no_length_check} = 1;
  $MockConf::REFUSALS{$case} = $dev->();
  $MockConf::THROUGH = 2;
  $s = statuses(only => [$case]);
  is $s->{$case}{status}, 'deviation', 'a deviation answers the case: not a todo at answered_through';
}

# pending: green, with one summary line
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = {
    kind => 'pending', card => 'k34', reason => qr/not emitted yet/,
  };
  $MockConf::REFUSALS{'ddl-fk-actions'} = {
    kind => 'pending', card => 'k35', reason => qr/not emitted yet/,
  };
  for my $c ($fk_case, 'ddl-fk-actions') {
    $MockConf::QUIRK{throw}{$c} = $refuse->(
      $c eq $fk_case
        ? "foreign keys refused for table 'child', column 'parent_id': not emitted yet"
        : "foreign keys refused for table 'child', column 'parent_id': not emitted yet"
    );
  }
  my @r = MockConf->results(q(DDL), only => [$fk_case, q(ddl-fk-actions), q(ddl-unique-constraint)]);
  is_deeply [ map { $_->{status} } @r ], [qw(pass pending pending)],
    'pending refusals are their own status';
  is $r[1]{card}, q(k34), 'the result carries the card';
  is(MockConf->summary_line(\@r),
    '2 pending refusals: ddl-foreign-key (karr k34), ddl-fk-actions (karr k35)',
    'one summary line, case and card');
  is(MockConf->summary_line([ $r[0] ]), undef, 'no line when nothing is pending');
}

# answered through
{
  my $name = 'ddl-default-string-apostrophe';
  MockConf::reset_state();
  $MockConf::QUIRK{double_apostrophe} = 1;

  $MockConf::THROUGH = 0;
  {
    local $ENV{AUTHOR_TESTING}  = '';
    local $ENV{RELEASE_TESTING} = '';
    my $s = statuses(only => [$name]);
    is $s->{$name}{status}, 'todo', 'a case newer than answered_through is todo outside author testing';
    like $s->{$name}{message}, qr/note/, '... and still reports what is wrong';
    is(MockConf->summary_line([ $s->{$name} ]), '1 case newer than the answered table version: ' . $name,
      'the summary line counts it');
  }
  for my $var (qw(AUTHOR_TESTING RELEASE_TESTING)) {
    local $ENV{AUTHOR_TESTING}  = '';
    local $ENV{RELEASE_TESTING} = '';
    local $ENV{$var} = 1;
    is statuses(only => [$name])->{$name}{status}, 'fail', "... and fails under $var";
  }
  $MockConf::THROUGH = 1;
  {
    local $ENV{AUTHOR_TESTING}  = '';
    local $ENV{RELEASE_TESTING} = '';
    is statuses(only => [$name])->{$name}{status}, 'fail',
      'a case the driver answered through is red whatever the environment';
  }
}

# a driver that answered table version 1 meets the two size cases as todo
{
  my $case = 'ddl-type-size-char';
  MockConf::reset_state();
  $MockConf::QUIRK{no_length_check} = 1;
  $MockConf::THROUGH = 1;
  local $ENV{AUTHOR_TESTING}  = '';
  local $ENV{RELEASE_TESTING} = '';
  is statuses(only => [$case])->{$case}{status}, 'todo',
    'the size cases (since 2) are todo for a driver answered through 1';
  is statuses(only => ['ddl-type-size-bit'])->{'ddl-type-size-bit'}{status}, 'pass',
    'the bit case is its own case: the char quirk does not touch it';
}

# a retired case name is no case: a driver declaring it is told
{
  MockConf::reset_state();
  $MockConf::REFUSALS{'ddl-type-size-passthrough'} = { kind => 'server', reason => qr/./ };
  like join("\n", MockConf->check_declarations('DDL')),
    qr/ddl-type-size-passthrough.*unknown case/,
    'the replaced case name is unknown to check_declarations';
}

# Diff: postcondition, and a driver without one
{
  local $ENV{AUTHOR_TESTING} = 1;
  my $name = 'ddl-unique-constraint';
  MockConf::reset_state();
  $MockConf::QUIRK{diff_nonempty} = 1;
  my $s = statuses(only => [$name]);
  is $s->{$name}{status}, 'fail', 'install then diff must be empty, for every case';
  like $s->{$name}{message}, qr/diff/i, '... and the message says it is the diff';

  $MockConf::AREAS{Diff} = { kind => 'server', reason => qr/no diff/ };
  $s = statuses(only => [$name]);
  is $s->{$name}{status}, 'pass', 'a driver that refuses the Diff area is not asked for the postcondition';
}

# the answer table itself
{
  MockConf::reset_state();
  is_deeply [ MockConf->check_declarations('DDL') ], [], 'no declarations, no problems';

  $MockConf::REFUSALS{'ddl-no-such-case'} = { kind => 'server', reason => qr/x/ };
  $MockConf::REFUSALS{$fk_case}           = { kind => 'pending', reason => qr/x/ };
  $MockConf::REFUSALS{'ddl-fk-actions'}   = { kind => 'maybe', reason => qr/x/, card => 'k1' };
  $MockConf::REFUSALS{'ddl-auto-increment'} = { kind => 'server', reason => 'not a regex' };
  $MockConf::REFUSALS{'ddl-foreign-key-x'}  = 'not a hash';
  my $p = join "\n", MockConf->check_declarations('DDL');
  like $p, qr/ddl-no-such-case.*unknown case/s, 'a refusal naming no case is a problem';
  like $p, qr/ddl-foreign-key\b.*card/s, 'pending needs a card';
  like $p, qr/ddl-fk-actions.*kind/s, 'kind is server or pending';
  like $p, qr/ddl-auto-increment.*reason/s, 'reason is a regex';
  like $p, qr/ddl-foreign-key-x/, 'a refusal is a hash';

  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = { kind => 'pending', card => 'k34', reason => qr/x/ };
  $MockConf::AREAS{Diff} = { kind => 'pending', reason => qr/x/ };
  like join("\n", MockConf->check_declarations('DDL')), qr/refused area Diff.*card/s,
    'a refused area is checked the same way';
}

# a card on another board is Board#kNN; other shapes stay a problem
{
  for my $ok ('k34', 'dbio-mssql#k71', 'dbio-async#k7') {
    MockConf::reset_state();
    $MockConf::REFUSALS{$fk_case} = { kind => 'pending', card => $ok, reason => qr/x/ };
    is_deeply [ MockConf->check_declarations('DDL') ], [], "card '$ok' is accepted";
  }
  for my $bad ('', 'dbio-mssql#71', '#k5', 'k', 'dbio-mssql#k', '#k71', 'dbio mssql#k1') {
    MockConf::reset_state();
    $MockConf::REFUSALS{$fk_case} = { kind => 'pending', card => $bad, reason => qr/x/ };
    like join("\n", MockConf->check_declarations('DDL')), qr/card/, "card '$bad' is a problem";
  }
  MockConf::reset_state();
}

# run() writes tests: one per case, plus the declarations; all green here
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::REFUSALS{$fk_case} = { kind => 'pending', card => 'k34', reason => qr/not emitted/ };
  $MockConf::QUIRK{throw}{$fk_case} = $refuse->(
    "refused for table 'child', column 'parent_id': not emitted yet"
  );
  subtest 'run(DDL) over the mock' => sub {
    MockConf->run('DDL');
    done_testing;
  };
}

# a conformance_count that answers undef is a failed case with a reason, not a warning
{
  local $ENV{AUTHOR_TESTING} = 1;
  MockConf::reset_state();
  $MockConf::QUIRK{count_undef} = 1;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my $s = statuses(only => ['ddl-view-declared']);
  is $s->{'ddl-view-declared'}{status}, 'fail', 'a count that returns undef fails the case';
  like $s->{'ddl-view-declared'}{message}, qr/conformance_count returned undef for \w+/,
    '... and says which seam answered nothing';
  is_deeply \@warn, [], '... without a warning';
}

# the default data operations: INSERT then a fresh SELECT, a COUNT
{
  local $ENV{AUTHOR_TESTING} = 1;
  my @r = MockDefaultOps->results('DDL', only => ['ddl-ident-reserved-word']);
  is $r[0]{status}, 'pass', 'default create/count answer a read_back and a search_by over the fake storage'
    or diag $r[0]{message};
}

done_testing;
