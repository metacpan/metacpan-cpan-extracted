use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Oracle::Storage;

# Two claims about how the storage finds the sequence of an auto-increment
# column (karr k46):
#
# 1. The sequence is looked up per storage, never remembered on the result
#    source. column_info belongs to the result class, which outlives a
#    connection: a table dropped and created again in the same process got a
#    new IDENTITY sequence (ISEQ$$_n), and the name remembered from the first
#    one gave ORA-02289. A sequence the class declares itself is used as is.
# 2. Looking in all_tab_identity_cols swallows only "that view does not exist"
#    (a server before 12c, ORA-00942). Any other error -- a lost connection --
#    goes through instead of ending as "No suitable BEFORE INSERT triggers".

{
  package T::K46S::Source;
  sub new { bless { info => $_[1] }, $_[0] }
  sub name { 't' }
  sub column_info { $_[0]{info}{ $_[1] } ||= {} }
}
{
  package T::K46S::Storage;
  our @ISA = ('DBIO::Oracle::Storage');
  our @lookups;
  sub get_autoinc_seq { push @lookups, $_[2]; \(sprintf '"U"."ISEQ$$_%d"', scalar @lookups) }
  sub _sequence_fetch { my ($s, $type, $seq) = @_; return ref $seq ? $$seq : $seq }
}

my $source = T::K46S::Source->new({ id => {} });

my $one = bless {}, 'T::K46S::Storage';
my $two = bless {}, 'T::K46S::Storage';

my ($first) = $one->_dbh_last_insert_id(undef, $source, 'id');
my ($again) = $one->_dbh_last_insert_id(undef, $source, 'id');
is $again, $first, 'one storage looks the sequence up once';
is scalar @T::K46S::Storage::lookups, 1, '... and asks the database once';

my ($other) = $two->_dbh_last_insert_id(undef, $source, 'id');
is scalar @T::K46S::Storage::lookups, 2,
  'another storage over the same result source looks again (the table may be new)';
isnt $other, $first, '... and gets its own sequence';
ok !exists $source->column_info('id')->{sequence},
  'the result source carries nothing a later connection could inherit';

my $declared = T::K46S::Source->new({ id => { sequence => 'my_seq' } });
my ($d) = $one->_dbh_last_insert_id(undef, $declared, 'id');
is $d, 'my_seq', 'a sequence the class declares is used as it is';

{
  package T::K46S::Dbh;
  sub new { bless { err => $_[1] }, $_[0] }
  sub selectrow_arrayref { die $_[0]{err} }
}

my @args = ('SRC', \'= USER', 't', '"', '"', 'id');

throws_ok {
  $one->_dbh_identity_seq(T::K46S::Dbh->new('DBD::Oracle::db selectrow_arrayref failed: ORA-03113: end-of-file on communication channel'), @args)
} qr/ORA-03113/, 'a lost connection is not read as "no identity column"';

lives_and {
  is $one->_dbh_identity_seq(T::K46S::Dbh->new('ORA-00942: table or view does not exist'), @args), undef
} 'a server without all_tab_identity_cols (before 12c) means: no identity column';

done_testing;
