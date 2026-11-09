use strict;
use warnings;
use Test::More;

# t/67-mask-error-values.t -- every statement of the storage that fails reaches
# the caller through the hook _mask_error_values, which masks the sentences of
# the engine that quote a value (DBIO::ClickHouse::Util, pinned by t/65) and
# then the values bound to the statement (core). The live counterpart, with the
# text a server really writes, is t/66.
#
# Offline: a storage whose statement handle fails the way DBI does -- by
# calling the error handler of the storage with the text of the engine. What is
# asserted is the way of each kind of statement (select, insert, the multi-row
# insert of a void populate, update, delete) to the hook, not the sentences.

use DBIO::ClickHouse::Storage;

my $ENGINE = q{DBD::mysql::st execute failed: Code: 6. DB::Exception: Cannot parse string 'ab' as Int32: syntax error at begin of string. (CANNOT_PARSE_TEXT) (version 25.3.14.14 (official build))};

{
  package MyTest::CH::Mask::Sth;
  use strict;
  use warnings;

  sub new { my ($c, $storage, $sql) = @_; bless { storage => $storage, Statement => $sql, NUM_OF_PARAMS => 0 }, $c }
  sub bind_param { }
  sub finish { 1 }
  sub errstr { undef }
  sub err    { undef }
  sub execute {
    my $self = shift;
    # what DBI does with RaiseError and HandleError: the handler throws
    $self->{storage}->_dbi_handle_error($self->{storage}{engine_text}, $self);
  }
}

{
  package MyTest::CH::Mask::Storage;
  use strict;
  use warnings;
  use base 'DBIO::ClickHouse::Storage';
  use mro 'c3';

  sub new {
    my $self = shift->next::method(@_);
    $self->{_driver_determined} = 1;
    $self->{_sql_maker_opts} = { quote_char => '`', name_sep => '.' };
    return $self;
  }

  sub dbh_do { my ($self, $run) = splice @_, 0, 2; return $self->$run(bless({}, 'MyTest::CH::Mask::Dbh'), @_) }
  sub _prepare_sth { MyTest::CH::Mask::Sth->new($_[0], $_[2]) }
  sub _bind_sth_params { $_[1] }
  sub _populate_dbh { }
  sub connected { 1 }
  sub _seems_connected { 1 }
}

{
  package My::CH::Mask::Result::T;
  use strict;
  use warnings;
  use base 'DBIO::Core';
  __PACKAGE__->table('t');
  __PACKAGE__->add_columns(
    id => { data_type => 'varchar', size => 20 },
    s  => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Mask::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(T => 'My::CH::Mask::Result::T');
}

my $schema = My::CH::Mask::Schema->connect(sub { });
my $storage = MyTest::CH::Mask::Storage->new($schema);
$schema->storage($storage);
$storage->{engine_text} = $ENGINE;
my $rs = $schema->resultset('T');

sub error_of {
  my ($code) = @_;
  return eval { $code->(); 1 } ? undef : "$@";
}

#############################################################################
# 1. the hook
#############################################################################

# WHY: the sentences of the engine are the driver's to mask; the base of the
# hook knows the bound values. Both have to happen, in this order, or a value
# that is short or that the engine rewrites stays in the text.
{
  my $masked = $storage->_mask_error_values(
    q{Code: 6. DB::Exception: Cannot parse string 'ab' as Int32: x. Column values: s = 'geheim42', t = 'q'. (VIOLATED_CONSTRAINT)},
    ['ab', 'geheim42'],
    'INSERT INTO t (s) VALUES (?)',
  );
  unlike $masked, qr/'ab'|geheim42/, 'the hook: a short and a long value are gone';
  like $masked, qr/Cannot parse string '\*\*\*' as Int32/, '... the sentence keeps its type';
  like $masked, qr/Code: 6\./, '... and its code';

  is $storage->_mask_error_values(undef, [], undef), undef, 'the hook: undef text stays undef';
  my $ref = { msg => 'x' };
  is $storage->_mask_error_values($ref, [], undef), $ref, '... and a reference is returned as it is';
  is $storage->_mask_error_values('plain', [], undef), 'plain', '... and a text without a value stays';
}

#############################################################################
# 2. the ways of a statement to the hook
#############################################################################

# WHY: select, insert, the multi-row insert of a void populate, update and
# delete are separate statement shapes of this driver; each one has to run
# through core's _dbh_execute (which names the statement and its values for the
# error handler) and out through the hook. A shape that bypasses it would put
# the text of the engine into the exception unmasked.
my @ways = (
  [ 'select',                 sub { $rs->search(\[ 's = ?', 'ab' ])->all },                        1 ],
  [ 'insert (create)',        sub { $rs->create({ id => 'ab', s => 'x' }) },                      2 ],
  [ 'multi-row insert (void populate)',
                              sub { $rs->populate([ { id => 'ab', s => 'x' }, { id => 'cd', s => 'y' } ]) }, 4 ],
  [ 'update (mutation)',      sub { $rs->search({ id => 'ab' })->update({ s => 'cd' }) },         2 ],
  [ 'delete (mutation)',      sub { $rs->search({ id => 'ab' })->delete },                        1 ],
);

for my $way (@ways) {
  my ($name, $code, $binds) = @$way;
  my $msg = error_of($code);

  ok defined $msg, "$name: fails";
  unlike $msg // '', qr/'ab'/, "$name: the value is not in the message";
  like $msg // '', qr/Cannot parse string '\*\*\*' as Int32/, "$name: the sentence of the engine is masked";
  like $msg // '', qr/Code: 6\./, "$name: the code stays";
  like $msg // '', qr/with $binds bind values?\]/, "$name: the number of binds stays";
}

# a statement whose execute returns false without an exception
{
  no warnings 'redefine', 'once';
  local *MyTest::CH::Mask::Sth::execute = sub { return 0 };
  local *MyTest::CH::Mask::Sth::errstr  = sub {
    q{Code: 6. DB::Exception: Cannot parse string 'ab' as Int32: x. (CANNOT_PARSE_TEXT)}
  };
  my $msg = error_of(sub { $rs->create({ id => 'ab', s => 'x' }) });
  unlike $msg // '', qr/'ab'/, 'execute returning false: the value is not in the message';
  like $msg // '', qr/Cannot parse string '\*\*\*' as Int32/, '... the sentence is masked';
}

done_testing;
