use Test::More tests => 1;

use DBI;
use DBD::Log;
use IO::File;
use IO::Handle;

my $dbi = DBI->connect("DBI:Mock:database=test", "user", "pass");

unlink "test.log";

{ # test scope
  my $fh   = IO::File->new( ">test.log" );

  $dbi = DBD::Log->new( dbi => $dbi,
                        logFH => $fh,
                        dbiLogging => 1,
                      );

  $dbi->prepare("SELECT * FROM my_table");
  my $sth = $dbi->prepare("SELECT * FROM my_table WHERE id=?");

  $dbi->dbi->{mock_can_connect} = 0;

  $sth->execute(1);

  like($dbi->dbi->{dbd_log_error}, qr{No connection present in t/03_errors.t at line}) || diag($dbi->dbi->{dbd_log_error});

  diag($dbi->dbi->{dbd_log_backtrace});

  $fh->close;
}

unlink "test.log";
