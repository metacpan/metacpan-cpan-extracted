use strict;
use warnings;

use Test::More;

# karr k97 -- the name of the throwaway database is at most 30 characters.
# ASE refuses a longer database name (Msg 103: "... is too long. Maximum
# length is 30."), and _dbio_tmp_<pid>_<time>_<n> came to 31 with a seven-digit
# pid (Linux allows pids up to 4194304) from the tenth database of a process
# on: a diff died before it began. The time is in minutes since the epoch now,
# which keeps the name numeric.

use DBIO::Sybase::Deploy;

{
  package K97::Dbh;
  sub new { bless { AutoCommit => 1, db => 'testdb', log => [] }, $_[0] }
  sub selectrow_array {
    my ($self, $sql) = @_;
    return $self->{db} if $sql =~ /db_name/i;
    return (16384, 1536, 850) if $sql =~ /^SELECT \@\@maxpagesize/;
    return 1;
  }
  sub do { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
  sub err { undef }
}
{ package K97::Schema; sub sources { () } }

my $deploy = bless { schema => bless({}, 'K97::Schema') }, 'DBIO::Sybase::Deploy';

my @names;
{
  local $$ = 4194303;
  push @names, $deploy->_create_temp_db(K97::Dbh->new) for 1 .. 12;
}

my ($longest) = sort { length($b) <=> length($a) } @names;
cmp_ok length($longest), '<=', 30,
  "twelve names with a seven-digit pid are at most 30 characters ($longest)";
is scalar(keys %{{ map { $_ => 1 } @names }}), 12, '... and all different';
like $names[0], qr/\A_dbio_tmp_4194303_\d+_\d+\z/, '... still _dbio_tmp_<pid>_<time>_<n>';

done_testing;
