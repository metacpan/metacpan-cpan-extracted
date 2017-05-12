use strict;
use Test::More tests => 112;
use Test::Deep;
use Test::Exception;
use Data::Dumper;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh;
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
ok($dbh = PgLinkTestUtil::connect(), 'connected');
PgLinkTestUtil::init_test();

sub exec_func {
  my $func = shift;
  my $params = join(',', map { '?' } @_);
  return $dbh->selectrow_array("SELECT $func($params)", {}, @_);
}


#---------------------------------------------------------tracing
is( exec_func('dbix_pglink.trace_level', 0), 0, 'trace_level set to 0');
is( exec_func('dbix_pglink.trace_level', 1), 1, 'trace_level set to 1');
is( exec_func('dbix_pglink.trace_level'), 1, 'get trace_level');
for my $severity (qw/DEBUG LOG INFO NOTICE WARNING/) {
  ok( $dbh->do("SELECT dbix_pglink.trace_msg('$severity', 'test $severity message')"), 'trace $severity message');
}
throws_ok {
  $dbh->do("SELECT dbix_pglink.trace_msg('ERROR', 'test ERROR message')");
} qr/ERROR:  error from Perl function: test ERROR message/, 'trace ERROR message raise exception';



#---------------------------------------------------------quoting
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_quote(_text text) 
returns text language plperlu as $body$
  use DBIx::PgLink::Local;
  return pg_dbh->quote(shift);
$body$;
END_OF_SQL

my @quote = do "t/quote-pg";

for my $q (@quote) {
  is( exec_func('test_local_quote', $q->{value}), $q->{exp},
    "quote " . (defined $q->{value} ? $q->{value} : '<undef>'));
}


$dbh->do(<<'END_OF_SQL');
create or replace function test_local_quote_identifier(_text text) 
returns text language plperlu as $body$
  use DBIx::PgLink::Local;
  return pg_dbh->quote_identifier(shift);
$body$;
END_OF_SQL

# with 	$quote_ident_only_if_necessary on
my @quote_identifier = (
  { value=>q!!,            exp=>q!""! }, 
  { value=>q!hello!,       exp=>q!hello! }, 
  { value=>q!hello world!, exp=>q!"hello world"! }, 
  { value=>q!"hello!,      exp=>q!"""hello"! }, 
  { value=>q!hel"lo!,      exp=>q!"hel""lo"! }, 
  { value=>q!hello"!,      exp=>q!"hello"""! }, 
  { value=>q!hel""lo!,     exp=>q!"hel""""lo"! }, 
  { value=>q!hel\\lo!,     exp=>q!"hel\\lo"! }, 
  { value=>q!hel'lo!,      exp=>q!"hel'lo"! }, 
  { value=>q!view!,        exp=>q!"view"! }, 
);

for my $q (@quote_identifier) {
  is( 
    exec_func('test_local_quote_identifier', $q->{value}), 
    $q->{exp}, 
    "quote_identifier $q->{value}"
  );
}

#---------------------------------------------------------select
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_bool() 
returns void language plperlu as $body$
  use DBIx::PgLink::Local;
  die "pg->perl: undef->undef" unless !defined pg_dbh->pg_to_perl_boolean(undef);
  die "pg->perl: f->0" unless pg_dbh->pg_to_perl_boolean('f') eq '0';
  die "pg->perl: t->1" unless pg_dbh->pg_to_perl_boolean('t') eq '1';
  die "perl->pg: undef->undef" unless !defined pg_dbh->pg_from_perl_boolean(undef);
  die "perl->pg: 0->f" unless pg_dbh->pg_from_perl_boolean('0') eq 'f';
  die "perl->pg: 1->t" unless pg_dbh->pg_from_perl_boolean('1') eq 't';
$body$;
END_OF_SQL
lives_ok {
  $dbh->do('SELECT test_local_bool()')
} 'boolean conversions';

#---------------------------------------------------------select

# build 2 closures to compare
sub build_fns {
  my ($got_perl, $exp_perl) = @_;
  $exp_perl = $got_perl unless defined $exp_perl;

  diag "code: \n$got_perl\n$exp_perl\n" if $Trace_level>=2;
  # first closure 
  #  - create PL/Perl function
  #  - execute PL/Perl function
  #  - interpolate $got_perl scalar result serialized to text
  #  - get text using DBI
  #  - deserialize text to Perl scalar
  my $got_coderef = sub {
    my $query = shift; 
    my $func = <<END_OF_SQL;
create or replace function test_local_select (_query text) 
returns text language plperlu as \$body\$
  use DBIx::PgLink::Local;
  use Data::Dumper;
  my \$query = shift;
  my \$dbh = pg_dbh;
  my \$result = do {
    $got_perl
  };
  return Dumper(\$result); # serialize
\$body\$;
END_OF_SQL
    diag $func if $Trace_level >= 2;
    $dbh->do($func);
    my $dump = exec_func('test_local_select', $query);
    our $VAR1 = undef;
    eval $dump; # deserialize
    return $VAR1;
  };

  # second closure execute perl code using standard DBI $dbh
  my $exp_coderef = sub {
    my $query = shift;
    return eval $exp_perl;
  };
  return ($got_coderef, $exp_coderef);
}

my %queries = (
  's1' => 'SELECT 1', # single value
  's2' => 'SELECT * FROM generate_series(1,10)', # 10 rows, 1 column
  's3' => # mix of datatypes (no boolean), 3 rows
    q/SELECT oid, relname, relkind, relowner, relacl 
      FROM pg_class 
      WHERE relname in ('pg_class', 'pg_database', 'pg_attribute')
      ORDER BY 1/,
  's4' => 'SELECT 1 FROM pg_class WHERE 1=0', # no rows
  'b1' => 'SELECT true as foo, false as bar', # 1 row, 2 boolean columns
  'b2' => # 3 rows, 3 boolean columns + 2 text columns
    q/SELECT           true as foo, false as bar, 'f'::text as dummy1, null::boolean as baz, 'f'::text as dummy2
      UNION ALL SELECT false,       null,         't',                 true,                 't'
      UNION ALL SELECT null,        true,         null,                false,                null
     /,
);


# prepare + execute{no_cursor} (row count)
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
my $sth = $dbh->prepare($query, {no_cursor=>1});
$sth->execute;
END_OF_GOT
my $sth = $dbh->prepare($query);
$sth->execute;
END_OF_EXP

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare + execute{all}, $t");
  }
}

# prepare + execute{no_cursor} + fetchall_arrayref
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
my $sth = $dbh->prepare($query, {no_cursor=>1});
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_GOT
my $sth = $dbh->prepare($query);
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_EXP

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare + execute{all} + fetchall_arrayref, $t");
  }
  { # boolean (NO COERCE)
    my $query = $queries{'b1'};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, [{foo=>'t', bar=>'f'}], 'SELECT true, false');
    cmp_deeply($exp, [{foo=>'1', bar=>'0'}], 'SELECT true, false');
  }
}

# prepare + execute{no_cursor} + fetchall_arrayref (convert boolean in result)
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
my $sth = $dbh->prepare($query, {no_cursor=>1, boolean=>[qw/foo bar baz/]});
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_GOT
my $sth = $dbh->prepare($query);
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_EXP
  for my $t (sort grep /^b/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, 'prepare + execute{all} + fetchall_arrayref (convert boolean in result)');
  }
}


# prepare + execute + fetchall_arrayref
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_CODE');
my $sth = $dbh->prepare($query);
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_CODE

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare + execute + fetchall_arrayref, $t");
  }
}

# prepare + execute + fetchrow_hashref
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_CODE');
my $sth = $dbh->prepare($query);
$sth->execute;
$sth->fetchrow_hashref;
END_OF_CODE

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare + execute + fetchrow_hashref, $t");
  }
}

# prepare + execute + fetchrow_hashref (convert boolean in result)
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
my $sth = $dbh->prepare($query, {boolean=>[qw/foo bar baz/]});
$sth->execute;
$sth->fetchrow_hashref;
END_OF_GOT
my $sth = $dbh->prepare($query);
$sth->execute;
$sth->fetchrow_hashref;
END_OF_EXP
  {
    my $query = $queries{'b2'};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, 'prepare + execute + fetchrow_hashref (convert boolean in result)');
  }
}

# selectall_arrayref (convert boolean in params)
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
$dbh->selectall_arrayref($query, {Slice=>{}, types=>[qw/BOOL/]}, 1);
END_OF_GOT
$dbh->selectall_arrayref($query, {Slice=>{}}, 1);
END_OF_EXP
  {
    my $query = 'SELECT id FROM source.tbool WHERE b=$1';
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, 'selectall_arrayref (convert boolean in params)');
  }
}

{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
$dbh->selectall_arrayref($query, {Slice=>{}, types=>[qw/BOOL/]}, 0);
END_OF_GOT
$dbh->selectall_arrayref($query, {Slice=>{}}, 0);
END_OF_EXP
  {
    my $query = 'SELECT id FROM source.tbool WHERE b=$1';
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, 'selectall_arrayref (convert boolean in params)');
  }
}

{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
$dbh->selectall_arrayref($query, {Slice=>{}, types=>[qw/BOOL/]}, undef);
END_OF_GOT
$dbh->selectall_arrayref($query, {Slice=>{}}, undef);
END_OF_EXP
  {
    my $query = 'SELECT id FROM source.tbool WHERE b=$1';
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, 'selectall_arrayref (convert boolean in params)');
  }
}


#-------------------------------------------------------------cache

# prepare_cached + execute{no_cursor} + fetchall_arrayref
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_GOT', <<'END_OF_EXP');
my $sth = $dbh->prepare_cached($query, {no_cursor=>1});
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_GOT
my $sth = $dbh->prepare_cached($query);
$sth->execute;
$sth->fetchall_arrayref({});
END_OF_EXP

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare_cached + execute{all} + fetchall_arrayref, $t");
  }
}

# prepare_cached + execute + fetchrow_hashref
{
  my ($got_coderef, $exp_coderef) = build_fns(<<'END_OF_CODE');
my $sth = $dbh->prepare_cached($query);
$sth->execute;
$sth->fetchrow_hashref;
END_OF_CODE

  for my $t (sort grep /^s/, keys %queries) {
    my $query = $queries{$t};
    my $got = $got_coderef->($query);
    my $exp = $exp_coderef->($query);
    diag "\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
    cmp_deeply($got, $exp, "prepare_cached + execute + fetchrow_hashref, $t");
  }
}

# ------------------------------------------------------placeholders

my @param_queries = (
  { 
    'n'=>'s1',
    'q'=>'SELECT $1::text',
    't'=>undef, # TEXT
    'v'=>[['a'],['b'],['c']],
  },
  { 
    'n'=>'s2',
    'q'=>'SELECT $1::text',
    't'=>['TEXT'],
    'v'=>[['a'],['b'],['c']],
  },
  {
    'n'=>'s3',
    'dies_ok' => 1,
    'q'=>'SELECT ?::int4',
    't'=>['INT4'],
    'v'=>[[1],[2],[3]],
  },
  {
    'n'=>'s4',
    'q'=>'SELECT * FROM source.crud WHERE i=$1 and t=$2',
    't'=> undef,
    'v'=>[[1,'row#1']],
  },
  {
    'n'=>'s5',
    'q'=>'SELECT * FROM source.crud WHERE i=$2 and t=$1',
    't'=> undef,
    'v'=>[['row#1',1]],
  },
  {
    'n'=>'s6',
    'q'=>'SELECT * FROM source.crud WHERE i=? and t=?',
    't'=> undef,
    'v'=>[[1,'row#1']],
  },
  {
    'n'=>'s7',
    'q'=>'SELECT * FROM source.crud WHERE i=$1 and t=$2',
    't'=> ['INT4','TEXT'],
    'v'=>[[1,'row#1']],
  },
  {
    'n'=>'s8',
    'q'=>'SELECT * FROM source.crud WHERE i=$2 and t=$1',
    't'=> ['TEXT','INT4'],
    'v'=>[['row#1',1]],
  },
  {
    'n'=>'s9',
    'dies_ok' => 1,
    'q'=>'SELECT * FROM source.crud WHERE i=? and t=?',
    't'=> ['INT4','TEXT'],
    'v'=>[[1,'row#1']],
  },
  {
    'n'=>'f1',
    'q'=>q/SELECT * FROM source.crud WHERE i=? and t='?'/, # ? in literal
    't'=> undef,
    'v'=>[[1,'WRONG']], # DBD::Pg issue warning and returns undef
    'got' => undef,
  },
  {
    'n'=>'f2',
    'dies_ok' => 1,
    'q'=>q/SELECT * FROM source.crud WHERE i=? and t='?'/, # ? in literal
    't'=> undef,
    'v'=>[[1]], # PL/Perl fails
  },
);

# can DBD::Pg do both placeholder styles?
lives_ok {
  my $sth = $dbh->prepare('SELECT $1::text') or die "prepare_failed";
  $sth->execute('foo') or die "execute failed";
} 'DBD::Pg $1 placeholder';
lives_ok {
  my $sth = $dbh->prepare('SELECT ?::text') or die "prepare_failed";
  $sth->execute('foo') or die "execute failed";
} 'DBD::Pg $1 placeholder';


for my $pq (@param_queries) {
  my $types_str = defined $pq->{'t'} ?  ", {types=>['" . join("','", @{$pq->{'t'}}) . "']}"
                         : '';
  for my $v (@{$pq->{'v'}}) {
    my $values_str = "'" . join("','", @{$v}) . "'";
    my ($got_coderef, $exp_coderef) = build_fns(<<END_OF_GOT, <<END_OF_EXP);
my \$sth = \$dbh->prepare_cached(\$query $types_str);
\$sth->execute($values_str);
\$sth->fetchall_arrayref({});
END_OF_GOT
my \$sth = \$dbh->prepare_cached(\$query);
\$sth->execute($values_str);
\$sth->fetchall_arrayref({});
END_OF_EXP

    if ($pq->{'dies_ok'}) {
      dies_ok {
        my $got = $got_coderef->($pq->{'q'});
        my $exp = $exp_coderef->($pq->{'q'});
      } "parametrized query $pq->{'n'} must fail";
    } else {
      my $got = $got_coderef->($pq->{'q'});
      my $exp = $exp_coderef->($pq->{'q'});
      $got = $pq->{'got'} if exists $pq->{'got'};
      diag "\n$pq->{'n'}, $pq->{'q'}\n", Data::Dumper->Dump([$got, $exp], ['got', 'exp']) if $Trace_level;
      cmp_deeply($got, $exp, "parametrized query $pq->{'n'}");
    }
  } # $v
} # $pq

#--------------------------------------------------------cache
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_cache() 
returns void language plperlu as $body$
  use strict;
  use DBIx::PgLink::Local;

  pg_dbh->pg_flush_plan_cache;
  die 'cache must be clean now' unless (keys %DBIx::PgLink::Local::cached_plans == 0);

  pg_dbh->do('SELECT current_database()');
  die 'must be 1 item in cache' unless (keys %DBIx::PgLink::Local::cached_plans == 1);

  my $foo = pg_dbh->selectrow_array('SELECT current_database()');
  die 'still must be 1 item in cache' unless (keys %DBIx::PgLink::Local::cached_plans == 1);

  pg_dbh->do('SELECT current_user');
  die 'must be 2 items in cache' unless (keys %DBIx::PgLink::Local::cached_plans == 2);

  pg_dbh->pg_flush_plan_cache;
  die 'cache must be clean again' unless (keys %DBIx::PgLink::Local::cached_plans == 0);

  # assume that user not set plperl.plan_cache_size in postgresql.conf
  my $def = DBIx::PgLink::Local::default_plan_cache_size();
  for my $i (1..($def+42)) {
    pg_dbh->prepare_cached("SELECT $i");
  }
  die 'cache must be limited to $def' unless (keys %DBIx::PgLink::Local::cached_plans == $def);

  return;
$body$;
END_OF_SQL

ok($dbh->do('SELECT test_local_cache()'), 'plan cache');


#----------------------------------------------------------utility functions
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_utility(_func text) 
returns text language plperlu as $body$
  use DBIx::PgLink::Local;
  my $func = shift;
  no strict;
  return pg_dbh->$func();
$body$;
END_OF_SQL
like( exec_func('test_local_utility', 'pg_server_version'), qr/^\d+$/, 'pg_server_version');
is(   exec_func('test_local_utility', 'pg_session_user'),  $Test->{TEST}->{user}, 'pg_session_user');
is(   exec_func('test_local_utility', 'pg_current_database'),  $Test->{TEST}->{database}, 'pg_current_database');


#---------------------------------------------------------array
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_array1(_array text) 
returns text language plperlu as $body$
  use DBIx::PgLink::Local;
  use Data::Dumper;
  my @arr = pg_dbh->pg_to_perl_array(shift);
  return Dumper(\@arr);
$body$;
END_OF_SQL

sub exec_array {
  my $dump = exec_func('test_local_array1', @_);
  our $VAR1 = undef;
  eval $dump; # deserialize
}

cmp_deeply(exec_array('{1,2,3}'), [1,2,3], 'pg->perl array conversion');
cmp_deeply(exec_array('{1,NULL,3}'), [1,undef,3], 'pg->perl array conversion');
cmp_deeply(exec_array('{1,hello world,3}'),   [1,'hello world',3], 'pg->perl array conversion');
cmp_deeply(exec_array('{1,"hello world",3}'), [1,'hello world',3], 'pg->perl array conversion');
cmp_deeply(exec_array('{1,"hello,world",3}'), [1,'hello,world',3], 'pg->perl array conversion');
cmp_deeply(exec_array('{1,"hello\"world",3}'), [1,'hello"world',3], 'pg->perl array conversion');

cmp_deeply(
  exec_array('{{1,2},{3,4}}'), 
  [[1,2],[3,4]], 
  'pg->perl 2-dimensional array conversion'
);
cmp_deeply(
  exec_array('{{{1,2},{3,4}},{{5,6},{7,8}}}'), 
  [[[1,2],[3,4]],[[5,6],[7,8]]], 
  'pg->perl 3-dimensional array conversion'
);
cmp_deeply(
  exec_array('{{1,NULL},{null,4}}'), 
  [[1,undef],[undef,4]], 
  'pg->perl 2-dimensional array conversion with nulls'
);
cmp_deeply(
  exec_array('{{1,"hello world"},{"\"foo\" bar",4}}'), 
  [[1,'hello world'],['"foo" bar',4]], 
  'pg->perl 2-dimensional array conversion with quoted values'
);


# pg_from_perl_array() quote all values, but reverse conversion strips unneeded quote marks

$dbh->do(<<'END_OF_SQL');
create or replace function test_local_array2(_array text) 
returns text[] language plperlu as $body$
  use DBIx::PgLink::Local;
  my @arr = eval shift;
  return pg_dbh->pg_from_perl_array(@arr);
$body$;
END_OF_SQL

is( exec_func('test_local_array2', q/(1,2,3)/), '{1,2,3}', 'perl->pg array conversion');
is( exec_func('test_local_array2', q/(1,undef,3)/), '{1,NULL,3}', 'perl->pg array conversion');
is( exec_func('test_local_array2', q/('a','b','c')/), '{a,b,c}', 'perl->pg array conversion'); 
is( exec_func('test_local_array2', q/('a',undef,'c')/), '{a,NULL,c}', 'perl->pg array conversion'); 
is( exec_func('test_local_array2', q/('a','how do you do','c')/), '{a,"how do you do",c}', 'perl->pg array conversion'); 
is( exec_func('test_local_array2', q/('a','how "do" you do','c')/), '{a,"how \\"do\\" you do",c}', 'perl->pg array conversion'); 

is( 
  exec_func('test_local_array2', q/([1,2],[3,4])/), 
  '{{1,2},{3,4}}', 
  'perl->pg 2D array conversion'
); 
is( 
  exec_func('test_local_array2', q/([[1,2],[3,4]],[[5,6],[7,8]])/), 
  '{{{1,2},{3,4}},{{5,6},{7,8}}}', 
  'perl->pg 3D array conversion'
); 
is( 
  exec_func('test_local_array2', q/([1,undef],[undef,4])/), 
  '{{1,NULL},{NULL,4}}', 
  'perl->pg 2D array conversion with nulls'
); 
is( 
  exec_func('test_local_array2', q/([1,'foo bar'],['"foo" bar',4])/), 
  '{{1,"foo bar"},{"\"foo\" bar",4}}', 
  'perl->pg 2D array conversion with quoted values'
); 


#---------------------------------------------------------hash
$dbh->do(<<'END_OF_SQL');
create or replace function test_local_hash1(_array text) 
returns text language plperlu as $body$
  use DBIx::PgLink::Local;
  use Data::Dumper;
  my $hashref = pg_dbh->pg_to_perl_hash(shift);
  return Dumper($hashref);
$body$;
END_OF_SQL

sub exec_hash {
  my $dump = exec_func('test_local_hash1', @_);
  our $VAR1 = undef;
  eval $dump; # deserialize
}

cmp_deeply(exec_hash('{foo,1,bar,2}'), {foo=>1,bar=>2}, 'pg->perl hash conversion');
cmp_deeply(exec_hash('{foo,1,"bar","X Y Z"}'), {foo=>1,bar=>'X Y Z'}, 'pg->perl hash conversion');

$dbh->do(<<'END_OF_SQL');
create or replace function test_local_hash2(_hash text) 
returns text[] language plperlu as $body$
  use DBIx::PgLink::Local;
  my $hashref = eval shift;
  return pg_dbh->pg_from_perl_hash($hashref);
$body$;
END_OF_SQL

# hash entries are not sorted!
{ 
  my $str = exec_func('test_local_hash2', q/{foo=>1,bar=>2}/);
  ok ( $str eq '{foo,1,bar,2}' || $str eq '{bar,2,foo,1}', 'perl->pg hash conversion');
}
{ 
  my $str = exec_func('test_local_hash2', q/{foo=>1,bar=>"X Y Z"}/);
  ok ( $str eq '{foo,1,bar,"X Y Z"}' || $str eq '{bar,"X Y Z",foo,1}', 'perl->pg hash conversion');
}
