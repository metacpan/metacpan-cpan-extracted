use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIO::PostgreSQL::DDL;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';

# A schema is bound to one driver, and the index declaration is per driver
# (karr core k333): install_ddl refuses, loudly and at once, what it would
# otherwise drop silently -- options, a type other than unique, an entry that
# carries only another driver's block, a key the pg block does not know.
# An own, empty pg block is the plain index of the columns.
subtest 'ddl-index-declaration-refusals' => sub {
  my $n = 0;
  my sub ddl_for {
    my ($decl, @extra) = @_;
    my $pkg = 'IdxRefuse' . ++$n;
    eval "package ${pkg}::Schema; use base q(DBIO::Schema); "
       . "package ${pkg}::Schema::Result::T; use base q(DBIO::Core); 1"
      or die $@;
    my $schema = "${pkg}::Schema";
    my $result = "${pkg}::Schema::Result::T";
    $schema->load_components('PostgreSQL');
    $result->load_components('PostgreSQL::Result');
    $result->table('t');
    $result->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'text' },
      kind => { data_type => 'text' },
    );
    $result->set_primary_key('id');
    $result->result_source_instance->add_index_declaration($decl);
    $schema->register_class(T => $result);
    return DBIO::PostgreSQL::DDL->install_ddl($schema);
  }

  # --- accepted
  like ddl_for({ name => 'i1', columns => ['name'], driver => { pg => {} } }),
    qr/^CREATE INDEX i1 ON t \(name\);$/m, 'an empty own pg block: the plain index';
  like ddl_for({ name => 'i2', columns => ['name'], type => 'unique' }),
    qr/^CREATE UNIQUE INDEX i2 ON t \(name\);$/m, 'type unique';
  like ddl_for({ name => 'i3', columns => ['name'], type => 'UNIQUE',
      driver => { sqlite => { where => 'x' }, pg => { using => 'hash' } } }),
    qr/^CREATE UNIQUE INDEX i3 ON t USING hash \(name\);$/m,
    'a pg block beside another driver is read';
  like ddl_for({ name => 'i4', columns => ['name'] }),
    qr/^CREATE INDEX i4 ON t \(name\);$/m, 'no driver block at all: the plain index';

  # --- refused
  throws_ok { ddl_for({ name => 'o1', columns => ['name'], options => { parser => 'ngram' } }) }
    qr/index 'o1'.*\boptions\b/s, 'options are refused';

  throws_ok { ddl_for({ name => 'ty', columns => ['kind'], type => 'fulltext' }) }
    qr/index 'ty'.*\btype\b.*fulltext/s, 'a type other than unique is refused';

  throws_ok { ddl_for({ name => 'lo', columns => ['name'],
      driver => { sqlite => { where => "kind = 'a'" } } }) }
    qr/index 'lo' carries only the 'sqlite' block and none for 'pg'/,
    'only a sqlite block is refused';

  throws_ok { ddl_for({ name => 'my', columns => ['name'], unique => 1,
      driver => { mysql => { using => 'hash' } } }) }
    qr/index 'my' carries only the 'mysql' block/, 'only a mysql block is refused';

  throws_ok { ddl_for({ name => 'bk', columns => ['name'],
      driver => { pg => { usng => 'gin' } } }) }
    qr/index 'bk': unknown key 'usng' in its 'pg' block/,
    'an unknown key in the pg block is refused';

  throws_ok { ddl_for({ name => 'wk', columns => ['name'],
      driver => { pg => { unique => 1 } } }) }
    qr/unknown key 'unique'/, 'unique is the entry\'s, not a pg key';
};

# What the install script takes from a declaration without being told whether
# it is a name or SQL (karr k120, point 9; maintainer's decision 2026-10-16,
# which replaces the one of 2026-10-12 for keys, using and opclasses):
#
#   pg_search_path entries   names -- checked by the quote_ident rule, $user
#                            the one entry that is no name; not written (the
#                            script no longer ends with SET search_path,
#                            karr k121)
#   pg_settings keys         names -- a dotted key is a dotted name, each part
#                            by the quote_ident rule, as the server's grammar
#                            reads it (var_name: ColId '.' ColId ...)
#   index using              SQL, written as given
#   index with               keys are storage parameter names (checked), values SQL as given
#   index opclasses          SQL, written as given
#
# One rule for both kinds of name: a name the user has put in double quotes
# already is refused, naming the unquoted form, rather than quoted a second
# time into another name. Nothing that is SQL is checked: the server judges it.
#
# A refusal is raised before any script exists: nothing is written, nothing
# is executed. t/124-ddl-names-and-sql-live.t asks the server.
subtest 'ddl-names-and-sql-refusals' => sub {
  my $n = 0;
  my sub ddl_for {
    my (%o) = @_;
    my $pkg = 'NameRefuse' . ++$n;
    eval "package ${pkg}::Schema; use base q(DBIO::Schema); "
       . "package ${pkg}::Schema::Result::T; use base q(DBIO::Core); 1"
      or die $@;
    my $schema = "${pkg}::Schema";
    my $result = "${pkg}::Schema::Result::T";
    $schema->load_components('PostgreSQL');
    $result->load_components('PostgreSQL::Result');
    $result->table('t');
    $result->add_columns(
      id   => { data_type => 'integer', is_auto_increment => 1 },
      name => { data_type => 'text' },
      kind => { data_type => 'text' },
    );
    $result->set_primary_key('id');
    $schema->pg_search_path(@{ $o{path} }) if $o{path};
    $schema->pg_settings($o{settings}) if $o{settings};
    $result->result_source_instance->add_index_declaration($o{index})
      if $o{index};
    $result->pg_index(@{ $o{pg_index} }) if $o{pg_index};
    $schema->register_class(T => $result);
    return DBIO::PostgreSQL::DDL->install_ddl($schema);
  }
  my sub path_of { ddl_for(path => [@_]) =~ /^(SET search_path TO .*;)$/m ? $1 : undef }
  my sub script_with_path { ddl_for(path => [@_]) }
  my sub index_of {
    my ($pg) = @_;
    (eval { ddl_for(index => { name => 'ix', columns => ['name'], driver => { pg => $pg } }) } // "refused: $@")
      =~ /^(CREATE INDEX ix .*;)$/m ? $1 : undef;
  }
  my sub refused_ok {
    my ($code, $like, $name) = @_;
    my $sql = eval { $code->(); 1 } ? 'no refusal' : undef;
    my $err = $@;
    ok !defined $sql && $err =~ $like, $name or diag "got: " . ($err || $sql);
  }

  # --- pg_search_path: names are accepted, and written nowhere (karr k121)
  for my $entries (['auth', 'public'], ['MySchema', 'public'], ['order'], ['a.b'],
    ['x; COMMENT ON SCHEMA public IS $$y$$'], ['$user', 'public']) {
    my $sql = eval { script_with_path(@$entries) };
    ok defined $sql && $sql !~ /search_path/,
      "pg_search_path(" . join(', ', @$entries) . "): installs, and the script holds no search_path"
      or diag $@ || $sql;
  }

  for my $quoted ('"auth"', '"$user"') {
    refused_ok sub { path_of($quoted, 'public') },
      qr/refusing to write the install DDL: pg_search_path entry \Q$quoted\E.*without quotes/s,
      "pg_search_path entry $quoted: already quoted, refused with the way out";
  }
  refused_ok sub { path_of('') }, qr/refusing to write the install DDL: pg_search_path entry/,
    'an empty entry is refused';
  refused_ok sub { path_of([]) }, qr/refusing to write the install DDL: pg_search_path entry/,
    'a reference as entry is refused';

  # --- pg_settings: keys are names
  # The key reaches the server as the third argument of format('ALTER DATABASE
  # %I SET %s = %L', ...): a literal that holds the name as SQL.
  my sub setting_of {
    my ($key, $value) = @_;
    my $sql = eval { ddl_for(settings => { $key => $value // '1' }) }
      // return "refused: $@";
    return $sql =~ /current_database\(\), ('(?:[^']|'')*'), '/ ? $1 : undef;
  }
  is setting_of('statement_timeout'), q{'statement_timeout'},
    'a plain key is written bare';
  is setting_of('myapp.greeting'), q{'myapp.greeting'},
    'a dotted key is a dotted name: app.current_user_id stays bare';
  is setting_of('app.current_user_id'), q{'app.current_user_id'},
    '... the parameter the RLS example reads';
  is setting_of('DateStyle'), q{'"DateStyle"'},
    'a mixed-case key is quoted by the server\'s rule, not written as given';
  is setting_of('Statement_Timeout'), q{'"Statement_Timeout"'},
    '... the same for any upper-case letter';
  is setting_of('MyApp.Greeting'), q{'"MyApp"."Greeting"'},
    'each part of a dotted key is quoted for itself';
  is setting_of('app.order'), q{'app."order"'},
    'a part that is a key word is quoted';
  is setting_of('a b'), q{'"a b"'}, 'a blank makes a (strange) name, quoted';
  is setting_of("it's"), q{'"it''s"'},
    'an apostrophe in a key is quoted as a name and doubled in the literal around it';
  is setting_of("statement_timeout = '7s'; COMMENT ON SCHEMA public IS 'x'; SET app.x"),
    q{'"statement_timeout = ''7s''; COMMENT ON SCHEMA public IS ''x''; SET app".x'},
    'a statement in a key is a name, never a second statement';
  like eval { ddl_for(settings => { DateStyle => 'ISO, DMY' }) } // "refused: $@",
    qr/\Qformat('ALTER DATABASE %I SET %s = %L', current_database(), '"DateStyle"', 'ISO, DMY')\E/,
    'the whole call: the key as a name inside a literal, the value as a literal';

  for my $quoted (['"Quoted"' => 'Quoted'], ['app."X"' => 'app.X'], ['"app".x' => 'app.x']) {
    my ($key, $plain) = @$quoted;
    refused_ok sub { ddl_for(settings => { $key => '1' }) },
      qr/refusing to write the install DDL: pg_settings key \Q$key\E is already quoted.*without quotes \(\Q$plain\E\)/s,
      "pg_settings key $key: already quoted, refused with the unquoted form";
  }
  for my $key ('', 'a..b', '.a', 'a.', "a\0b") {
    (my $shown = $key) =~ s/\0/\\0/g;
    refused_ok sub { ddl_for(settings => { $key => '1' }) },
      qr/refusing to write the install DDL: pg_settings key .* is not a name/s,
      "pg_settings key '$shown' is refused: no name";
  }

  # --- index using: SQL, written as given
  for my $using ('gin', 'GIN', 'my_am2', '"BTree"', 'public.gin', 'gin; DROP TABLE t') {
    is index_of({ using => $using }), "CREATE INDEX ix ON t USING $using (name);",
      "using '$using' is written as given";
  }
  like eval { ddl_for(pg_index => [ hand => { columns => ['name'], using => 'GiST' } ]) } // "refused: $@",
    qr/^CREATE INDEX hand ON t USING GiST \(name\);$/m,
    'the same for an index declared with pg_index';

  # --- index with: keys checked as names, values written as given
  is index_of({ with => { fillfactor => 70 } }),
    'CREATE INDEX ix ON t (name) WITH (fillfactor = 70);', 'with: a plain key and value';
  is index_of({ with => { Lists => "'100'", 'toast.x' => 'on' } }),
    q{CREATE INDEX ix ON t (name) WITH (Lists = '100', toast.x = on);},
    'with: a key in any case, a dotted key, a quoted value -- written as given';

  # --- opclasses: SQL, written as given
  for my $oc (
    'vector_l2_ops', 'public.vector_l2_ops', '"MyOps"', '"My Schema"."My Ops"',
    'gist_trgm_ops(siglen=32)', 'text_pattern_ops DESC NULLS LAST',
    'ops COLLATE "C"', 'a.b.c', 'ops, kind', 'text_ops; DROP TABLE t',
  ) {
    is index_of({ opclasses => { name => $oc } }),
      "CREATE INDEX ix ON t (name $oc);", "opclass '$oc' is written as given";
  }
  is index_of({ opclasses => { name => '' } }), 'CREATE INDEX ix ON t (name);',
    'an empty opclass names none (as before)';
};

# karr k120, "skipping a foreign key" (maintainer's decision 2026-10-12).
#
# A result class that opts into pg_fk_constraints_from_rels asks for its
# belongs_to relationships to become FOREIGN KEY constraints. Two of the ways
# that cannot be done are mistakes of the declaration, not a property of the
# relationship, and are refused -- loudly, naming table, relationship and
# class, and before any script exists -- where the script used to carry a
# `-- skipped FK` note nobody reads:
#
#   foreign class is not loaded               refused
#   table is not part of this schema deploy   refused
#
# A condition that is no column equality is a relationship that cannot be
# written as a FOREIGN KEY, and stays a note in the script.
subtest 'ddl-fk-from-rels-refusals' => sub {
  my $n = 0;
  my sub fresh {
    my $pkg = 'FKRefuse' . ++$n;
    my %o = (schema => "${pkg}::Schema");
    eval "package $o{schema}; use base q(DBIO::Schema); 1" or die $@;
    $o{schema}->load_components('PostgreSQL');
    $o{pkg} = $pkg;
    return \%o;
  }
  my sub result {
    my ($o, $name, $table, %opt) = @_;
    my $class = "$o->{pkg}::Result::$name";
    eval "package $class; use base q(DBIO::Core); 1" or die $@;
    $class->load_components('PostgreSQL::Result');
    $class->table($table);
    $class->add_columns(
      id        => { data_type => 'integer', is_auto_increment => 1 },
      parent_id => { data_type => 'integer', is_nullable => 1 },
    );
    $class->set_primary_key('id');
    # no_fk switches the class off with 0; default leaves the setting alone,
    # which is on; otherwise it is set to 1 explicitly
    $class->pg_fk_constraints_from_rels($opt{no_fk} ? 0 : 1) unless $opt{default};
    return $class;
  }
  my sub install_ddl { DBIO::PostgreSQL::DDL->install_ddl($_[0]) }

  # --- a foreign class that is not loaded ------------------------------------
  {
    my $o = fresh();
    my $child = result($o, Child => 'child');
    $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
      { 'foreign.id' => 'self.parent_id' });
    $o->{schema}->register_class(Child => $child);

    my $sql = eval { install_ddl($o->{schema}) };
    my $err = $@;
    ok !defined $sql, 'a belongs_to to a class that is not loaded: no script';
    like $err, qr/refusing to write the install DDL: /, '... refused in the style of the others';
    like $err, qr/\bchild\b/, '... names the table';
    like $err, qr/\bghost\b/, '... names the relationship';
    like $err, qr/\Q$o->{pkg}\E::Result::NeverLoaded/, '... names the class';
    like $err, qr/not loaded/, '... and says why';
    unlike $err, qr/skipped FK/, '... and is no note';
  }

  # --- a table that is not part of this deploy --------------------------------
  {
    my $o = fresh();
    my $other = result($o, Other => 'not_deployed', no_fk => 1);
    my $child = result($o, Child => 'child');
    $child->belongs_to(target => $other, 'parent_id');
    $o->{schema}->register_class(Child => $child);    # Other is not registered

    my $sql = eval { install_ddl($o->{schema}) };
    my $err = $@;
    ok !defined $sql, 'a belongs_to to a table outside the deploy: no script';
    like $err, qr/refusing to write the install DDL: /, '... refused in the style of the others';
    like $err, qr/\bchild\b/, '... names the table';
    like $err, qr/\btarget\b/, '... names the relationship';
    like $err, qr/\bnot_deployed\b/, '... names the foreign table';
    like $err, qr/not part of this schema deploy/, '... and says why';
  }

  # --- the target is in the deploy: unchanged ---------------------------------
  {
    my $o = fresh();
    my $parent = result($o, Parent => 'parent', no_fk => 1);
    my $child  = result($o, Child => 'child');
    $child->belongs_to(parent => $parent, 'parent_id');
    $o->{schema}->register_class(Parent => $parent);
    $o->{schema}->register_class(Child  => $child);
    my $sql = eval { install_ddl($o->{schema}) };
    ok defined $sql, 'a belongs_to to a table of the deploy: script written' or diag $@;
    like $sql, qr/ALTER TABLE child ADD CONSTRAINT child_parent_id_fkey FOREIGN KEY \(parent_id\) REFERENCES parent \(id\);/,
      '... with its foreign key';
  }

  # --- the default is on: a class that sets nothing is refused too ------------
  {
    my $o = fresh();
    my $child = result($o, Child => 'child', default => 1);
    $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
      { 'foreign.id' => 'self.parent_id' });
    $o->{schema}->register_class(Child => $child);
    my $sql = eval { install_ddl($o->{schema}) };
    ok !defined $sql, 'a class that does not set pg_fk_constraints_from_rels is refused for a dangling relationship';
    like $@, qr/refusing to write the install DDL: .*NeverLoaded/, '... naming the class';
  }

  # --- switched off with 0: nothing is looked at ------------------------------
  {
    my $o = fresh();
    my $child = result($o, Child => 'child', no_fk => 1);
    $child->belongs_to(ghost => "$o->{pkg}::Result::NeverLoaded",
      { 'foreign.id' => 'self.parent_id' });
    $o->{schema}->register_class(Child => $child);
    my $sql = eval { install_ddl($o->{schema}) };
    ok defined $sql, 'without pg_fk_constraints_from_rels a dangling relationship is no business of the script'
      or diag $@;
  }

  # --- a condition that is no column equality: still a note -------------------
  {
    my $o = fresh();
    my $parent = result($o, Parent => 'parent', no_fk => 1);
    my $child  = result($o, Child => 'child');
    $child->belongs_to(parent => $parent, sub { {} });
    $o->{schema}->register_class(Parent => $parent);
    $o->{schema}->register_class(Child  => $child);
    my $sql = eval { install_ddl($o->{schema}) };
    ok defined $sql, 'a non-column condition does not refuse' or diag $@;
    like $sql, qr/^-- skipped FK for rel parent: non-column condition$/m,
      '... and stays a note in the script';
  }
};

done_testing;
