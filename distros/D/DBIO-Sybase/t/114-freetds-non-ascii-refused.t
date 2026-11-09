use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::Core;
use DBIO::Schema;

# karr k97, maintainer's decision. Over FreeTDS a string with a character
# beyond ASCII does not arrive in a varchar or univarchar column: the client
# library cannot convert it to the server's character set (Msg 97/98 of Open
# Client, "Error converting characters into server's character set"), reports
# it AFTER the statement was executed, and the row holds a blank in place of
# the value (measured with U+00FC, U+20AC and U+65E5, also in univarchar). The
# storage refuses such a bind value before anything is sent, with a
# DBIO::Exception naming table and column, as dbio-mssql does over DBD::Sybase
# (its karr k49). Not refused: ASCII, NULL, a binary column, and anything where
# the client library is not FreeTDS (not measured there).

my @EXECUTED;
my $OC;
{
  package T::K97N::STH;
  sub new { bless { sql => $_[1], bind => [] }, $_[0] }
  sub bind_param { $_[0]{bind}[ $_[1] - 1 ] = $_[2]; 1 }
  sub bind_param_inout { 1 }
  sub execute { my $s = shift; push @EXECUTED, { sql => $s->{sql}, bind => [ @{ $s->{bind} } ] }; 1 }
  sub execute_for_fetch {
    my ($self, $fetch, $status) = @_;
    while (my $t = $fetch->()) { push @EXECUTED, { sql => $self->{sql}, bind => [ @$t ] }; push @$status, 1 }
    return 1;
  }
  sub fetchall_arrayref { [ [ 1 ] ] } sub fetchrow_array { () } sub finish { 1 }
  sub err { undef } sub errstr { undef }
}
{
  package T::K97N::DBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
                    Driver => { Name => 'Sybase' }, syb_oc_version => $OC,
                    syb_dynamic_supported => 1 }, $_[0] }
  sub FETCH { $_[0]{$_[1]} } sub ping { 1 } sub disconnect { $_[0]{Active} = 0; 1 }
  sub begin_work { 1 } sub commit { 1 } sub rollback { 1 } sub err { undef } sub errstr { undef }
  sub do { 1 }
  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }
  sub selectrow_array { 1 }
  sub quote { my $v = $_[1]; return 'NULL' unless defined $v; $v =~ s/'/''/g; "'$v'" }
  sub prepare { T::K97N::STH->new($_[1]) } sub prepare_cached { T::K97N::STH->new($_[1]) }
}
{
  package T::K97N::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('doc');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 40, is_nullable => 1 },
    raw  => { data_type => 'varbinary', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  package T::K97N::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Doc => 'T::K97N::Result::Doc');
}

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;
no warnings 'redefine';
local *DBI::connect = sub { T::K97N::DBH->new };
use warnings 'redefine';

my $FREETDS = 'freetds v1.3.17';
my $OPEN    = 'Sybase Client-Library/16.0/P/x86_64/Linux';

for my $storage_type (qw(DBIO::Sybase::Storage DBIO::Sybase::Storage::ASE::NoBindVars)) {
  my $short = $storage_type =~ s/.*:://r;
  $OC = $FREETDS;
  my $schema = T::K97N::Schema->clone;
  $schema->storage_type("+$storage_type");
  $schema->connection('dbi:Sybase:server=x', 'u', 'p');
  my $rs = $schema->resultset('Doc');

  for my $op (
    [ create   => sub { $rs->create({ id => 1, name => "Gr\x{fc}\x{df}e" }) } ],
    [ update   => sub { $rs->search({ id => 1 })->update({ name => "\x{20ac}" }) } ],
    [ search   => sub { $rs->search({ name => "\x{65e5}" })->all } ],
    [ populate => sub { $rs->populate([ { id => 2, name => 'ok' }, { id => 3, name => "\x{65e5}" } ]) } ],
  ) {
    my ($label, $code) = @$op;
    @EXECUTED = ();
    my $err = eval { $code->(); 1 } ? '' : "$@";
    like $err, qr/table doc, column name: .*has a character beyond ASCII.*is refused/s,
      "$short, $label: refused, naming table and column";
    unlike $err, qr/\x{fc}|\x{20ac}|\x{65e5}/, '... the value is not in the message';
    is scalar(grep { $_->{sql} =~ /\b(?:INSERT|UPDATE|SELECT)\b.*\bdoc\b/s } @EXECUTED), 0,
      '... and nothing was sent';
  }

  @EXECUTED = ();
  ok eval { $rs->create({ id => 4, name => 'plain', raw => "\xff\xfe" }); 1 }, "$short: ASCII, and bytes for a binary column: sent" or diag $@;
  ok eval { $rs->create({ id => 5, name => undef }); 1 }, "$short: NULL: sent" or diag $@;
  ok scalar(@EXECUTED), '... statements went out';

  $OC = $OPEN;
  my $open = T::K97N::Schema->clone;
  $open->storage_type("+$storage_type");
  $open->connection('dbi:Sybase:server=x', 'u', 'p');
  ok eval { $open->resultset('Doc')->create({ id => 6, name => "\x{fc}" }); 1 },
    "$short: not FreeTDS: not refused (nothing was measured there)" or diag $@;
}

done_testing;
