use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::DDL;

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

my $n = 0;
sub ddl_for {
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
sub path_of { ddl_for(path => [@_]) =~ /^(SET search_path TO .*;)$/m ? $1 : undef }
sub script_with_path { ddl_for(path => [@_]) }
sub index_of {
  my ($pg) = @_;
  (eval { ddl_for(index => { name => 'ix', columns => ['name'], driver => { pg => $pg } }) } // "refused: $@")
    =~ /^(CREATE INDEX ix .*;)$/m ? $1 : undef;
}
sub refused_ok {
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
sub setting_of {
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

done_testing;
