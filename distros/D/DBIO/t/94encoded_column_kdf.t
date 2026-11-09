use strict;
use warnings;

use Test::More;
use Digest::SHA ();
use Digest::MD5 ();
use MIME::Base64 ();

use DBIO::Test::Storage;

# DBIO::EncodedColumn (karr k385): Bcrypt and Argon2 for passwords, Digest for
# tokens with a fixed list of algorithms, UTF-8 bytes into every method,
# accept_unencoded off by default with rehash-on-verify, a secure random source
# or nothing, no serializing / changelog of the column, masked trace.

BEGIN {
  eval { require Crypt::Bcrypt; 1 } or plan skip_all => 'Crypt::Bcrypt not installed';
}

my $have_argon2 = eval { require Crypt::Argon2; 1 } ? 1 : 0;

{
  package TestDBIO::EncKdf::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::EncKdf::Schema::Result::Default;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('defaults');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 50, is_nullable => 1 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TestDBIO::EncKdf::Schema::Result::Fast;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('fast');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    password => {
      data_type     => 'varchar', size => 255, is_nullable => 1,
      encode_column => 1,
      encode_class  => 'Bcrypt',
      encode_args   => { cost => 4 },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TestDBIO::EncKdf::Schema::Result::Token;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('tokens');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    token => {
      data_type     => 'varchar', size => 255, is_nullable => 1,
      encode_column => 1,
      encode_class  => 'Digest',
      encode_args   => { algorithm => 'SHA3-256', salt_length => 8 },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package TestDBIO::EncKdf::Schema::Result::Legacy;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('legacy');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    password => {
      data_type     => 'varchar', size => 255, is_nullable => 1,
      encode_column => 1,
      encode_class  => 'Bcrypt',
      encode_args   => { cost => 4, accept_unencoded => 1 },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::EncKdf::Schema->register_class($_ => "TestDBIO::EncKdf::Schema::Result::$_")
  for qw(Default Fast Token Legacy);

TestDBIO::EncKdf::Schema->storage_type('+DBIO::Test::Storage');
my $schema = TestDBIO::EncKdf::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

my $n = 0;
sub class_error {
  my ($info, %opt) = @_;
  my $pkg = 'TestDBIO::EncKdf::Probe' . ++$n;
  my $ok = eval {
    eval "package $pkg; use base 'DBIO::Core'; 1" or die $@;
    $pkg->load_components(@{ $opt{components} || ['EncodedColumn'] });
    $pkg->table('probe');
    $pkg->add_columns(id => { data_type => 'integer' },
      password => { data_type => 'varchar', encode_column => 1, %$info });
    1;
  };
  return $ok ? (undef, $pkg) : ("$@", $pkg);
}

sub from_storage {
  my ($name, $col, $value) = @_;
  my $source = $schema->source($name);
  return $source->result_class->inflate_result($source, { id => 1, $col => $value });
}

sub probe_row {
  my ($pkg) = @_;
  (my $name = $pkg) =~ s/\W//g;
  $schema->register_class($name => $pkg);
  return $schema->resultset($name)->new_result({});
}

sub bound_values {
  my ($q) = @_;
  return map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q->{bind} || [] };
}

# ------------------------------------------------------------ Bcrypt ---------

subtest 'the default class is Bcrypt with cost 12' => sub {
  my $row = $schema->resultset('Default')->new_result({ password => 's3cret' });
  like($row->get_column('password'), qr/\A\$2b\$12\$[.\/A-Za-z0-9]{53}\z/, 'a $2b$12$ bcrypt hash');
  ok($row->check_password('s3cret'), 'the right value matches');
  is($row->check_password('s3creT'), 0, 'another does not');
};

subtest 'Bcrypt takes its cost from encode_args' => sub {
  my $row = $schema->resultset('Fast')->new_result({ password => 's3cret' });
  like($row->get_column('password'), qr/\A\$2b\$04\$/, 'cost 4');
  ok($row->check_password('s3cret'), 'verifies');
  isnt($schema->resultset('Fast')->new_result({ password => 's3cret' })->get_column('password'),
    $row->get_column('password'), 'salted');
  ok(from_storage(Fast => password => $row->get_column('password'))->check_password('s3cret'),
    'verifies after a trip through storage');
};

subtest 'encode_class and encode_args are checked per class' => sub {
  my ($e) = class_error({ encode_args => { cost => 3 } });
  like($e, qr/cost.*4 to 31/, 'cost below 4');
  ($e) = class_error({ encode_args => { cost => 32 } });
  like($e, qr/cost.*4 to 31/, 'cost above 31');
  ($e) = class_error({ encode_args => { algorithm => 'SHA-256' } });
  like($e, qr/Unknown encode_args key\(s\).*algorithm.*known for Bcrypt: accept_unencoded, cost/s,
    'algorithm belongs to Digest');
  ($e) = class_error({ encode_args => { salt_length => 8 } });
  like($e, qr/Unknown encode_args key\(s\).*salt_length/s, 'salt_length belongs to Digest');
  ($e) = class_error({ encode_class => 'Digest', encode_args => { cost => 12 } });
  like($e, qr/Unknown encode_args key\(s\).*cost/s, 'cost is not a Digest key');
  ($e) = class_error({ encode_class => 'Digest', encode_args => { t_cost => 3 } });
  like($e, qr/Unknown encode_args key\(s\).*t_cost/s, 't_cost is not a Digest key');
  ($e) = class_error({ encode_class => 'Bcrypt', encode_args => { m_cost => '32M' } });
  like($e, qr/Unknown encode_args key\(s\).*m_cost/s, 'm_cost is not a Bcrypt key');
  ($e) = class_error({ encode_class => 'Argon2', encode_args => { cost => 12 } });
  like($e, qr/Unknown encode_args key\(s\).*cost/s, 'cost is not an Argon2 key');
  ($e) = class_error({ encode_class => 'Scrypt' });
  like($e, qr/encode_class 'Scrypt'.*known: Argon2, Bcrypt, Digest/, 'unknown class');
  is((class_error({ encode_args => { cost => 4, accept_unencoded => 1 } }))[0], undef, 'known keys load');
};

# ------------------------------------------------------------ Argon2 ---------

subtest 'Argon2 writes and checks argon2id' => sub {
  plan skip_all => 'Crypt::Argon2 not installed' unless $have_argon2;

  my ($e, $pkg) = class_error({
    encode_class => 'Argon2',
    encode_args  => { t_cost => 1, m_cost => '8k', parallelism => 1 },
  });
  is($e, undef, 'the class loads');
  $pkg->set_primary_key('id');
  $schema->register_class(Argon => $pkg);

  my $row = $schema->resultset('Argon')->new_result({ password => "p\x{e4}ss" });
  like($row->get_column('password'), qr/\A\$argon2id\$/, 'an argon2id hash');
  ok($row->check_password("p\x{e4}ss"), 'verifies');
  is($row->check_password('pass'), 0, 'another does not');
  is($row->check_password("p\x{e4}ss" x 30), 0, 'a long value is no problem and does not match');
  ok($schema->resultset('Argon')->new_result({ password => 'a' x 100 })->check_password('a' x 100),
    'no 72 byte limit');
};

subtest 'Argon2 values and a missing module' => sub {
  my $res = do {
    local %INC = %INC;
    delete $INC{'Crypt/Argon2.pm'};
    local @INC = (sub { die "Can't locate Crypt/Argon2.pm\n" if $_[1] eq 'Crypt/Argon2.pm'; return }, @INC);

    my ($e) = class_error({ encode_class => 'Argon2' });
    like($e, qr/encode_class 'Argon2'.*Crypt::Argon2/, 'the class does not load, the module is named');

    my $row = from_storage(Token => token =>
      '$argon2id$v=19$m=65536,t=3,p=1$c29tZXNhbHRzb21l$aGFzaGhhc2hoYXNoaGFzaGhhc2hoYXNoaGFzaGhhc2g');
    eval { $row->check_token('x') };
    "$@";
  };
  like($res, qr/Crypt::Argon2/, 'checking an argon2id hash without the module names it');
};

# ---------------------------------------------------------- missing module ---

subtest 'a class whose module is missing does not load' => sub {
  my $e = do {
    local %INC = %INC;
    delete $INC{'Crypt/Bcrypt.pm'};
    local @INC = (sub { die "Can't locate Crypt/Bcrypt.pm\n" if $_[1] eq 'Crypt/Bcrypt.pm'; return }, @INC);
    (class_error({}))[0];
  };
  like($e, qr/encode_class 'Bcrypt'.*needs Crypt::Bcrypt, which is not installed/, 'default class: the module is named');

  my $digest = do {
    local %INC = %INC;
    delete $INC{'Crypt/Bcrypt.pm'};
    local @INC = (sub { die "Can't locate Crypt/Bcrypt.pm\n" if $_[1] eq 'Crypt/Bcrypt.pm'; return }, @INC);
    (class_error({ encode_class => 'Digest' }))[0];
  };
  is($digest, undef, 'Digest needs no module');
};

# ----------------------------------------------------------------- UTF-8 -----

subtest 'values go in as UTF-8 bytes, written and checked' => sub {
  my $pw = "p\x{e4}ssw\x{f6}rd \x{263a}";
  my $bytes = $pw;
  utf8::encode($bytes);

  my $row = $schema->resultset('Fast')->new_result({ password => $pw });
  ok(Crypt::Bcrypt::bcrypt_check($bytes, $row->get_column('password')),
    'bcrypt hash is the hash of the UTF-8 bytes');
  ok($row->check_password($pw), 'the character string checks');

  my $salt   = 'saltsalt';
  my $stored = join '$', 'dbio', 'SHA-256', MIME::Base64::encode_base64($salt, ''),
    MIME::Base64::encode_base64(Digest::SHA::sha256($salt . $bytes), '');
  my $dig = $schema->source('Token')->result_class->inflate_result(
    $schema->source('Token'), { id => 1, token => $stored });
  # a SHA3 column checks a dbio$SHA-256$ value too: the value names its algorithm
  ok($dig->check_token($pw), 'a digest of the UTF-8 bytes checks with the character string');

  my $tok = $schema->resultset('Token')->new_result({ token => $pw });
  ok($tok->check_token($pw), 'Digest: written and checked alike');
  my (undef, undef, $salt_b64, $digest_b64) = split /\$/, $tok->get_column('token');
  my $ctx = Digest->new('SHA3-256');
  $ctx->add(MIME::Base64::decode_base64($salt_b64), $bytes);
  is(MIME::Base64::encode_base64($ctx->digest, ''), $digest_b64, 'Digest hashes the UTF-8 bytes');
};

subtest 'bcrypt refuses what it would cut or stop at' => sub {
  my $rs = $schema->resultset('Fast');

  ok(eval { $rs->new_result({ password => "a" x 72 })->get_column("password"); 1 }, '72 bytes are taken');
  for my $case (
    [ '73 bytes'                  => 'a' x 73 ],
    [ 'a NUL byte'                => "abc\0def" ],
    [ '74 bytes of 37 characters' => "\x{e9}" x 37 ],
  ) {
    my ($name, $value) = @$case;
    eval { $rs->new_result({ password => $value })->get_column("password") };
    like("$@", qr/72 bytes.*Argon2/s, "$name: refused, Argon2 named");
  }

  my $full = $rs->new_result({ password => 'a' x 72 });
  is($full->check_password('a' x 73), 0, 'a longer candidate does not match its 72 byte prefix');
  is($full->check_password("a\0"), 0, 'a candidate with NUL gives 0');
};

# ---------------------------------------------------------- digest list -----

subtest 'Digest writes SHA-2 and SHA-3 only, reads what is there' => sub {
  for my $alg (qw(MD5 SHA-1 SHA-224 SHA-512/256)) {
    like((class_error({ encode_class => 'Digest', encode_args => { algorithm => $alg } }))[0],
      qr/algorithm '\Q$alg\E'.*not allowed for writing/, "$alg is refused");
  }
  for my $alg (qw(SHA-256 SHA-384 SHA-512 SHA3-224 SHA3-256 SHA3-384 SHA3-512)) {
    is((class_error({ encode_class => 'Digest', encode_args => { algorithm => $alg } }))[0],
      undef, "$alg loads");
  }
  like((class_error({ encode_class => 'Digest', encode_args => { algorithm => 'NO-SUCH' } }))[0],
    qr/algorithm 'NO-SUCH'/, 'a name Digest does not know is refused');

  my $tok = $schema->resultset('Token')->new_result({ token => 'abc' });
  like($tok->get_column('token'), qr/\Adbio\$SHA3-256\$/, 'SHA3-256 is written');

  my $salt = 'oldsalt';
  my $md5  = join '$', 'dbio', 'MD5', MIME::Base64::encode_base64($salt, ''),
    MIME::Base64::encode_base64(Digest::MD5::md5($salt . 'secret'), '');
  my $row = from_storage(Token => token => $md5);
  is($row->check_token('secret'), 1, 'an existing dbio$MD5$ value checks');
  is($row->check_token('other'),  0, 'and rejects another');
};

# ------------------------------------------------- accept_unencoded ---------

subtest 'accept_unencoded is 0 by default' => sub {
  my $row = from_storage(Default => password => 'plain-text');
  is($row->check_password('plain-text'), 0, 'a value without hash format does not match');
};

subtest 'accept_unencoded => 1 writes the hash back on a match' => sub {
  my $storage = $schema->storage;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $row = from_storage(Legacy => password => 'plain-text');
  $storage->reset_captured;

  is($row->check_password('wrong'), 0, 'a wrong candidate does not match');
  is(scalar(grep { $_->{op} eq 'update' } $storage->captured_queries), 0, 'and writes nothing');

  is($row->check_password('plain-text'), 1, 'the right one matches');
  my @updates = grep { $_->{op} eq 'update' } $storage->captured_queries;
  is(scalar @updates, 1, 'one update');
  like($updates[0]{sql}, qr/\AUPDATE "legacy" SET "password" = \?/, 'it sets this column only');
  unlike($updates[0]{sql}, qr/SET[^W]*,/, 'and no other');
  like($updates[0]{sql}, qr/WHERE.*"id".*"password"/s, 'where the key and the compared value hold');

  my @bound = bound_values($updates[0]);
  is(scalar @bound, 3, 'hash, key, compared value');
  like($bound[0], qr/\A\$2b\$04\$/, 'the new value is a finished hash, bound as it is');
  is($bound[1], 1, 'the key');
  is($bound[2], 'plain-text', 'the old value is the condition');

  is($row->get_column('password'), $bound[0], 'the row holds the written hash');
  ok(!$row->is_column_changed('password'), 'and is not dirty');
  is($row->check_password('plain-text'), 1, 'the hash verifies (not hashed twice)');
  is(scalar(grep { $_->{op} eq 'update' } $storage->captured_queries), 1, 'a hash needs no second write');
  is(scalar(grep { /without hash format/ } @warnings), 1, 'warned once');
};

subtest 'the write back leaves a value that changed since' => sub {
  my $storage = $schema->storage;
  local $SIG{__WARN__} = sub { };

  my $row = from_storage(Legacy => password => 'plain-text2');
  $storage->mock_affected_rows('0E0');
  my $r = eval { $row->check_password('plain-text2') };
  $storage->mock_affected_rows(undef);

  is($r, 1, 'the check itself matches');
  is($row->get_column('password'), 'plain-text2', 'the row is left as it was: nothing was written');
};

subtest 'a row that is not in the database only gets the column value' => sub {
  my $storage = $schema->storage;
  local $SIG{__WARN__} = sub { };

  my $row = $schema->resultset('Legacy')->new_result({});
  $row->set_column(password => 'plain-text3');
  ok(!$row->in_storage, 'not in storage');

  $storage->reset_captured;
  is($row->check_password('plain-text3'), 1, 'matches');
  is(scalar($storage->captured_queries), 0, 'no statement');
  like($row->get_column('password'), qr/\A\$2b\$04\$/, 'the column holds the hash');
  is($row->check_password('plain-text3'), 1, 'which verifies');
};

# ----------------------------------------------------- random source ---------

subtest 'no secure random source: encoding throws' => sub {
  no warnings 'redefine';

  {
    local *Crypt::URandom::urandom = sub { die "no entropy\n" };
    eval { $schema->resultset("Token")->new_result({ token => "abc" })->get_column("token") };
    like("$@", qr/no secure random source -- install Crypt::URandom/, 'urandom dies');
  }
  {
    local *Crypt::URandom::urandom = sub { 'short' };
    eval { $schema->resultset("Fast")->new_result({ password => "abc" })->get_column("password") };
    like("$@", qr/no secure random source -- install Crypt::URandom/, 'urandom delivers too little');
  }
  {
    ok(eval { $schema->resultset('Token')->new_result({ token => 'abc' }); 1 }, 'with the source it works');
  }
};

# ------------------------------------------------------- column metadata -----

subtest 'an encoded column is not serialized and not logged unless it says so' => sub {
  my $info = $schema->source('Default')->column_info('password');
  is($info->{is_serializable}, 0, 'is_serializable is 0');
  ok($info->{_changelog_exclude}, 'the changelog leaves it out');

  my $row = $schema->resultset('Default')->new_result({ name => 'alice', password => 'x' });
  my $json = $row->TO_JSON;
  is($json->{name}, 'alice', 'TO_JSON has the other column');
  ok(!exists $json->{password}, 'and not the encoded one');

  for my $order ([qw(EncodedColumn ChangeLog)], [qw(ChangeLog EncodedColumn)]) {
    my ($e, $pkg) = class_error({}, components => $order);
    is($e, undef, "loads (@$order)");
    ok(probe_row($pkg)->_changelog_excluded_columns->{password}, "excluded from the changelog (@$order)");
  }

  for my $order ([qw(EncodedColumn ChangeLog)], [qw(ChangeLog EncodedColumn)]) {
    my ($e, $pkg) = class_error({ changelog => 0 }, components => $order);
    ok(probe_row($pkg)->_changelog_excluded_columns->{password}, "an explicit changelog => 0 holds (@$order)");
    ($e, $pkg) = class_error({ changelog => 1, is_serializable => 1 }, components => $order);
    ok(!probe_row($pkg)->_changelog_excluded_columns->{password}, "an explicit changelog => 1 logs (@$order)");
    is($pkg->result_source_instance->column_info('password')->{is_serializable}, 1,
      "an explicit is_serializable => 1 holds (@$order)");
  }
};

# -------------------------------------------------------------- trace --------

subtest 'the trace masks the bind of an encoded column' => sub {
  my $storage = $schema->storage;
  my $out = '';
  open my $fh, '>', \$out or die;
  $storage->debugobj->debugfh($fh);
  $storage->debug(2);

  my $row = $schema->resultset('Default')->create({ name => 'visible-name', password => 'topsecret' });
  my $hash = $row->get_column('password');
  $schema->resultset('Default')->search({ password => 'lookup-secret', name => 'visible-name' })->all;

  $storage->debug(0);
  close $fh;

  like($out, qr/'\*\*\*'/, 'the bind shows as ***');
  like($out, qr/'visible-name'/, 'a column without encode_column shows its value');
  unlike($out, qr/topsecret|lookup-secret/, 'the plain values are not in the trace');
  unlike($out, qr/\Q$hash\E/, 'neither is the hash');

  my $custom = '';
  {
    no warnings 'redefine';
    local *DBIO::Storage::DBI::redact_bind_value = sub { sub { my @a = @_; $custom = "@a[0,1]" . (ref $a[2]); 'X' } };
    $storage->debug(2);
    my ($t) = $storage->_format_for_trace([ [ { dbic_colname => 'name' }, 'v' ] ]);
    is($t, "'X'", 'a redactor of the old two argument form still works');
  }
  $storage->debug(0);
  is($custom, 'name vHASH', 'and gets the bind attributes as a third argument');
};

done_testing;
