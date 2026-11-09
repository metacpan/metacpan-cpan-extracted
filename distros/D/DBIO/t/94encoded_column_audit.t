use strict;
use warnings;

use Test::More;
use Digest::SHA ();

use DBIO::Test::Storage;

# DBIO::EncodedColumn, case by case (karr k288). The first state of this file
# pinned what the component did before the decisions of 2026-10-10; every
# subtest below that used to say WRONG or RISK now states the decided claim.
#
# "stored" is a value that comes from the database (inflate_result); "set" is a
# value handed to new_result / the column accessor. Origin plays no part in
# what the filter does: a defined non-reference, non-literal value is encoded.
# set_column and a literal are the raw ways in.

{
  package TestDBIO::EncAudit::Schema;
  use base 'DBIO::Schema';
}

{
  package TestDBIO::EncAudit::Schema::Result::User;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    password => {
      data_type           => 'varchar',
      size                => 255,
      is_nullable         => 1,
      encode_column       => 1,
      encode_class        => 'Digest',
      encode_check_method => 'check_password',
      encode_args         => { salt_length => 8 },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

# A column that takes values without a hash format only on request.
{
  package TestDBIO::EncAudit::Schema::Result::Legacy;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('legacy_users');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    password => {
      data_type           => 'varchar',
      size                => 255,
      is_nullable         => 1,
      encode_column       => 1,
      encode_class        => 'Digest',
      encode_check_method => 'check_password',
      encode_args         => { accept_unencoded => 1 },
    },
  );
  __PACKAGE__->set_primary_key('id');
}

# A column on the defaults: no value without a hash format is accepted.
{
  package TestDBIO::EncAudit::Schema::Result::Strict;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/EncodedColumn/);
  __PACKAGE__->table('strict_users');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    password => {
      data_type           => 'varchar',
      size                => 255,
      is_nullable         => 1,
      encode_column       => 1,
      encode_class        => 'Digest',
      encode_check_method => 'check_password',
    },
  );
  __PACKAGE__->set_primary_key('id');
}

TestDBIO::EncAudit::Schema->register_class(User   => 'TestDBIO::EncAudit::Schema::Result::User');
TestDBIO::EncAudit::Schema->register_class(Legacy => 'TestDBIO::EncAudit::Schema::Result::Legacy');
TestDBIO::EncAudit::Schema->register_class(Strict => 'TestDBIO::EncAudit::Schema::Result::Strict');

TestDBIO::EncAudit::Schema->storage_type('+DBIO::Test::Storage');
my $schema = TestDBIO::EncAudit::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));

my $rs = $schema->resultset('User');

sub from_storage {
  my ($source, $value) = @_;
  return $source->result_class->inflate_result($source, { id => 1, password => $value });
}

my $user_source   = $rs->result_source;
my $strict_source = $schema->resultset('Strict')->result_source;
my $legacy_source = $schema->resultset('Legacy')->result_source;

# the class definition is refused while it loads
my $n = 0;
sub class_error {
  my ($info) = @_;
  my $pkg = 'TestDBIO::EncAudit::Probe' . ++$n;
  my $ok = eval {
    eval "package $pkg; use base 'DBIO::Core'; 1" or die $@;
    $pkg->load_components('EncodedColumn');
    $pkg->table('probe');
    $pkg->add_columns(id => { data_type => 'integer' },
      password => { data_type => 'varchar', encode_column => 1, %$info });
    1;
  };
  return $ok ? undef : "$@";
}

# fixtures -------------------------------------------------------------------

my $dbio_hash = $rs->new_result({ password => 'secret' })->get_column('password');
like($dbio_hash, qr/\Adbio\$SHA-256\$/, 'fixture: dbio hash');

my $bcrypt = crypt('secret', '$2b$06$abcdefghijklmnopqrstuu');
my $have_crypt_bcrypt = defined $bcrypt && $bcrypt =~ /\A\$2b\$06\$/;
my $have_module = eval { require Crypt::Bcrypt; 1 };

# DBIx::Class::EncodedColumn, class Digest, algorithm SHA-1, format hex:
# 40 hex characters, no salt, no prefix.
my $dbic_hex = Digest::SHA::sha1_hex('secret');

# ---------------------------------------------------------------- set -------

subtest 'set: whatever the caller sets is encoded, even a finished hash' => sub {
  my $row = $rs->new_result({ password => 'secret' });
  like($row->get_column('password'), qr/\Adbio\$SHA-256\$[^\$]*\$[^\$]+\z/, 'plaintext -> dbio$SHA-256 (one round, salted)');
  ok($row->check_password('secret'), 'right candidate matches');
  is($row->check_password('wrong'), 0, 'wrong candidate is 0');

  # origin decides, not shape: a finished hash handed over by the caller is
  # that caller's password text
  my $same = $rs->new_result({ password => $dbio_hash });
  isnt($same->get_column('password'), $dbio_hash, 'a well-formed dbio hash that is set is encoded');
  like($same->get_column('password'), qr/\Adbio\$SHA-256\$/, 'into one dbio hash');
  ok($same->check_password($dbio_hash), 'the hash text is the password');
  is($same->check_password('secret'), 0, 'and the plaintext behind it is not');

  my $empty = $rs->new_result({ password => '' });
  like($empty->get_column('password'), qr/\Adbio\$/, 'empty string is encoded too');
};

subtest 'stored: writing back through the accessor encodes again; set_column and copy do not' => sub {
  # the accessor takes a defined non-reference value as a password, whatever
  # its origin: DBIx::Class::EncodedColumn does the same
  my $row = from_storage($user_source, $dbio_hash);
  is($row->check_password('secret'), 1, 'loaded: the plaintext verifies');
  $row->password($row->get_column('password'));
  isnt($row->get_column('password'), $dbio_hash, 'dbio: write back through the accessor -> encoded again');
  is($row->check_password('secret'), 0, 'and the plaintext no longer verifies');
  is($row->check_password($dbio_hash), 1, 'the old hash text is the password now');

  my $raw = from_storage($user_source, $dbio_hash);
  $raw->set_column(password => $raw->get_column('password'));
  is($raw->get_column('password'), $dbio_hash, 'dbio: set_column keeps it');
  is($raw->check_password('secret'), 1, 'and it still verifies');

  is(from_storage($user_source, $dbio_hash)->copy->get_column('password'), $dbio_hash,
    'dbio: copy keeps the hash');

  SKIP: {
    skip 'crypt() has no bcrypt here', 3 unless $have_crypt_bcrypt;
    my $b = from_storage($user_source, $bcrypt);
    $b->password($b->get_column('password'));
    isnt($b->get_column('password'), $bcrypt, 'bcrypt: write back through the accessor -> encoded again');
    like($b->get_column('password'), qr/\Adbio\$SHA-256\$/, 'into a dbio hash');
    is(from_storage($user_source, $bcrypt)->copy->get_column('password'), $bcrypt,
      'bcrypt: copy keeps the hash');
  }
};

# ------------------------------------------------- hash-looking plaintext ----

subtest 'a plaintext that only looks like a hash is encoded when it is set' => sub {
  for my $pw ('$2a$my-own-password', '$2$x', 'dbio$a$b$c', 'dbio$SHA-256$c2FsdA==$short') {
    my $row = $rs->new_result({ password => $pw });
    like($row->get_column('password'), qr/\Adbio\$SHA-256\$[^\$]*\$[^\$]+\z/, "'$pw' is encoded");
    isnt($row->get_column('password'), $pw, "'$pw' is not stored as it is");
    ok($row->check_password($pw), "'$pw': the user who chose it can log in");
  }

  my $row = $rs->new_result({ password => 'x' });
  $row->password('$2a$my-own-password');
  like($row->get_column('password'), qr/\Adbio\$/, 'through the accessor too');

  # a stored value of that shape is only compared as it is; set through the
  # accessor it is a password like any other
  my $stored = from_storage($user_source, '$2a$odd-but-stored');
  $stored->password($stored->get_column('password'));
  like($stored->get_column('password'), qr/\Adbio\$/, 'a stored value written back is encoded');
};

# ------------------------------------------------------------- import -------

# the values of a captured statement's bind, whether a bind is [ $attr, $value ]
# or a plain value
sub bound_values {
  my ($q) = @_;
  return map { ref $_ eq 'ARRAY' ? $_->[1] : $_ } @{ $q->{bind} || [] };
}
# A ready-made hash goes past the filter on purpose: set_column (the filter acts
# on set_filtered_column / the accessor / new / create / update only) or a
# literal in create/new.

subtest 'import: set_column and a bind literal store a finished hash as it is' => sub {
  my $row = $rs->new_result({});
  $row->set_column(password => $dbio_hash);
  is($row->get_column('password'), $dbio_hash, 'set_column: stored unchanged');
  is($row->check_password('secret'), 1, 'set_column: check_password(plaintext) is 1');
  is($row->check_password($dbio_hash), 0, 'set_column: the hash is not the password');

  # on a row that already holds a (filtered) value
  my $other = $rs->new_result({ password => 'first' });
  $other->set_column(password => $dbio_hash);
  is($other->get_column('password'), $dbio_hash, 'set_column replaces a set value unchanged');

  # a literal in create: the SQL carries the hash as a bind, untouched
  $schema->storage->reset_captured;
  my $created = $rs->create({ password => \[ '?', $dbio_hash ] });
  my ($insert) = grep { $_->{op} eq 'insert' } $schema->storage->captured_queries;
  ok($insert, 'create ran an insert');
  is_deeply([ bound_values($insert) ], [ $dbio_hash ], 'bind literal: the hash is bound as it is');
  is(${ $created->get_column('password') }->[1], $dbio_hash, 'the literal is kept on the row');

  # after a round trip from storage it verifies like any stored hash
  is(from_storage($user_source, $dbio_hash)->check_password('secret'), 1,
    'the imported value verifies once loaded');

  SKIP: {
    skip 'crypt() has no bcrypt here', 1 unless $have_crypt_bcrypt;
    $schema->storage->reset_captured;
    $rs->create({ password => \[ '?', $bcrypt ] });
    my ($ins) = grep { $_->{op} eq 'insert' } $schema->storage->captured_queries;
    is_deeply([ bound_values($ins) ], [ $bcrypt ], 'bcrypt bind literal: bound as it is');
  }
};

# ------------------------------------------------------------- bcrypt -------

subtest 'a bcrypt hash is imported raw and verifies through Crypt::Bcrypt' => sub {
  plan skip_all => 'crypt() has no bcrypt here' unless $have_crypt_bcrypt;

  isnt($rs->new_result({ password => $bcrypt })->get_column('password'), $bcrypt,
    'a bcrypt hash that is set is encoded like any other value');

  my $imported = $rs->new_result({});
  $imported->set_column(password => $bcrypt);
  is($imported->get_column('password'), $bcrypt, 'set_column imports it unchanged');

  my $row = from_storage($user_source, $bcrypt);

  SKIP: {
    skip 'Crypt::Bcrypt not installed', 3 unless $have_module;
    is($row->check_password('secret'), 1, 'right password: 1');
    is($row->check_password('wrong'),  0, 'wrong password: 0');
    is($row->check_password($bcrypt),  0, 'the hash itself as candidate: 0');
  }
};

subtest 'without Crypt::Bcrypt a bcrypt check throws and names the module' => sub {
  plan skip_all => 'crypt() has no bcrypt here' unless $have_crypt_bcrypt;

  my $row = from_storage($user_source, $bcrypt);
  my $res = do {
    local %INC = %INC;
    delete $INC{'Crypt/Bcrypt.pm'};
    local @INC = (sub { die "Can't locate Crypt/Bcrypt.pm\n" if $_[1] eq 'Crypt/Bcrypt.pm'; return }, @INC);
    eval { $row->check_password('secret') };
    "$@";
  };
  like($res, qr/Crypt::Bcrypt/, 'the exception names the module');

  my $dbio = from_storage($user_source, $dbio_hash);
  ok($dbio->check_password('secret'), 'a dbio hash does not need it');
};

subtest 'a value that claims a bcrypt hash and is not one never matches' => sub {
  for my $bad ('$2b$06$tooshort', '$2$x', '$2a$my-own-password') {
    my $row = from_storage($user_source, $bad);
    is($row->check_password($bad), 0, "'$bad' is not compared as plaintext");
  }
};

# ---------------------------------------------------- unknown algorithm ------

subtest 'a stored value names its algorithm, an unknown one never matches' => sub {
  (my $fake = $dbio_hash) =~ s/SHA-256/NO-SUCH-ALG/;
  my $row = from_storage($user_source, $fake);
  is($row->check_password('secret'), 0, 'dbio$NO-SUCH-ALG$... is 0');
  is($row->check_password($fake),    0, 'and not compared as plaintext');

  # exactly the named algorithm: a SHA-1 value is checked with SHA-1
  my $salt   = 'salty';
  my $digest = Digest::SHA::sha1($salt . 'secret');
  my $sha1 = join '$', 'dbio', 'SHA-1',
    MIME::Base64::encode_base64($salt, ''), MIME::Base64::encode_base64($digest, '');
  my $r = from_storage($user_source, $sha1);
  is($r->check_password('secret'), 1, 'dbio$SHA-1$... verifies with SHA-1');
  is($r->check_password('wrong'),  0, 'wrong candidate is 0');
};

subtest 'the class definition is refused for what the component would ignore' => sub {
  like(class_error({ encode_class => 'Digest', encode_args => { algorithm => 'NO-SUCH-ALG' } }),
    qr/algorithm 'NO-SUCH-ALG'/, 'unknown algorithm');
  like(class_error({ encode_class => 'Crypt::Eksblowfish::Bcrypt', encode_args => { cost => 8 } }),
    qr/encode_class 'Crypt::Eksblowfish::Bcrypt'/, 'encode_class that is not known');
  like(class_error({ encode_class => 'Digest', encode_args => { algorithm => 'SHA-256', format => 'hex' } }),
    qr/Unknown encode_args key\(s\).*format/, 'unknown encode_args key');
  like(class_error({ encode_class => 'Digest', encode_args => 'SHA-256' }), qr/must be a hashref/, 'encode_args not a hash');
  like(class_error({ encode_class => 'Digest', encode_args => { salt_length => -1 } }), qr/non-negative integer/, 'negative salt');
  is(class_error({ encode_class => 'Digest', encode_args => { algorithm => 'SHA3-256', salt_length => 0, accept_unencoded => 0 } }),
    undef, 'what is known is accepted');
};

# ---------------------------------------------- value without a hash format --

subtest 'a stored value without a hash format: opt-in, constant time, 0 or 1' => sub {
  local $SIG{__WARN__} = sub { };

  my $row = from_storage($legacy_source, 'legacy-plain');

  is($row->check_password('legacy-wrng'),  0, 'wrong candidate: 0, not an empty string');
  is($row->check_password(undef),          0, 'undef candidate: 0');
  is($row->check_password('legacy-plain'), 1, 'right candidate: 1');

  my $called = 0;
  {
    no warnings 'redefine';
    my $orig = \&DBIO::EncodedColumn::_constant_time_eq;
    local *DBIO::EncodedColumn::_constant_time_eq = sub { $called++; $orig->(@_) };
    from_storage($legacy_source, 'legacy-plain')->check_password('legacy-plain');
  }
  is($called, 1, 'compared in constant time, once');
};

subtest 'accept_unencoded is 0 unless set' => sub {
  my $row = from_storage($strict_source, 'legacy-plain');
  is($row->check_password('legacy-plain'), 0, 'the right plaintext does not match');
  is(from_storage($user_source, 'legacy-plain')->check_password('legacy-plain'), 0,
    'on a column without the setting too');

  my $enc = $schema->resultset('Strict')->new_result({ password => 'secret' });
  ok($enc->check_password('secret'), 'an encoded value still does');
};

subtest 'a dbio hash is compared in constant time' => sub {
  my $row = from_storage($user_source, $dbio_hash);

  my $called = 0;
  {
    no warnings 'redefine';
    local *DBIO::EncodedColumn::_constant_time_eq = sub { $called++; 1 };
    ok($row->check_password('anything'), 'comparison goes through _constant_time_eq');
  }
  is($called, 1, 'exactly once');

  is($row->check_password(undef), 0, 'undef candidate: 0');
  ok(!from_storage($user_source, undef)->check_password('secret'), 'stored undef: false');
};

# ----------------------------------------------------- foreign hash formats --
# Not decided by k288: still measured as they are (karr k288 follow-up).

subtest 'foreign hash formats are plaintext to the column and are hashed again' => sub {
  my @foreign = (
    [ 'DBIx::Class::EncodedColumn Digest SHA-1 hex' => $dbic_hex ],
    [ 'crypt $6$'                                    => crypt('secret', '$6$saltsalt$') ],
  );

  for my $case (@foreign) {
    my ($name, $value) = @$case;
    next unless defined $value && length $value;

    my $row = from_storage($user_source, $value);
    $row->password($row->get_column('password'));
    isnt($row->get_column('password'), $value, "$name: write back changes the value");
    like($row->get_column('password'), qr/\Adbio\$SHA-256\$/, "$name: it was hashed a second time");
    is($row->check_password('secret'), 0, "$name: and the user can no longer log in");
  }
};

done_testing;
