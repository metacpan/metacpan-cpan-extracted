# $Id$
# Various ways of enabling Multiple Active Statements support in
# MS SQL Server - what you use depends on your driver.
#
use strict;
use DBI;
use Data::Dumper;

my $attrs = { RaiseError => 1, PrintError => 0, AutoCommit => 1 };

my %connect_args = (DSN => 'dbi:ODBC:DSN=baugi',
                    USER => 'sa',
                    PASS => undef);

my $dbhmakers = {
  normal => sub {
    DBI->connect (
      (map { $connect_args{"$_"} } (qw/DSN USER PASS/) ),
      $attrs,
    );
  },
  MARs => sub {
    local $connect_args{DSN} = $connect_args{DSN} . ';MARS_Connection=Yes';
    DBI->connect (
      (map { $connect_args{$_} } (qw/DSN USER PASS/) ),
      $attrs,
    );
  },
  server_cursors_hack => sub {
    DBI->connect (
      (map { $connect_args{$_} } (qw/DSN USER PASS/) ),
      { %$attrs, odbc_SQL_ROWSET_SIZE => 2 },
    );
  },
  cursor_type => sub {
    DBI->connect (
      (map { $connect_args{$_} } (qw/DSN USER PASS/) ),
      { %$attrs, odbc_cursortype => 2 },
    );
  },
};

for (sort keys %$dbhmakers) {
  print "\n\nTrying with $_\n";

  my $dbh = $dbhmakers->{$_}->();
  $dbh->{odbc_SQL_ROWSET_SIZE} = 2;
  eval { $dbh->do ('DROP TABLE test_foo') };
  $dbh->do ('CREATE TABLE test_foo ( bar VARCHAR(20) )');

  $dbh->do ("INSERT INTO test_foo (bar) VALUES ( 'baz_$_' )")
    for (1..5);

  eval {
    my @sths;
    push @sths, $dbh->prepare("SELECT * FROM test_foo") for (1..5);
    $_->execute for @sths;

    LOOP:
    while (1) {
      for (0 .. $#sths) {
        my $res = $sths[$_]->fetchrow_arrayref
          or last LOOP;
        print "Result from sth $_: $res->[0]\n";
      }
    }
  };
  warn "Died with $@\n" if $@;

  eval { $dbh->do ('DROP TABLE test_foo') };
}

__END__
