use strict;
use warnings;

use Test::More;

# karr k75: the name of a temp database was prefix . pid . time, so two of one
# process in the same second shared it (a first one left behind by a refused
# DROP made the next diff die of Msg 1801). The clock is frozen here; the
# names must still differ and stay recognisable by _dbio_tmp_<pid>_.
BEGIN { *CORE::GLOBAL::time = sub { 1790000000 } }

use DBIO::Sybase::Deploy;

{
  package K75::Dbh;
  sub new { bless { AutoCommit => 1, db => 'testdb', did => [] }, shift }
  sub selectrow_array {
    my ($self, $sql) = @_;
    return $self->{db} if $sql =~ /db_name/i;
    return (16384, 1536, 850) if $sql =~ /^SELECT \@\@maxpagesize/;   # karr k69 part B
    return 1;    # the status2 check of karr k69
  }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{did} }, $sql;
    $self->{db} = $1 if $sql =~ /^USE\s+(\S+)$/i;
    1;
  }
  sub err { undef }
}

{ package K75::Schema; sub sources { () } }
my $deploy = bless { schema => bless({}, 'K75::Schema') }, 'DBIO::Sybase::Deploy';
my $dbh    = K75::Dbh->new;

is(time(), 1790000000, 'the clock is frozen: both names are made in one second');

my $first  = $deploy->_create_temp_db($dbh);
my $second = $deploy->_create_temp_db($dbh);

isnt($first, $second, 'two temp databases of one process in one second get different names');
like($first,  qr/^_dbio_tmp_\Q$$\E_\d+/, 'the first keeps the _dbio_tmp_<pid>_ prefix');
like($second, qr/^_dbio_tmp_\Q$$\E_\d+/, 'the second keeps the _dbio_tmp_<pid>_ prefix');

my @creates = grep { /^CREATE DATABASE/i } @{ $dbh->{did} };
is_deeply(\@creates, [ "CREATE DATABASE $first ON default = '24M'", "CREATE DATABASE $second ON default = '24M'" ],
  'each name is the one CREATE DATABASE was sent');

done_testing;
