use strict;
use warnings;
use Test::More;

# DBIO::Oracle::Storage::Savepoints silences DBD::Oracle's warning on a
# partial execute_for_fetch failure. The arguments are ($self, $source, $sth,
# ...): the attribute belongs on the statement handle, not on the source.

{
  package Local::Base;
  sub new { bless {}, shift }
  sub _dbh_execute_for_fetch {
    my ($self, $source, $sth) = @_;
    $self->{seen} = { sth => $sth->{PrintWarn}, source => exists $source->{PrintWarn} };
    return 1;
  }
}
{
  package Local::Storage;
  use mro 'c3';
  use base qw(DBIO::Oracle::Storage::Savepoints Local::Base);
}

my $storage = Local::Storage->new;
my $source  = {};
my $sth     = { PrintWarn => 1 };

$storage->_dbh_execute_for_fetch($source, $sth, [], [], []);

is $storage->{seen}{sth}, 0, 'PrintWarn is off on the statement handle during execute_for_fetch';
ok !$storage->{seen}{source}, 'and the source is not written to';
is $sth->{PrintWarn}, 1, 'the statement handle has its PrintWarn back afterwards';
ok !exists $source->{PrintWarn}, 'the source holds no PrintWarn key afterwards';

done_testing;
