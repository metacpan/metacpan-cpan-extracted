use strict;

BEGIN {
  use Test::More;
  use Test::Exception;
  eval { require DBIx::Safe };
  if ($@) {
    plan skip_all => 'no DBIx::Safe installed';
  } else {
    plan tests => 15;
  }
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

$dbh->do(q/SELECT dbix_pglink.set_role('TEST','', 'Adapter','Safe', null, false)/);

END {
  if (defined $dbh) {
    $dbh->do(q/SELECT dbix_pglink.delete_role('TEST','', 'Adapter','Safe'::text)/);
  }
}



my %q = (
  'S' => q/SELECT * FROM source.crud WHERE id=101/,
  'I' => q/INSERT INTO source.crud (id,i,t) SELECT 101,101,'foo'/,
  'U' => q/UPDATE source.crud SET t = 'bar' WHERE id=101/,
  'D' => q/DELETE FROM source.crud WHERE id=101/,
);

my $ins_safe = $dbh->prepare(<<'END_OF_SQL');
INSERT INTO dbix_pglink.safe (
  conn_name,
  local_user,
  safe_kind,
  safe_text,
  safe_perm
) VALUES (?, ?, ?, ?, ?)
END_OF_SQL


#----------------------------------nothing allowed

$dbh->do(q/DELETE FROM dbix_pglink.safe WHERE conn_name='TEST'/);

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{S});
} qr/\(pg\) Invalid statement:/, 'no access be default';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{D});
} qr/\(pg\) Invalid statement:/, 'no access be default';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{I});
} qr/\(pg\) Invalid statement:/, 'no access be default';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{U});
} qr/\(pg\) Invalid statement:/, 'no access be default';

#----------------------------------only SELECT allowed

$dbh->do(q/SELECT dbix_pglink.disconnect('TEST')/);

$ins_safe->execute('TEST', '', 'command', 'SELECT', 'allow');

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{S});
} 'SELECT allowed';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{D});
} qr/\(pg\) Invalid statement:/, 'DELETE not allowed';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{I});
} qr/\(pg\) Invalid statement:/, 'INSERT not allowed';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{U});
} qr/\(pg\) Invalid statement:/, 'UPDATE not allowed';


#----------------------------------S,I,U,D allowed

$dbh->do(q/SELECT dbix_pglink.disconnect('TEST')/);

$ins_safe->execute('TEST', '', 'command', 'INSERT', 'allow');
$ins_safe->execute('TEST', '', 'command', 'UPDATE', 'allow');
$ins_safe->execute('TEST', '', 'command', 'DELETE', 'allow');

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{S});
} 'SELECT allowed';

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{D});
} 'DELETE allowed';

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{I});
} 'INSERT allowed';

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, $q{U});
} 'UPDATE allowed';

# ---------------------------- regex

$dbh->do(q/SELECT dbix_pglink.disconnect('TEST')/);

$ins_safe->execute('TEST', '', 'regex', 'all_types', 'deny');
$ins_safe->execute('TEST', '', 'regex', 'SELECT 1 FROM source\.crud\b', 'allow');

lives_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, q/SELECT 1 FROM source.crud WHERE 1=0/);
} 'select from crud allowed';

throws_ok {
  $dbh->do(q/SELECT dbix_pglink.exec('TEST',?)/, {}, q/SELECT 1 FROM source.all_types WHERE 1=0/);
} qr/Forbidden statement/, 'all_types not allowed';

# TODO: more regexes
# TODO: attribute?
